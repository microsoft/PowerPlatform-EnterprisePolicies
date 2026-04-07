[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Test-TLSHandshake Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
        $secureString = (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force)
        Mock Get-AccessToken { return $secureString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {}
        Mock Write-Warning {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Testing Test-TLSHandshake' {
        It 'Returns string when response is not JSON' {
            $stringResult = 'Some non-JSON string'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult)
            $region = "westus"

            Mock Send-RequestWithRetries { return $mockResult } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-TLSHandshake -EnvironmentId $environmentId -Destination "bing.com" -Port 443 -TenantId "0123" -Endpoint $endpoint -Region $region

            $result | Should -Be $stringResult
        }

        It 'Auto-resolves region when not provided' {
            $stringResult = '{"TCPConnectivity":true,"Certificate":null,"SSLWithoutCRL":null,"SSLWithCRL":null}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult)

            Mock Send-RequestWithRetries { return $mockResult } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnvironmentRegionFromCache { return "westus" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-TLSHandshake -EnvironmentId $environmentId -Destination "bing.com" -Port 443 -Endpoint $endpoint

            Should -Invoke Get-EnvironmentRegionFromCache -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Returns TLSConnectivityInformation on successful handshake' {
            $stringResult = '{"TCPConnectivity":true,"Certificate":{"Issuer":"CN=Test CA","Subject":"CN=test.com","SignatureAlgorithm":"sha256RSA","IsExpired":false},"SSLWithoutCRL":{"Protocols":"12288","Success":true,"SslErrors":"0","CipherSuite":"4866"},"SSLWithCRL":{"Protocols":"12288","Success":true,"SslErrors":"0","CipherSuite":null}}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")
            $region = "westus"

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-TLSHandshake -EnvironmentId $environmentId -Destination "bing.com" -Port 443 -TenantId "0123" -Endpoint $endpoint -Region $region

            $result | Should -BeOfType [TLSConnectivityInformation]
            $result.TCPConnectivity | Should -BeTrue
            $result.SSLWithoutCRL.Success | Should -BeTrue
            $result.SSLWithCRL.Success | Should -BeTrue
            Should -Not -Invoke Write-Warning -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Warns when TCP connectivity fails' {
            $stringResult = '{"TCPConnectivity":false,"Certificate":null,"SSLWithoutCRL":null,"SSLWithCRL":null}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")
            $region = "westus"

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-TLSHandshake -EnvironmentId $environmentId -Destination "bing.com" -Port 443 -TenantId "0123" -Endpoint $endpoint -Region $region

            $result | Should -BeOfType [TLSConnectivityInformation]
            $result.TCPConnectivity | Should -BeFalse
            Should -Invoke Write-Warning -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { $Message -like "*TCP connectivity*" }
        }

        It 'Warns when TLS handshake fails' {
            $stringResult = '{"TCPConnectivity":true,"Certificate":null,"SSLWithoutCRL":{"Protocols":"12288","Success":false,"SslErrors":"1","CipherSuite":null},"SSLWithCRL":null}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")
            $region = "westus"

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-TLSHandshake -EnvironmentId $environmentId -Destination "bing.com" -Port 443 -TenantId "0123" -Endpoint $endpoint -Region $region

            $result | Should -BeOfType [TLSConnectivityInformation]
            Should -Invoke Write-Warning -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { $Message -like "*TLS handshake failed*" }
        }

        It 'Warns when CRL check fails but TLS without CRL succeeds' {
            $stringResult = '{"TCPConnectivity":true,"Certificate":{"Issuer":"CN=Test CA","Subject":"CN=test.com","SignatureAlgorithm":"sha256RSA","IsExpired":false},"SSLWithoutCRL":{"Protocols":"12288","Success":true,"SslErrors":"0","CipherSuite":"4866"},"SSLWithCRL":{"Protocols":"12288","Success":false,"SslErrors":"4","CipherSuite":null}}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")
            $region = "westus"

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-TLSHandshake -EnvironmentId $environmentId -Destination "bing.com" -Port 443 -TenantId "0123" -Endpoint $endpoint -Region $region

            $result | Should -BeOfType [TLSConnectivityInformation]
            $result.SSLWithoutCRL.Success | Should -BeTrue
            $result.SSLWithCRL.Success | Should -BeFalse
            Should -Invoke Write-Warning -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { $Message -like "*Certificate Revocation List*" }
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

            $result = Test-TLSHandshake -EnvironmentId $environmentId -Destination "bing.com" -Port 443 -TenantId "0123" -Endpoint $endpoint -Region $region

            $result | Should -Be $stringResult
        }
    }
}
