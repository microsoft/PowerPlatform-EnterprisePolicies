[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-IdentityEnterprisePolicy Tests' {
    BeforeAll {
        $script:testSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:testResourceGroup = "test-rg"
        $script:testPolicyName = "test-identity-policy"
        $script:testEnvironmentId = "00000000-0000-0000-0000-000000000001"
        $script:testPolicyArmId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:testPolicyName"

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyArmId
            Name = $script:testPolicyName
            Kind = "Identity"
            Properties = @{ systemId = "test-system-id" }
        }

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

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-AzContext {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'ByResourceId' {
        BeforeAll {
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should retrieve policy by ARM resource ID' {
            $result = Get-IdentityEnterprisePolicy -PolicyResourceId $script:testPolicyArmId

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testPolicyName
        }
    }

    Context 'BySubscription' {
        It 'Should retrieve all identity policies in subscription' {
            Mock Get-EnterprisePolicy { return @($script:mockPolicy) } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Get-IdentityEnterprisePolicy -SubscriptionId $script:testSubscriptionId

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should throw when no policies found' {
            Mock Get-EnterprisePolicy { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-IdentityEnterprisePolicy -SubscriptionId $script:testSubscriptionId } | Should -Throw "*No Identity Enterprise Policies found*"
        }
    }

    Context 'ByResourceGroup' {
        It 'Should retrieve all identity policies in resource group' {
            Mock Get-EnterprisePolicy { return @($script:mockPolicy) } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Get-IdentityEnterprisePolicy -SubscriptionId $script:testSubscriptionId -ResourceGroupName $script:testResourceGroup

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'ByEnvironment' {
        It 'Should retrieve the linked identity policy from environment' {
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Get-IdentityEnterprisePolicy -EnvironmentId $script:testEnvironmentId

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testPolicyName
        }

        It 'Should throw when no identity policy is linked to environment' {
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithoutPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-IdentityEnterprisePolicy -EnvironmentId $script:testEnvironmentId } | Should -Throw "*No Identity Enterprise Policy is linked*"
        }
    }

    Context 'Error handling' {
        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-IdentityEnterprisePolicy -SubscriptionId $script:testSubscriptionId } | Should -Throw "*Failed to connect to Azure*"
        }
    }
}
