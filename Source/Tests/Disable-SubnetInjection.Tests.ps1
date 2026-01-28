[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Disable-SubnetInjection Tests' {
    BeforeAll {
        $script:testEnvironmentId = "00000000-0000-0000-0000-000000000001"
        $script:testSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:testResourceGroup = "test-rg"
        $script:testPolicyName = "test-policy"
        $script:testTenantId = "87654321-4321-4321-4321-210987654321"
        $script:testPolicyArmId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:testPolicyName"
        $script:testPolicySystemId = "/regions/unitedstates/providers/Microsoft.PowerPlatform/enterprisePolicies/00000000-0000-0000-0000-000000000002"

        $script:mockEnvironmentWithoutPolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            properties = @{
                enterprisePolicies = $null
            }
        }

        $script:mockEnvironmentWithPolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
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
            properties = @{
                enterprisePolicies = @{
                    VNets = @{
                        id = "/subscriptions/other/resourceGroups/other/providers/Microsoft.PowerPlatform/enterprisePolicies/otherPolicy"
                    }
                }
            }
        }

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyArmId
            Name = $script:testPolicyName
            Kind = "NetworkInjection"
            Properties = @{
                systemId = $script:testPolicySystemId
            }
        }

        $script:mockUnlinkResponse = [PSCustomObject]@{
            StatusCode = 202
            Headers = @{
                "operation-location" = "https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/operations/00000000-0000-0000-0000-000000000003"
            }
        }
        $script:mockUnlinkResponse.Headers | Add-Member -MemberType ScriptMethod -Name "Contains" -Value { param($key) return $this.ContainsKey($key) } -Force
        $script:mockUnlinkResponse.Headers | Add-Member -MemberType ScriptMethod -Name "GetValues" -Value { param($key) return @($this[$key]) } -Force

        $script:mockOperationResult = [PSCustomObject]@{
            id = "00000000-0000-0000-0000-000000000003"
            state = @{
                id = "Succeeded"
            }
        }

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Warning {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-AzContext {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Successful disable operation' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-BAPEnvironment { return $script:mockEnvironmentWithPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnvironmentEnterprisePolicy { return $script:mockUnlinkResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Wait-EnterprisePolicyOperation { return $script:mockOperationResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should disable Subnet Injection successfully' {
            $result = Disable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId

            $result | Should -Not -BeNullOrEmpty
            $result.state.id | Should -Be "Succeeded"
        }

        It 'Should call Set-EnvironmentEnterprisePolicy with unlink operation' {
            Disable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId

            Should -Invoke Set-EnvironmentEnterprisePolicy -Times 1 -ParameterFilter {
                $Operation -eq [LinkOperation]::unlink
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'NoWait parameter' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-BAPEnvironment { return $script:mockEnvironmentWithPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnvironmentEnterprisePolicy { return $script:mockUnlinkResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Wait-EnterprisePolicyOperation { return $script:mockOperationResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should not wait when NoWait is specified' {
            Disable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId `
                -NoWait

            Should -Invoke Wait-EnterprisePolicyOperation -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Subnet Injection not enabled' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-BAPEnvironment { return $script:mockEnvironmentWithoutPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnvironmentEnterprisePolicy { return $script:mockUnlinkResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return early without calling unlink API' {
            Disable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId

            Should -Invoke Set-EnvironmentEnterprisePolicy -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Policy mismatch' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-BAPEnvironment { return $script:mockEnvironmentWithDifferentPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should throw when PolicyArmId does not match linked policy' {
            { Disable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId } | Should -Throw "*does not match*"
        }
    }

    Context 'Error handling' {
        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Disable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId } | Should -Throw "*Failed to connect to Azure*"
        }

        It 'Should throw when environment retrieval fails' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-BAPEnvironment { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Disable-SubnetInjection `
                -EnvironmentId $script:testEnvironmentId `
                -PolicyArmId $script:testPolicyArmId } | Should -Throw "*Failed to retrieve environment*"
        }
    }
}
