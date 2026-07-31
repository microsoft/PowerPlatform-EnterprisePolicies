[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-SubnetInjectionEnterprisePolicy Tests' {
    BeforeAll {
        $script:testSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:testResourceGroup = "test-rg"
        $script:testPolicyName = "test-policy"
        $script:testTenantId = "87654321-4321-4321-4321-210987654321"
        $script:testEnvironmentId = "00000000-0000-0000-0000-000000000001"
        $script:testPolicyResourceId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:testPolicyName"

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyResourceId
            Name = $script:testPolicyName
            Kind = "NetworkInjection"
            Properties = @{
                networkInjection = @{
                    virtualNetworks = @(
                        @{ id = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.Network/virtualNetworks/test-vnet"; subnet = @{ name = "default" } }
                    )
                }
            }
        }

        $script:mockEnvironmentWithPolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            properties = @{
                enterprisePolicies = @{
                    VNets = @{
                        id = $script:testPolicyResourceId
                    }
                }
            }
        }

        $script:mockEnvironmentWithoutPolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            properties = @{
                enterprisePolicies = $null
            }
        }

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-AzContext {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'BySubscription parameter set' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should retrieve all policies in subscription and return EnterprisePolicy object' {
            Mock Get-EnterprisePolicy { return @($script:mockPolicy) } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Get-SubnetInjectionEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId

            $result | Should -Not -BeNullOrEmpty
            @($result)[0].Name | Should -Be $script:testPolicyName
        }

        It 'Should throw when no policies found in subscription' {
            Mock Get-EnterprisePolicy { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-SubnetInjectionEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId } | Should -Throw "*No Subnet Injection Enterprise Policies found in subscription*"
        }
    }

    Context 'ByResourceGroup parameter set' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should retrieve all policies in resource group and return EnterprisePolicy object' {
            Mock Get-EnterprisePolicy { return @($script:mockPolicy) } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Get-SubnetInjectionEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup

            $result | Should -Not -BeNullOrEmpty
            @($result)[0].Name | Should -Be $script:testPolicyName
        }

        It 'Should throw when no policies found in resource group' {
            Mock Get-EnterprisePolicy { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-SubnetInjectionEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup } | Should -Throw "*No Subnet Injection Enterprise Policies found in resource group*"
        }
    }

    Context 'ByResourceId parameter set' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should retrieve policy by resource ID and return EnterprisePolicy object' {
            $result = Get-SubnetInjectionEnterprisePolicy `
                -PolicyResourceId $script:testPolicyResourceId `
                -TenantId $script:testTenantId

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testPolicyName
            $result.Kind | Should -Be "NetworkInjection"
        }

        It 'Should throw when PolicyResourceId format is invalid' {
            { Get-SubnetInjectionEnterprisePolicy `
                -PolicyResourceId "invalid-resource-id" `
                -TenantId $script:testTenantId } | Should -Throw "*Invalid resource ID format*"
        }

        It 'Should throw when policy is not found' {
            Mock Get-EnterprisePolicy { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-SubnetInjectionEnterprisePolicy `
                -PolicyResourceId $script:testPolicyResourceId `
                -TenantId $script:testTenantId } | Should -Throw "*No enterprise policy found with resource ID*"
        }
    }

    Context 'ByEnvironment parameter set' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should retrieve policy linked to environment and return EnterprisePolicy object' {
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Get-SubnetInjectionEnterprisePolicy `
                -EnvironmentId $script:testEnvironmentId `
                -Endpoint Prod

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testPolicyName
        }

        It 'Should throw when environment has no linked policy' {
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithoutPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-SubnetInjectionEnterprisePolicy `
                -EnvironmentId $script:testEnvironmentId `
                -Endpoint Prod } | Should -Throw "*No Subnet Injection Enterprise Policy is linked to environment*"
        }

        It 'Should throw when environment retrieval fails' {
            Mock Get-PPEnvironment { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-SubnetInjectionEnterprisePolicy `
                -EnvironmentId $script:testEnvironmentId `
                -Endpoint Prod } | Should -Throw "*Failed to retrieve environment*"
        }
    }

    Context 'Error handling' {
        It 'Should throw when Connect-Azure fails for BySubscription' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-SubnetInjectionEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId } | Should -Throw "*Failed to connect to Azure*"
        }

        It 'Should throw when Connect-Azure fails for ByResourceGroup' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-SubnetInjectionEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup } | Should -Throw "*Failed to connect to Azure*"
        }

        It 'Should throw when Connect-Azure fails for ByResourceId' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-SubnetInjectionEnterprisePolicy `
                -PolicyResourceId $script:testPolicyResourceId `
                -TenantId $script:testTenantId } | Should -Throw "*Failed to connect to Azure*"
        }

        It 'Should throw when Connect-Azure fails for ByEnvironment' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-SubnetInjectionEnterprisePolicy `
                -EnvironmentId $script:testEnvironmentId `
                -Endpoint Prod } | Should -Throw "*Failed to connect to Azure*"
        }
    }

    Context 'ForceAuth parameter' {
        BeforeAll {
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should pass ForceAuth to Connect-Azure' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            Get-SubnetInjectionEnterprisePolicy `
                -PolicyResourceId $script:testPolicyResourceId `
                -TenantId $script:testTenantId `
                -ForceAuth

            Should -Invoke Connect-Azure -Times 1 -ParameterFilter { $Force -eq $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

}
