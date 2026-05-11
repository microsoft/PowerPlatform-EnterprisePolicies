[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Test-NetworkConnectivity Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
        $secureString = (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force)
        Mock Get-PPAPIAccessToken { return $secureString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Warning {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Testing Test-NetworkConnectivity' {
        It 'Returns ConnectivityInformation on successful connection' {
            $stringResult = '{"TCPSuccess":true,"TCPErrorMessage":null,"Destination":"bing.com","Port":443,"ContainerIpAddress":"10.1.2.3"}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")
            $region = "westus"

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-JsonRequestMessage -ParameterFilter { $Query.EndsWith($region) } { return "message" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-NetworkConnectivity -EnvironmentId $environmentId -Destination "bing.com" -Port 443 -TenantId "0123" -Endpoint $endpoint -Region $region

            $result | Should -BeOfType [ConnectivityInformation]
            $result.TCPSuccess | Should -BeTrue
            $result.Destination | Should -Be "bing.com"
            $result.Port | Should -Be 443
            Should -Not -Invoke Write-Warning -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Warns when TCP connectivity fails' {
            $stringResult = '{"TCPSuccess":false,"TCPErrorMessage":"Connection refused","Destination":"bing.com","Port":1234,"ContainerIpAddress":"10.1.2.3"}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")
            $region = "westus"

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-NetworkConnectivity -EnvironmentId $environmentId -Destination "bing.com" -Port 1234 -Endpoint $endpoint -Region $region

            $result | Should -BeOfType [ConnectivityInformation]
            $result.TCPSuccess | Should -BeFalse
            Should -Invoke Write-Warning -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { $Message -like "*TCP connectivity failed*" }
        }

        It 'Auto-resolves region when not provided' {
            $stringResult = '{"TCPSuccess":true,"TCPErrorMessage":null,"Destination":"bing.com","Port":443,"ContainerIpAddress":"10.1.2.3"}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnvironmentRegionFromCache { return "westus" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $null = Test-NetworkConnectivity -EnvironmentId $environmentId -Destination "bing.com" -Port 443 -Endpoint $endpoint

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

            $result = Test-NetworkConnectivity -EnvironmentId $environmentId -Destination "bing.com" -Port 443 -Endpoint $endpoint -Region $region

            $result | Should -Be $stringResult
        }
    }
}
