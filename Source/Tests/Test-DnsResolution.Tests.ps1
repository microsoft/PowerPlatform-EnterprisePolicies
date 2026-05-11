[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Test-DnsResolution Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
        $secureString = (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force)
        Mock Get-PPAPIAccessToken { return $secureString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Warning {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Testing Test-DnsResolution' {
        It 'Returns HostResolutionInformation on successful resolution' {
            $stringResult = '{"Success":true,"HostName":"bing.com","IPAddresses":["13.107.21.200"],"DnsServers":["10.0.0.10"],"ErrorMessage":null,"ContainerIpAddress":"10.1.2.3"}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $region = "westus"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-JsonRequestMessage -ParameterFilter { $Query.EndsWith($region) } { return "message" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-DnsResolution -EnvironmentId $environmentId -HostName "bing.com" -Endpoint $endpoint -Region $region

            $result | Should -BeOfType [HostResolutionInformation]
            $result.Success | Should -BeTrue
            $result.HostName | Should -Be "bing.com"
            $result.IPAddresses | Should -Contain "13.107.21.200"
            Should -Not -Invoke Write-Warning -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Warns when DNS resolution fails' {
            $stringResult = '{"Success":false,"HostName":"unresolvable.local","IPAddresses":[],"DnsServers":["10.0.0.10"],"ErrorMessage":"NXDOMAIN","ContainerIpAddress":"10.1.2.3"}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $region = "westus"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-DnsResolution -EnvironmentId $environmentId -HostName "unresolvable.local" -Endpoint $endpoint -Region $region

            $result | Should -BeOfType [HostResolutionInformation]
            $result.Success | Should -BeFalse
            Should -Invoke Write-Warning -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { $Message -like "*DNS resolution failed*" }
        }

        It 'Auto-resolves region when not provided' {
            $stringResult = '{"Success":true,"HostName":"bing.com","IPAddresses":["13.107.21.200"],"DnsServers":["10.0.0.10"],"ErrorMessage":null,"ContainerIpAddress":"10.1.2.3"}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnvironmentRegionFromCache { return "westus" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $null = Test-DnsResolution -EnvironmentId $environmentId -HostName "bing.com" -Endpoint $endpoint

            Should -Invoke Get-EnvironmentRegionFromCache -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Returns raw string when JSON deserialization fails' {
            $stringResult = '{"unexpectedFormat": true}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")
            $region = "westus"

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock ConvertFrom-JsonToClass { throw "Deserialization failed" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-DnsResolution -EnvironmentId $environmentId -HostName "bing.com" -Endpoint $endpoint -Region $region

            $result | Should -Be $stringResult
        }
    }
}
