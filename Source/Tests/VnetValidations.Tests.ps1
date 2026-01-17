BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1 -Module
}

Describe 'VnetValidations Tests' {
    InModuleScope 'Microsoft.PowerPlatform.EnterprisePolicies'{
        BeforeAll{
            Mock Write-Host {}
        }
        
        Context 'Testing Assert-AzureRegionIsSupported'{
            It 'Throws an error for unsupported Azure region' {
                { Assert-AzureRegionIsSupported -PowerPlatformRegion "unitedstates" -AzureRegion "westus2" } | Should -Throw
            }
    
            It 'Does not throw an error for supported Azure region' {
                { Assert-AzureRegionIsSupported -PowerPlatformRegion "unitedstates" -AzureRegion "eastus" } | Should -Not -Throw
            }
        }
    
        Context 'Testing Assert-PowerPlatformRegionIsSupported' {
            It 'Throws an error for unsupported Power Platform region' {
                { Assert-PowerPlatformRegionIsSupported -PowerPlatformRegion "UnknownRegion" } | Should -Throw
            }
    
            It 'Does not throw an error for supported Power Platform region' {
                { Assert-PowerPlatformRegionIsSupported -PowerPlatformRegion "unitedstates" } | Should -Not -Throw
            }
        }
    
        Context 'Testing Get-SupportedVnetRegionsForPowerPlatformRegion' {
            It 'Returns supported Azure regions for a valid Power Platform region' {
                $result = Get-SupportedVnetRegionsForPowerPlatformRegion -PowerPlatformRegion "unitedstates"
                $result | Should -Contain "eastus"
                $result | Should -Contain "westus"
            }

            It 'Throws an error for unsupported Power Platform region' {
                { Get-SupportedVnetRegionsForPowerPlatformRegion -PowerPlatformRegion "UnknownRegion" } | Should -Throw
            }
        }

        Context 'Testing Test-PowerPlatformRegionRequiresPair' {
            It 'Returns true for regions requiring paired VNets' {
                $result = Test-PowerPlatformRegionRequiresPair -PowerPlatformRegion "unitedstates"
                $result | Should -Be $true
            }

            It 'Returns false for regions not requiring paired VNets' {
                $result = Test-PowerPlatformRegionRequiresPair -PowerPlatformRegion "brazil"
                $result | Should -Be $false
            }

            It 'Throws for unsupported region' {
                { Test-PowerPlatformRegionRequiresPair -PowerPlatformRegion "UnknownRegion" } | Should -Throw
            }
        }

        Context 'Testing Get-VirtualNetwork' {
            It 'Returns VNet resource when found and region is valid' {
                $mockVnet = [PSCustomObject]@{
                    ResourceId = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet"
                    Location = "eastus"
                }
                Mock Get-AzResource { return $mockVnet }

                $result = Get-VirtualNetwork -VirtualNetworkId $mockVnet.ResourceId -EnterprisePolicyLocation "unitedstates"

                $result.ResourceId | Should -Be $mockVnet.ResourceId
            }

            It 'Throws when VNet is not found' {
                Mock Get-AzResource { return [PSCustomObject]@{ ResourceId = $null } }

                { Get-VirtualNetwork -VirtualNetworkId "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/nonexistent" -EnterprisePolicyLocation "unitedstates" } | Should -Throw "*Error getting virtual network*"
            }

            It 'Throws when VNet region is not supported for the Power Platform region' {
                $mockVnet = [PSCustomObject]@{
                    ResourceId = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet"
                    Location = "northeurope"
                }
                Mock Get-AzResource { return $mockVnet }

                { Get-VirtualNetwork -VirtualNetworkId $mockVnet.ResourceId -EnterprisePolicyLocation "unitedstates" } | Should -Throw
            }
        }

        Context 'Testing Assert-RegionPairing' {
            It 'Does not throw for valid region pair' {
                $vnet1 = [PSCustomObject]@{ Location = "eastus" }
                $vnet2 = [PSCustomObject]@{ Location = "westus" }
                $vnets = @(
                    [VnetInformation]::new($vnet1, "subnet1"),
                    [VnetInformation]::new($vnet2, "subnet2")
                )

                { Assert-RegionPairing -VnetInformation $vnets -PowerPlatformRegion "unitedstates" } | Should -Not -Throw
            }

            It 'Throws for invalid region pair' {
                $vnet1 = [PSCustomObject]@{ Location = "eastus" }
                $vnet2 = [PSCustomObject]@{ Location = "northeurope" }
                $vnets = @(
                    [VnetInformation]::new($vnet1, "subnet1"),
                    [VnetInformation]::new($vnet2, "subnet2")
                )

                { Assert-RegionPairing -VnetInformation $vnets -PowerPlatformRegion "unitedstates" } | Should -Throw "*not a supported pair*"
            }

            It 'Throws when same region is used for both VNets' {
                $vnet1 = [PSCustomObject]@{ Location = "eastus" }
                $vnet2 = [PSCustomObject]@{ Location = "eastus" }
                $vnets = @(
                    [VnetInformation]::new($vnet1, "subnet1"),
                    [VnetInformation]::new($vnet2, "subnet2")
                )

                { Assert-RegionPairing -VnetInformation $vnets -PowerPlatformRegion "unitedstates" } | Should -Throw "*not a supported pair*"
            }

            It 'Throws when not exactly 2 VNets provided' {
                $vnet1 = [PSCustomObject]@{ Location = "eastus" }
                $vnets = @([VnetInformation]::new($vnet1, "subnet1"))

                { Assert-RegionPairing -VnetInformation $vnets -PowerPlatformRegion "unitedstates" } | Should -Throw "*requires exactly 2 vnets*"
            }
        }
    }
}