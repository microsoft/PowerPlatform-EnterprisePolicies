[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1 -Module
}

Describe 'Utilities Tests' {
    InModuleScope 'Microsoft.PowerPlatform.EnterprisePolicies'{
        
        Context 'Testing Get-LogDate' {
            It 'Returns date in UTC format with correct timezone indicator' {
                $result = Get-LogDate
                
                # Result should contain a UTC timezone indicator (Z or +00:00)
                $result | Should -Match 'Z$|(\+|\-)00:00$'
            }

            It 'Returns date in expected format dd/MM/yyyy:HH:mm:ss:K' {
                $result = Get-LogDate
                
                # Should match the pattern: dd/MM/yyyy:HH:mm:ss:K where K is timezone
                $result | Should -Match '^\d{2}/\d{2}/\d{4}:\d{2}:\d{2}:\d{2}:(Z|[\+\-]\d{2}:\d{2})$'
            }

            It 'Uses UTC time not local time' {
                $result = Get-LogDate
                $utcNow = [DateTime]::UtcNow
                
                # Parse the date portion from result (dd/MM/yyyy)
                $resultDate = $result.Substring(0, 10)
                $expectedDate = $utcNow.ToString("dd/MM/yyyy")
                
                $resultDate | Should -Be $expectedDate
            }
        }

        Context 'Testing Get-ModuleVersion' {
            It 'Returns a non-empty version string' {
                $version = Get-ModuleVersion
                $version | Should -Not -BeNullOrEmpty
            }

            It 'Returns a version string in valid format' {
                $version = Get-ModuleVersion
                # Version should match the pattern Major.Minor.Build.Revision
                $version | Should -Match '^\d+\.\d+\.\d+(\.\d+)?$'
            }

            It 'Stores version in script scope for reuse' {
                # Clear any existing value
                Remove-Variable -Name script:ModuleVersion -ErrorAction SilentlyContinue
                
                # First call should set the variable
                $firstCallVersion = Get-ModuleVersion
                $script:ModuleVersion | Should -Be $firstCallVersion
                
                # Modify the variable to test reuse
                $script:ModuleVersion = "ModifiedVersion"
                
                # Second call should return the modified value
                $secondCallVersion = Get-ModuleVersion
                $secondCallVersion | Should -Be "ModifiedVersion"

                # Clear any existing value
                Remove-Variable -Name script:ModuleVersion -ErrorAction SilentlyContinue
            }

            It 'Returns consistent version across multiple calls' {
                $version1 = Get-ModuleVersion
                $version2 = Get-ModuleVersion
                $version1 | Should -Be $version2
            }
        }

        Context 'Testing Test-LatestModuleVersion' {
            BeforeAll {
                Mock Write-Host {}
                Mock Write-Warning {}
                Mock Write-Verbose {}
            }

            It 'Shows warning when a newer version is available' {
                Mock Get-ModuleVersion { return "1.0.0" }
                Mock Find-Module { return [PSCustomObject]@{ Version = "2.0.0" } }

                Test-LatestModuleVersion

                Should -Invoke Write-Warning -Times 1 -ParameterFilter { $Message -like "*latest version is 2.0.0*" }
            }

            It 'Does not show warning when current version is the latest' {
                Mock Get-ModuleVersion { return "2.0.0" }
                Mock Find-Module { return [PSCustomObject]@{ Version = "2.0.0" } }

                Test-LatestModuleVersion

                Should -Not -Invoke Write-Warning
            }

            It 'Does not show warning when current version is newer than PSGallery' {
                Mock Get-ModuleVersion { return "3.0.0" }
                Mock Find-Module { return [PSCustomObject]@{ Version = "2.0.0" } }

                Test-LatestModuleVersion

                Should -Not -Invoke Write-Warning
            }

            It 'Handles errors gracefully when Find-Module fails' {
                Mock Get-ModuleVersion { return "1.0.0" }
                Mock Find-Module { throw "Network error" }

                { Test-LatestModuleVersion } | Should -Not -Throw
                Should -Invoke Write-Verbose -Times 1 -ParameterFilter { $Message -like "*Could not check for the latest module version*" }
            }

            It 'Handles errors gracefully when Get-ModuleVersion fails' {
                Mock Get-ModuleVersion { throw "Cannot read version" }
                Mock Find-Module { return [PSCustomObject]@{ Version = "1.0.0" } }

                { Test-LatestModuleVersion } | Should -Not -Throw
                Should -Invoke Write-Verbose -Times 1 -ParameterFilter { $Message -like "*Could not check for the latest module version*" }
            }
        }
    }
}
