[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-CMKEnterprisePolicy Tests' {
    BeforeAll {
        $script:testSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:testResourceGroup = "test-rg"
        $script:testPolicyName = "test-cmk-policy"
        $script:testEnvironmentId = "00000000-0000-0000-0000-000000000001"
        $script:testPolicyArmId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:testPolicyName"

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyArmId
            Name = $script:testPolicyName
            Kind = "Encryption"
            Location = "unitedstates"
        }

        $script:mockEnvironmentWithPolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            location = "unitedstates"
            properties = @{
                enterprisePolicies = @{
                    CustomerManagedKeys = @{
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

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-AzContext {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'By subscription' {
        BeforeAll {
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return policies in the subscription' {
            $result = Get-CMKEnterprisePolicy -SubscriptionId $script:testSubscriptionId
            $result.Name | Should -Be $script:testPolicyName
        }

        It 'Should throw when no policies found' {
            Mock Get-EnterprisePolicy { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            { Get-CMKEnterprisePolicy -SubscriptionId $script:testSubscriptionId } | Should -Throw "*No CMK Enterprise Policies found in subscription*"
        }
    }

    Context 'By resource group' {
        BeforeAll {
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return policies in the resource group' {
            $result = Get-CMKEnterprisePolicy -SubscriptionId $script:testSubscriptionId -ResourceGroupName $script:testResourceGroup
            $result.Name | Should -Be $script:testPolicyName
        }
    }

    Context 'By resource ID' {
        BeforeAll {
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return the policy by resource ID' {
            $result = Get-CMKEnterprisePolicy -PolicyResourceId $script:testPolicyArmId
            $result.ResourceId | Should -Be $script:testPolicyArmId
        }

        It 'Rejects a non-encryption policy' {
            Mock Get-EnterprisePolicy { return [PSCustomObject]@{ Kind = "Identity" } } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-CMKEnterprisePolicy -PolicyResourceId $script:testPolicyArmId } | Should -Throw "*not a CMK (Encryption) policy*"
        }
    }

    Context 'By environment' {
        BeforeAll {
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return the linked policy' {
            $result = Get-CMKEnterprisePolicy -EnvironmentId $script:testEnvironmentId
            $result.ResourceId | Should -Be $script:testPolicyArmId
        }

        It 'Rejects a linked non-encryption policy' {
            Mock Get-EnterprisePolicy { return [PSCustomObject]@{ Kind = "Identity" } } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-CMKEnterprisePolicy -EnvironmentId $script:testEnvironmentId } | Should -Throw "*not a CMK (Encryption) policy*"
        }

        It 'Should throw when no policy is linked' {
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithoutPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            { Get-CMKEnterprisePolicy -EnvironmentId $script:testEnvironmentId } | Should -Throw "*No CMK Enterprise Policy is linked*"
        }
    }

    Context 'Error handling' {
        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            { Get-CMKEnterprisePolicy -SubscriptionId $script:testSubscriptionId } | Should -Throw "*Failed to connect to Azure*"
        }
    }
}
