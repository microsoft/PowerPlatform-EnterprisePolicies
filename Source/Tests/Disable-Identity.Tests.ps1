[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Disable-Identity Tests' {
    BeforeAll {
        $script:testEnvironmentId = "00000000-0000-0000-0000-000000000001"
        $script:testSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:testResourceGroup = "test-rg"
        $script:testPolicyName = "test-identity-policy"
        $script:testPolicyArmId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:testPolicyName"
        $script:testPolicySystemId = "/regions/unitedstates/providers/Microsoft.PowerPlatform/enterprisePolicies/00000000-0000-0000-0000-000000000002"

        $script:mockEnvironmentWithPolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            location = "unitedstates"
            properties = @{
                enterprisePolicies = @{
                    identity = @{
                        id = $script:testPolicyArmId
                    }
                }
            }
        }

        $script:mockEnvironmentWithoutPolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            location = "unitedstates"
            properties = @{
                enterprisePolicies = $null
            }
        }

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyArmId
            Name = $script:testPolicyName
            Kind = "Identity"
            Location = "unitedstates"
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

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-AzContext {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Successful disable operation' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnvironmentEnterprisePolicy { return $script:mockUnlinkResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Wait-EnterprisePolicyOperation { return "Succeeded" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should disable Identity successfully' {
            $result = Disable-Identity -EnvironmentId $script:testEnvironmentId

            $result | Should -Be $true
        }

        It 'Should call Set-EnvironmentEnterprisePolicy with unlink operation' {
            Disable-Identity -EnvironmentId $script:testEnvironmentId

            Should -Invoke Set-EnvironmentEnterprisePolicy -Times 1 -ParameterFilter {
                $Operation -eq [LinkOperation]::unlink
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'NoWait parameter' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnvironmentEnterprisePolicy { return $script:mockUnlinkResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Wait-EnterprisePolicyOperation { return "Succeeded" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should not wait when NoWait is specified' {
            Disable-Identity -EnvironmentId $script:testEnvironmentId -NoWait

            Should -Invoke Wait-EnterprisePolicyOperation -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Identity not enabled' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithoutPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return false when identity is not enabled' {
            $result = Disable-Identity -EnvironmentId $script:testEnvironmentId

            $result | Should -Be $false
        }
    }

    Context 'Error handling' {
        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Disable-Identity -EnvironmentId $script:testEnvironmentId } | Should -Throw "*Failed to connect to Azure*"
        }
    }
}
