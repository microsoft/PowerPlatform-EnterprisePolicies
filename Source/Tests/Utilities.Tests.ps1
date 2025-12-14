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
    }
}
