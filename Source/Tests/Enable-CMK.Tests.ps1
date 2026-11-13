[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Enable-CMK Tests' {
    BeforeAll {
        $script:testEnvironmentId = "00000000-0000-0000-0000-000000000001"
        $script:testSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:testResourceGroup = "test-rg"
        $script:testPolicyName = "test-cmk-policy"
        $script:testPolicyArmId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:testPolicyName"
        $script:testPolicySystemId = "/regions/unitedstates/providers/Microsoft.PowerPlatform/enterprisePolicies/00000000-0000-0000-0000-000000000002"

        $script:mockEnvironmentWithoutPolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            location = "unitedstates"
            properties = @{ enterprisePolicies = $null }
        }

        $script:mockEnvironmentWithSamePolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            location = "unitedstates"
            properties = @{
                enterprisePolicies = @{
                    CustomerManagedKeys = @{ id = $script:testPolicyArmId }
                }
            }
        }

        $script:mockEnvironmentWithDifferentPolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            location = "unitedstates"
            properties = @{
                enterprisePolicies = @{
                    CustomerManagedKeys = @{ id = "/subscriptions/other/resourceGroups/other/providers/Microsoft.PowerPlatform/enterprisePolicies/otherPolicy" }
                }
            }
        }

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyArmId
            Name = $script:testPolicyName
            Kind = "Encryption"
            Location = "unitedstates"
            Properties = @{ systemId = $script:testPolicySystemId }
        }

        $script:mockIdentityPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyArmId
            Name = $script:testPolicyName
            Kind = "Identity"
            Location = "unitedstates"
            Properties = @{ systemId = $script:testPolicySystemId }
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
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithoutPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnvironmentEnterprisePolicy { return $script:mockLinkResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Wait-EnterprisePolicyOperation { return $script:mockOperationResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should enable CMK successfully' {
            $result = Enable-CMK -EnvironmentId $script:testEnvironmentId -PolicyArmId $script:testPolicyArmId
            $result | Should -Be $true
        }

        It 'Uses endpoint-based authentication in sovereign clouds unless overridden' {
            Mock Connect-Azure { throw 'Unexpected authentication cloud' } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Connect-Azure { return $true } -ParameterFilter {
                $Endpoint -eq 'china'
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            Enable-CMK -EnvironmentId $script:testEnvironmentId -PolicyArmId $script:testPolicyArmId -Endpoint china | Should -Be $true
        }

        It 'Honors an explicit Azure environment' {
            Mock Connect-Azure { throw 'Unexpected authentication cloud' } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Connect-Azure { return $true } -ParameterFilter {
                $AzureEnvironment -eq 'AzureUSGovernment'
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            Enable-CMK -EnvironmentId $script:testEnvironmentId -PolicyArmId $script:testPolicyArmId -Endpoint usgovhigh -AzureEnvironment AzureUSGovernment | Should -Be $true
        }

        It 'Should call Set-EnvironmentEnterprisePolicy with link operation' {
            Enable-CMK -EnvironmentId $script:testEnvironmentId -PolicyArmId $script:testPolicyArmId

            Should -Invoke Set-EnvironmentEnterprisePolicy -Times 1 -ParameterFilter {
                $Operation -eq [LinkOperation]::link -and $PolicyType -eq [PolicyType]::Encryption
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

        It 'Initiates a link without polling and preserves the legacy default endpoint' {
            Enable-CMK -PlatformAppsData -PolicyArmId $script:testPolicyArmId | Should -Be $true

            Should -Invoke Connect-Azure -Times 1 -Exactly -ParameterFilter { $Endpoint -eq 'tip1' } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Should -Invoke Set-PlatformAppsDataCMK -Times 1 -Exactly -ParameterFilter {
                $PolicyArmId -eq $script:testPolicyArmId -and $Operation -eq 'link' -and $Endpoint -eq 'tip1'
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Honors an explicit endpoint, tenant, and forced authentication' {
            $tenantId = "00000000-0000-0000-0000-000000000004"
            Enable-CMK -PlatformAppsData -PolicyArmId $script:testPolicyArmId -Endpoint china -TenantId $tenantId -ForceAuth | Should -Be $true

            Should -Invoke Connect-Azure -Times 1 -Exactly -ParameterFilter {
                $Endpoint -eq 'china' -and $TenantId -eq "00000000-0000-0000-0000-000000000004" -and $Force
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Should -Invoke Set-PlatformAppsDataCMK -Times 1 -Exactly -ParameterFilter {
                $Endpoint -eq 'china' -and $TenantId -eq "00000000-0000-0000-0000-000000000004"
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Rejects environment-only parameters: <ParameterName>' -TestCases @(
            @{ ParameterName = 'EnvironmentId' }
            @{ ParameterName = 'Swap' }
            @{ ParameterName = 'NoWait' }
            @{ ParameterName = 'TimeoutSeconds' }
        ) {
            param($ParameterName)
            $parameters = @{ $ParameterName = $true }
            if ($ParameterName -eq 'EnvironmentId') { $parameters[$ParameterName] = $script:testEnvironmentId }
            if ($ParameterName -eq 'TimeoutSeconds') { $parameters[$ParameterName] = 60 }

            { Enable-CMK -PlatformAppsData -PolicyArmId $script:testPolicyArmId @parameters } | Should -Throw "*Parameter set cannot be resolved*"
        }
    }

    Context 'NoWait parameter' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithoutPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnvironmentEnterprisePolicy { return $script:mockLinkResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Wait-EnterprisePolicyOperation { return $script:mockOperationResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should not wait when NoWait is specified' {
            Enable-CMK -EnvironmentId $script:testEnvironmentId -PolicyArmId $script:testPolicyArmId -NoWait

            Should -Invoke Wait-EnterprisePolicyOperation -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Already enabled with same policy' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithSamePolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnvironmentEnterprisePolicy { return $script:mockLinkResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return early without calling link API' {
            $result = Enable-CMK -EnvironmentId $script:testEnvironmentId -PolicyArmId $script:testPolicyArmId

            $result | Should -Be $true
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
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithDifferentPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Enable-CMK -EnvironmentId $script:testEnvironmentId -PolicyArmId $script:testPolicyArmId -Swap

            $result | Should -Be $true
            Should -Invoke Set-EnvironmentEnterprisePolicy -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should throw when different policy exists and -Swap not specified' {
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithDifferentPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Enable-CMK -EnvironmentId $script:testEnvironmentId -PolicyArmId $script:testPolicyArmId } | Should -Throw "*Use the -Swap parameter*"
        }

        It 'Should throw when -Swap is specified but no policy is linked' {
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithoutPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Enable-CMK -EnvironmentId $script:testEnvironmentId -PolicyArmId $script:testPolicyArmId -Swap } | Should -Throw "*Cannot use -Swap*"
        }
    }

    Context 'Error handling' {
        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Enable-CMK -EnvironmentId $script:testEnvironmentId -PolicyArmId $script:testPolicyArmId } | Should -Throw "*Failed to connect to Azure*"
        }

        It 'Should throw when policy is not Encryption type' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithoutPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockIdentityPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Enable-CMK -EnvironmentId $script:testEnvironmentId -PolicyArmId $script:testPolicyArmId } | Should -Throw "*not a CMK (Encryption) policy*"
        }
    }
}
