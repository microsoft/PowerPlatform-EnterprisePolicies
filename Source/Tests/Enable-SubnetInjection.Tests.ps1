[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Enable-SubnetInjection Tests' {
    BeforeAll {
        $script:testEnvironmentId = "00000000-0000-0000-0000-000000000001"
        $script:testSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:testResourceGroup = "test-rg"
        $script:testPolicyName = "test-policy"
        $script:testTenantId = "87654321-4321-4321-4321-210987654321"
        $script:testPolicyArmId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:testPolicyName"
        $script:testPolicySystemId = "/regions/unitedstates/providers/Microsoft.PowerPlatform/enterprisePolicies/00000000-0000-0000-0000-000000000002"
        $script:testRegion = "unitedstates"

        $script:mockEnvironmentWithoutPolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            location = $script:testRegion
            properties = @{
                enterprisePolicies = $null
            }
        }

        $script:mockEnvironmentWithSamePolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            location = $script:testRegion
            properties = @{
                enterprisePolicies = @{
                    VNets = @{
                        id = $script:testPolicyArmId
                    }
                }
            }
        }

        $script:mockEnvironmentWithDifferentPolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            location = $script:testRegion
            properties = @{
                enterprisePolicies = @{
                    VNets = @{
                        id = "/subscriptions/other/resourceGroups/other/providers/Microsoft.PowerPlatform/enterprisePolicies/otherPolicy"
                    }
                }
            }
        }

        $script:mockEnvironmentDifferentLocation = [PSCustomObject]@{
            name = $script:testEnvironmentId
            location = "europe"
            properties = @{
                enterprisePolicies = $null
            }
        }

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyArmId
            Name = $script:testPolicyName
            Kind = "NetworkInjection"
            Location = $script:testRegion
            Properties = @{
                systemId = $script:testPolicySystemId
            }
        }

        $script:mockEncryptionPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyArmId
            Name = $script:testPolicyName
            Kind = "Encryption"
            Location = $script:testRegion
            Properties = @{
                systemId = $script:testPolicySystemId
            }
        }

        $script:mockLinkResponse = [PSCustomObject]@{
            StatusCode = 202
            Headers = @{
                "operation-location" = "https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/operations/00000000-0000-0000-0000-000000000003"
            }
        }
        $script:mockLinkResponse.Headers | Add-Member -MemberType ScriptMethod -Name "Contains" -Value { param($key) return $this.ContainsKey($key) } -Force
        $script:mockLinkResponse.Headers | Add-Member -MemberType ScriptMethod -Name "GetValues" -Value { param($key) return @($this[$key]) } -Force

        $script:mockOperationResult = "Succeeded"

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Warning {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-AzContext {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Successful enable operation' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-BAPEnvironment { return $script:mockEnvironmentWithoutPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnvironmentEnterprisePolicy { return $script:mockLinkResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Wait-EnterprisePolicyOperation { return $script:mockOperationResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should enable Subnet Injection successfully' {
            $result = Enable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId

            $result | Should -Be $true
        }

        It 'Should call Set-EnvironmentEnterprisePolicy with link operation' {
            Enable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId

            Should -Invoke Set-EnvironmentEnterprisePolicy -Times 1 -ParameterFilter {
                $Operation -eq [LinkOperation]::link
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'NoWait parameter' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-BAPEnvironment { return $script:mockEnvironmentWithoutPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnvironmentEnterprisePolicy { return $script:mockLinkResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Wait-EnterprisePolicyOperation { return $script:mockOperationResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should not wait when NoWait is specified' {
            Enable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId `
                -NoWait

            Should -Invoke Wait-EnterprisePolicyOperation -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Already enabled with same policy' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-BAPEnvironment { return $script:mockEnvironmentWithSamePolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnvironmentEnterprisePolicy { return $script:mockLinkResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return early without calling link API' {
            Enable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId

            Should -Invoke Set-EnvironmentEnterprisePolicy -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Swap parameter' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnvironmentEnterprisePolicy { return $script:mockLinkResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Wait-EnterprisePolicyOperation { return $script:mockOperationResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should swap policy when -Swap is specified and different policy exists' {
            Mock Get-BAPEnvironment { return $script:mockEnvironmentWithDifferentPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Enable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId `
                -Swap

            $result | Should -Be $true
            Should -Invoke Set-EnvironmentEnterprisePolicy -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should throw when different policy exists and -Swap not specified' {
            Mock Get-BAPEnvironment { return $script:mockEnvironmentWithDifferentPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Enable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId } | Should -Throw "*Use the -Swap parameter*"
        }

        It 'Should throw when -Swap is specified but no policy is linked' {
            Mock Get-BAPEnvironment { return $script:mockEnvironmentWithoutPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Enable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId `
                -Swap } | Should -Throw "*Cannot use -Swap*"
        }
    }

    Context 'Error handling' {
        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Enable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId } | Should -Throw "*Failed to connect to Azure*"
        }

        It 'Should throw when policy is not NetworkInjection type' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-BAPEnvironment { return $script:mockEnvironmentWithoutPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockEncryptionPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Enable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId } | Should -Throw "*not a Subnet Injection*"
        }

        It 'Should throw when environment location does not match policy location' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-BAPEnvironment { return $script:mockEnvironmentDifferentLocation } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Enable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId } | Should -Throw "*does not match*"
        }

        It 'Should treat unitedstates environment with unitedstateseuap policy as compatible' {
            $mockEnvironmentUnitedStates = [PSCustomObject]@{
                name = $script:testEnvironmentId
                location = "unitedstates"
                properties = @{
                    enterprisePolicies = $null
                }
            }
            $mockPolicyEuap = [PSCustomObject]@{
                ResourceId = $script:testPolicyArmId
                Name = $script:testPolicyName
                Kind = "NetworkInjection"
                Location = "unitedstateseuap"
                Properties = @{
                    systemId = $script:testPolicySystemId
                }
            }

            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-BAPEnvironment { return $mockEnvironmentUnitedStates } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $mockPolicyEuap } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnvironmentEnterprisePolicy { return $script:mockLinkResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Wait-EnterprisePolicyOperation { return "Succeeded" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Enable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId

            $result | Should -Be $true
        }
    }
}
