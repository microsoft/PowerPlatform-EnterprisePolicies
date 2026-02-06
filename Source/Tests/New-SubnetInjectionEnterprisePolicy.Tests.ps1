[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'New-SubnetInjectionEnterprisePolicy Tests' {
    BeforeAll {
        $script:testSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:testResourceGroup = "test-rg"
        $script:testPolicyName = "test-policy"
        $script:testPolicyLocation = "unitedstates"
        $script:testTenantId = "87654321-4321-4321-4321-210987654321"
        $script:testVnetId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.Network/virtualNetworks/test-vnet"
        $script:testSubnetName = "default"
        $script:testVnetId2 = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.Network/virtualNetworks/test-vnet2"
        $script:testSubnetName2 = "default2"

        $script:mockVnetResource = [PSCustomObject]@{
            ResourceId = $script:testVnetId
            Location = "eastus"
        }

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:testPolicyName"
            Name = $script:testPolicyName
            Properties = @{ networkInjection = @{ virtualNetworks = @() } }
        }

        $script:mockBody = @{
            "`$schema" = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
            "contentVersion" = "1.0.0.0"
            "resources" = @(@{ "type" = "Microsoft.PowerPlatform/enterprisePolicies" })
        }

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-AzContext {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Successful policy creation' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Initialize-SubscriptionForPowerPlatform { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Test-PowerPlatformRegionRequiresPair { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-VirtualNetwork { return $script:mockVnetResource } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-EnterprisePolicyBody { return $script:mockBody } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnterprisePolicy { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create policy and return PSResource object' {
            $result = New-SubnetInjectionEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation `
                -VirtualNetworkId $script:testVnetId `
                -SubnetName $script:testSubnetName `
                -TenantId $script:testTenantId

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testPolicyName
        }
    }

    Context 'Paired VNet regions' {
        BeforeAll {
            $mockVnetResource2 = [PSCustomObject]@{
                ResourceId = $script:testVnetId2
                Location = "westus"
            }

            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Initialize-SubscriptionForPowerPlatform { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Test-PowerPlatformRegionRequiresPair { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-VirtualNetwork {
                param($VirtualNetworkId)
                if ($VirtualNetworkId -eq $script:testVnetId) { return $script:mockVnetResource }
                if ($VirtualNetworkId -eq $script:testVnetId2) { return $mockVnetResource2 }
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Assert-RegionPairing {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-EnterprisePolicyBody { return $script:mockBody } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnterprisePolicy { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create policy with paired VNets' {
            $result = New-SubnetInjectionEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation `
                -VirtualNetworkId $script:testVnetId `
                -SubnetName $script:testSubnetName `
                -VirtualNetworkId2 $script:testVnetId2 `
                -SubnetName2 $script:testSubnetName2 `
                -TenantId $script:testTenantId

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Assert-RegionPairing -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should throw when region pairing validation fails' {
            Mock Assert-RegionPairing { throw "The regions are not a supported pair" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-SubnetInjectionEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation `
                -VirtualNetworkId $script:testVnetId `
                -SubnetName $script:testSubnetName `
                -VirtualNetworkId2 $script:testVnetId2 `
                -SubnetName2 $script:testSubnetName2 `
                -TenantId $script:testTenantId } | Should -Throw "*not a supported pair*"
        }
    }

    Context 'Error handling' {
        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-SubnetInjectionEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation `
                -VirtualNetworkId $script:testVnetId `
                -SubnetName $script:testSubnetName `
                -TenantId $script:testTenantId } | Should -Throw "*Failed to connect to Azure*"
        }

        It 'Should throw when subscription initialization fails' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Initialize-SubscriptionForPowerPlatform { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-SubnetInjectionEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation `
                -VirtualNetworkId $script:testVnetId `
                -SubnetName $script:testSubnetName `
                -TenantId $script:testTenantId } | Should -Throw "*Failed to initialize subscription*"
        }

        It 'Should throw when VNet retrieval fails' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Initialize-SubscriptionForPowerPlatform { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Test-PowerPlatformRegionRequiresPair { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-VirtualNetwork { throw "Error getting virtual network" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-SubnetInjectionEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation `
                -VirtualNetworkId $script:testVnetId `
                -SubnetName $script:testSubnetName `
                -TenantId $script:testTenantId } | Should -Throw "*Error getting virtual network*"
        }

        It 'Should throw when policy deployment fails' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Initialize-SubscriptionForPowerPlatform { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Test-PowerPlatformRegionRequiresPair { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-VirtualNetwork { return $script:mockVnetResource } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-EnterprisePolicyBody { return $script:mockBody } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnterprisePolicy { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-SubnetInjectionEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation `
                -VirtualNetworkId $script:testVnetId `
                -SubnetName $script:testSubnetName `
                -TenantId $script:testTenantId } | Should -Throw "*Failed to create Subnet Injection Enterprise Policy*"
        }
    }
}
