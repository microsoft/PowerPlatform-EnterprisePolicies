BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Remove-SubnetInjectionEnterprisePolicy Tests' {
    BeforeAll {
        $script:testSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:testResourceGroup = "test-rg"
        $script:testPolicyName = "test-policy"
        $script:testTenantId = "87654321-4321-4321-4321-210987654321"
        $script:testPolicyResourceId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:testPolicyName"

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyResourceId
            Name = $script:testPolicyName
            Kind = "NetworkInjection"
        }

        $script:mockPolicy2 = [PSCustomObject]@{
            ResourceId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/test-policy-2"
            Name = "test-policy-2"
            Kind = "NetworkInjection"
        }

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-AzContext {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'ByResourceId parameter set' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Remove-AzResource {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should remove policy by resource ID' {
            Remove-SubnetInjectionEnterprisePolicy -PolicyResourceId $script:testPolicyResourceId -Confirm:$false

            Should -Invoke Remove-AzResource -Times 1 -ParameterFilter {
                $ResourceId -eq $script:testPolicyResourceId -and $Force -eq $true
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should pass TenantId to Connect-Azure' {
            Remove-SubnetInjectionEnterprisePolicy `
                -PolicyResourceId $script:testPolicyResourceId `
                -TenantId $script:testTenantId `
                -Confirm:$false

            Should -Invoke Connect-Azure -Times 1 -ParameterFilter {
                $TenantId -eq $script:testTenantId
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should pass AzureEnvironment to Connect-Azure' {
            Remove-SubnetInjectionEnterprisePolicy `
                -PolicyResourceId $script:testPolicyResourceId `
                -AzureEnvironment AzureUSGovernment `
                -Confirm:$false

            Should -Invoke Connect-Azure -Times 1 -ParameterFilter {
                $AzureEnvironment -eq [AzureEnvironment]::AzureUSGovernment
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should pass ForceAuth to Connect-Azure' {
            Remove-SubnetInjectionEnterprisePolicy `
                -PolicyResourceId $script:testPolicyResourceId `
                -ForceAuth `
                -Confirm:$false

            Should -Invoke Connect-Azure -Times 1 -ParameterFilter {
                $Force -eq $true
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should throw when PolicyResourceId format is invalid' {
            { Remove-SubnetInjectionEnterprisePolicy -PolicyResourceId "invalid-resource-id" -Confirm:$false } |
                Should -Throw "*Invalid PolicyResourceId format*"
        }
    }

    Context 'BySubscription parameter set' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Remove-AzResource {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should remove single policy in subscription' {
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            Remove-SubnetInjectionEnterprisePolicy -SubscriptionId $script:testSubscriptionId -Confirm:$false

            Should -Invoke Remove-AzResource -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should output policy IDs when multiple policies found in subscription' {
            Mock Get-EnterprisePolicy { return @($script:mockPolicy, $script:mockPolicy2) } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            Remove-SubnetInjectionEnterprisePolicy -SubscriptionId $script:testSubscriptionId -Confirm:$false

            Should -Invoke Remove-AzResource -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Should -Invoke Write-Host -Times 3 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'ByResourceGroup parameter set' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Remove-AzResource {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should remove single policy in resource group' {
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            Remove-SubnetInjectionEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -Confirm:$false

            Should -Invoke Remove-AzResource -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should output policy IDs when multiple policies found in resource group' {
            Mock Get-EnterprisePolicy { return @($script:mockPolicy, $script:mockPolicy2) } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            Remove-SubnetInjectionEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -Confirm:$false

            Should -Invoke Remove-AzResource -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Should -Invoke Write-Host -Times 3 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Policy not found' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should throw when policy does not exist' {
            Mock Get-EnterprisePolicy { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Remove-SubnetInjectionEnterprisePolicy -PolicyResourceId $script:testPolicyResourceId -Confirm:$false } |
                Should -Throw "*No enterprise policies found*"
        }
    }

    Context 'Connection failure' {
        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Remove-SubnetInjectionEnterprisePolicy -PolicyResourceId $script:testPolicyResourceId -Confirm:$false } |
                Should -Throw "*Failed to connect to Azure*"
        }
    }

    Context 'WhatIf support' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Remove-AzResource {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should not remove policy when WhatIf is specified' {
            Remove-SubnetInjectionEnterprisePolicy -PolicyResourceId $script:testPolicyResourceId -WhatIf

            Should -Invoke Remove-AzResource -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Force parameter' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Remove-AzResource {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should remove policy without confirmation when Force is specified' {
            Remove-SubnetInjectionEnterprisePolicy -PolicyResourceId $script:testPolicyResourceId -Force

            Should -Invoke Remove-AzResource -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }
}
