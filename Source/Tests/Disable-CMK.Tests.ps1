[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Disable-CMK Tests' {
    BeforeAll {
        $script:testEnvironmentId = "00000000-0000-0000-0000-000000000001"
        $script:testSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:testResourceGroup = "test-rg"
        $script:testPolicyName = "test-cmk-policy"
        $script:testPolicyArmId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:testPolicyName"
        $script:testPolicySystemId = "/regions/unitedstates/providers/Microsoft.PowerPlatform/enterprisePolicies/00000000-0000-0000-0000-000000000002"

        $script:mockEnvironmentWithPolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            location = "unitedstates"
            properties = @{
                enterprisePolicies = @{
                    CustomerManagedKeys = @{ id = $script:testPolicyArmId }
                }
            }
        }

        $script:mockEnvironmentWithoutPolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            location = "unitedstates"
            properties = @{ enterprisePolicies = $null }
        }

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyArmId
            Name = $script:testPolicyName
            Kind = "Encryption"
            Location = "unitedstates"
            Properties = @{ systemId = $script:testPolicySystemId }
        }

        $script:mockUnlinkResponse = [PSCustomObject]@{
            StatusCode = 202
            Headers = @{
                "operation-location" = "https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/operations/00000000-0000-0000-0000-000000000003"
            }
        }
        $script:mockUnlinkResponse.Headers | Add-Member -MemberType ScriptMethod -Name "Contains" -Value { param($key) return $this.ContainsKey($key) } -Force
        $script:mockUnlinkResponse.Headers | Add-Member -MemberType ScriptMethod -Name "GetValues" -Value { param($key) return @($this[$key]) } -Force

        $script:mockOperationResult = "Succeeded"

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Warning {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-AzContext {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Successful disable operation' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnvironmentEnterprisePolicy { return $script:mockUnlinkResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Wait-EnterprisePolicyOperation { return $script:mockOperationResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should disable CMK successfully' {
            $result = Disable-CMK -EnvironmentId $script:testEnvironmentId
            $result | Should -Be $true
        }

        It 'Uses endpoint-based authentication in sovereign clouds unless overridden' {
            Mock Connect-Azure { throw 'Unexpected authentication cloud' } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Connect-Azure { return $true } -ParameterFilter {
                $Endpoint -eq 'china'
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            Disable-CMK -EnvironmentId $script:testEnvironmentId -Endpoint china | Should -Be $true
        }

        It 'Honors an explicit Azure environment' {
            Mock Connect-Azure { throw 'Unexpected authentication cloud' } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Connect-Azure { return $true } -ParameterFilter {
                $AzureEnvironment -eq 'AzureUSGovernment'
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            Disable-CMK -EnvironmentId $script:testEnvironmentId -Endpoint usgovhigh -AzureEnvironment AzureUSGovernment | Should -Be $true
        }

        It 'Should call Set-EnvironmentEnterprisePolicy with unlink operation' {
            Disable-CMK -EnvironmentId $script:testEnvironmentId

            Should -Invoke Set-EnvironmentEnterprisePolicy -Times 1 -ParameterFilter {
                $Operation -eq [LinkOperation]::unlink -and $PolicyType -eq [PolicyType]::Encryption
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'PlatformAppsData' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-PlatformAppsDataCMK { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-PPEnvironment { throw "Must not use an environment route" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Wait-EnterprisePolicyOperation { throw "PlatformAppsData must not poll environment operations" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Initiates an unlink without polling and preserves the legacy default endpoint' {
            Disable-CMK -PlatformAppsData -PolicyArmId $script:testPolicyArmId | Should -Be $true

            Should -Invoke Connect-Azure -Times 1 -Exactly -ParameterFilter { $Endpoint -eq 'tip1' } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Should -Invoke Set-PlatformAppsDataCMK -Times 1 -Exactly -ParameterFilter {
                $PolicyArmId -eq $script:testPolicyArmId -and $Operation -eq 'unlink' -and $Endpoint -eq 'tip1'
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Honors an explicit endpoint and tenant' {
            $tenantId = "00000000-0000-0000-0000-000000000004"
            Disable-CMK -PlatformAppsData -PolicyArmId $script:testPolicyArmId -Endpoint prod -TenantId $tenantId | Should -Be $true

            Should -Invoke Connect-Azure -Times 1 -Exactly -ParameterFilter {
                $Endpoint -eq 'prod' -and $TenantId -eq "00000000-0000-0000-0000-000000000004"
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Should -Invoke Set-PlatformAppsDataCMK -Times 1 -Exactly -ParameterFilter {
                $Endpoint -eq 'prod' -and $TenantId -eq "00000000-0000-0000-0000-000000000004"
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Rejects an environment ID with the PlatformAppsData target' {
            { Disable-CMK -PlatformAppsData -PolicyArmId $script:testPolicyArmId -EnvironmentId $script:testEnvironmentId } | Should -Throw "*Parameter set cannot be resolved*"
        }

        It 'Rejects environment polling options' {
            { Disable-CMK -PlatformAppsData -PolicyArmId $script:testPolicyArmId -NoWait } | Should -Throw "*Parameter set cannot be resolved*"
        }
    }

    Context 'NoWait parameter' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnvironmentEnterprisePolicy { return $script:mockUnlinkResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Wait-EnterprisePolicyOperation { return $script:mockOperationResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should not wait when NoWait is specified' {
            Disable-CMK -EnvironmentId $script:testEnvironmentId -NoWait

            Should -Invoke Wait-EnterprisePolicyOperation -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Error handling' {
        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Disable-CMK -EnvironmentId $script:testEnvironmentId } | Should -Throw "*Failed to connect to Azure*"
        }

        It 'Should throw when CMK is not enabled for the environment' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithoutPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Disable-CMK -EnvironmentId $script:testEnvironmentId } | Should -Throw "*CMK is not enabled*"
        }
    }
}
