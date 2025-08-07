BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1 -Module
}

Describe 'VnetValidations Tests' {
    BeforeAll{
        Mock Write-Host {} -ModuleName "VnetValidations"
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
}