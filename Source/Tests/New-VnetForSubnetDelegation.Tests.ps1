[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'New-VnetForSubnetDelegation Tests' {
    BeforeAll {
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-AzContext {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock New-AzDelegation { return @{Name = "Microsoft.PowerPlatform/enterprisePolicies"; ServiceName = "Microsoft.PowerPlatform/enterprisePolicies"} } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Initialize-SubscriptionForPowerPlatform { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Testing parameter validation' {
        It 'Should validate AddressPrefix pattern' {
            Mock Get-AzResourceGroup { return @{ResourceGroupName = "test-rg"} } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            { New-VnetForSubnetDelegation -SubscriptionId "12345678-1234-1234-1234-123456789012" -VirtualNetworkName "test-vnet" -SubnetName "default" -ResourceGroupName "test-rg" -CreateVirtualNetwork -Region "eastus" -AddressPrefix "invalid" -SubnetPrefix "10.0.1.0/24" } | Should -Throw
        }

        It 'Should validate SubnetPrefix pattern' {
            Mock Get-AzResourceGroup { return @{ResourceGroupName = "test-rg"} } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            { New-VnetForSubnetDelegation -SubscriptionId "12345678-1234-1234-1234-123456789012" -VirtualNetworkName "test-vnet" -SubnetName "default" -ResourceGroupName "test-rg" -CreateVirtualNetwork -Region "eastus" -AddressPrefix "10.0.0.0/16" -SubnetPrefix "invalid" } | Should -Throw
        }
    }

    Context 'Testing existing VNet configuration' {
        BeforeAll {
            $mockVNet = [PSCustomObject]@{
                Name = "test-vnet"
                Id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
                Location = "eastus"
            }

            $mockSubnet = [PSCustomObject]@{
                Name = "default"
                Id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
                Delegations = @()
            }

            Mock Get-AzVirtualNetwork { return $mockVNet } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzVirtualNetworkSubnetConfig { return $mockSubnet } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Add-AzDelegation { return $mockSubnet } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-AzVirtualNetwork { return $mockVNet } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should configure existing VNet and subnet with delegation' {
            $result = New-VnetForSubnetDelegation -SubscriptionId "12345678-1234-1234-1234-123456789012" -VirtualNetworkName "test-vnet" -SubnetName "default" -ResourceGroupName "test-rg"

            $result.Name | Should -Be "test-vnet"
            $result.Id | Should -Be "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"

            Should -Invoke Get-AzVirtualNetwork -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Should -Invoke Get-AzVirtualNetworkSubnetConfig -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Should -Invoke Add-AzDelegation -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Should -Invoke Set-AzVirtualNetwork -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should skip adding delegation if it already exists' {
            $mockSubnetWithDelegation = [PSCustomObject]@{
                Name = "default"
                Id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
                Delegations = @([PSCustomObject]@{ ServiceName = "Microsoft.PowerPlatform/enterprisePolicies" })
            }

            Mock Get-AzVirtualNetworkSubnetConfig { return $mockSubnetWithDelegation } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = New-VnetForSubnetDelegation -SubscriptionId "12345678-1234-1234-1234-123456789012" -VirtualNetworkName "test-vnet" -SubnetName "default" -ResourceGroupName "test-rg"

            Should -Invoke Add-AzDelegation -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Testing new VNet creation' {
        BeforeAll {
            $mockResourceGroup = [PSCustomObject]@{
                ResourceGroupName = "test-rg"
                Location = "eastus"
            }

            $mockVNet = [PSCustomObject]@{
                Name = "test-vnet"
                Id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
                Location = "eastus"
            }

            $mockSubnet = [PSCustomObject]@{
                Name = "default"
                Id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
                Delegations = @()
            }

            Mock Get-AzResourceGroup { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-AzResourceGroup { return $mockResourceGroup } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzVirtualNetwork { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-AzVirtualNetworkSubnetConfig { return $mockSubnet } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-AzVirtualNetwork { return $mockVNet } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzVirtualNetworkSubnetConfig { return $mockSubnet } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Add-AzDelegation { return $mockSubnet } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-AzVirtualNetwork { return $mockVNet } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create new resource group when it does not exist' {
            $result = New-VnetForSubnetDelegation -SubscriptionId "12345678-1234-1234-1234-123456789012" -VirtualNetworkName "test-vnet" -SubnetName "default" -ResourceGroupName "test-rg" -CreateVirtualNetwork -Region "eastus" -AddressPrefix "10.0.0.0/16" -SubnetPrefix "10.0.1.0/24"

            Should -Invoke New-AzResourceGroup -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create new VNet with subnet and delegation' {
            $result = New-VnetForSubnetDelegation -SubscriptionId "12345678-1234-1234-1234-123456789012" -VirtualNetworkName "test-vnet" -SubnetName "default" -ResourceGroupName "test-rg" -CreateVirtualNetwork -Region "eastus" -AddressPrefix "10.0.0.0/16" -SubnetPrefix "10.0.1.0/24"

            $result.Name | Should -Be "test-vnet"
            $result.Location | Should -Be "eastus"

            Should -Invoke New-AzVirtualNetworkSubnetConfig -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Should -Invoke New-AzVirtualNetwork -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Should -Invoke New-AzDelegation -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should use existing resource group if it exists' {
            Mock Get-AzResourceGroup { return $mockResourceGroup } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = New-VnetForSubnetDelegation -SubscriptionId "12345678-1234-1234-1234-123456789012" -VirtualNetworkName "test-vnet" -SubnetName "default" -ResourceGroupName "test-rg" -CreateVirtualNetwork -Region "eastus" -AddressPrefix "10.0.0.0/16" -SubnetPrefix "10.0.1.0/24"

            Should -Invoke New-AzResourceGroup -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should use existing VNet if it exists when CreateVirtualNetwork is specified' {
            Mock Get-AzVirtualNetwork { return $mockVNet } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = New-VnetForSubnetDelegation -SubscriptionId "12345678-1234-1234-1234-123456789012" -VirtualNetworkName "test-vnet" -SubnetName "default" -ResourceGroupName "test-rg" -CreateVirtualNetwork -Region "eastus" -AddressPrefix "10.0.0.0/16" -SubnetPrefix "10.0.1.0/24"

            Should -Invoke New-AzVirtualNetwork -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Testing error handling' {
        It 'Should throw when VNet does not exist and CreateVirtualNetwork is not specified' {
            Mock Get-AzVirtualNetwork { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-VnetForSubnetDelegation -SubscriptionId "12345678-1234-1234-1234-123456789012" -VirtualNetworkName "nonexistent-vnet" -SubnetName "default" -ResourceGroupName "test-rg" } | Should -Throw "*not found*"
        }

        It 'Should throw when subnet does not exist and CreateVirtualNetwork is not specified' {
            $mockVNet = [PSCustomObject]@{
                Name = "test-vnet"
                Id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
            }

            Mock Get-AzVirtualNetwork { return $mockVNet } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzVirtualNetworkSubnetConfig { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-VnetForSubnetDelegation -SubscriptionId "12345678-1234-1234-1234-123456789012" -VirtualNetworkName "test-vnet" -SubnetName "nonexistent-subnet" -ResourceGroupName "test-rg" } | Should -Throw "*not found*"
        }

        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-VnetForSubnetDelegation -SubscriptionId "12345678-1234-1234-1234-123456789012" -VirtualNetworkName "test-vnet" -SubnetName "default" -ResourceGroupName "test-rg" } | Should -Throw "*Failed to connect to Azure*"
        }
    }
}
