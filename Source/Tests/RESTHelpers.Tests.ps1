[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1 -Module
}

Describe 'RESTHelpers Tests' {
    InModuleScope 'Microsoft.PowerPlatform.EnterprisePolicies'{
        BeforeAll{
            Mock Write-Host {}
        }
        
        Context 'Testing Get-APIResourceUrl' {
            It 'Throws an error for unsupported endpoint' {
                { Get-APIResourceUrl -Endpoint ([BAPEndpoint]::unknown) } | Should -Throw "Unsupported BAP endpoint: unknown"
            }
    
            It 'Returns the correct resource URL for a valid endpoint' {
                $result = Get-APIResourceUrl -Endpoint ([BAPEndpoint]::prod)
                $result | Should -Be "https://api.powerplatform.com/"
            }
        }
    
        Context 'Testing Get-EnvironmentRouteHostName' {
            It 'Returns the correct route for TIP1 endpoint' {
                $result = Get-EnvironmentRouteHostName -EnvironmentId "12345678-1234-1234-1234-123456789012" -Endpoint ([BAPEndpoint]::tip1)
                $result | Should -Be "1234567812341234123412345678901.2.environment.api.preprod.powerplatform.com"
            }
    
            It 'Returns the correct route for PROD endpoint' {
                $result = Get-EnvironmentRouteHostName -EnvironmentId "3496a854-39b3-41bd-a783-1f2479ca3fbd" -Endpoint ([BAPEndpoint]::prod)
                $result | Should -Be "3496a85439b341bda7831f2479ca3f.bd.environment.api.powerplatform.com"
            }
    
            It 'Returns the correct route when EnvironmentId is not a Guid' {
                $result = Get-EnvironmentRouteHostName -EnvironmentId "Default3496a854-39b3-41bd-a783-1f2479ca3fbd" -Endpoint ([BAPEndpoint]::prod)
                $result | Should -Be "Default3496a85439b341bda7831f2479ca3f.bd.environment.api.powerplatform.com"
            }
        }

        Context 'Testing New-EnvironmentRouteRequest' {
            It 'Creates a request with the correct URI and method' {
                $envId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
                $path = "/plex/networkUsage"
                $query = "api-version=2024-10-01"
                $secureString = (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force)
                $httpMethod = [System.Net.Http.HttpMethod]::Get
                $endpoint = [BAPEndpoint]::prod

                $result = New-EnvironmentRouteRequest -EnvironmentId $envId -Path $path -Query $query -AccessToken $secureString -HttpMethod $httpMethod -Endpoint $endpoint

                $result.RequestUri.AbsoluteUri | Should -Be "https://primary-3496a85439b341bda7831f2479ca3f.bd.environment.api.powerplatform.com/plex/networkUsage?api-version=2024-10-01"
                $result.Method | Should -Be $httpMethod
                $result.Headers.Host | Should -Be "3496a85439b341bda7831f2479ca3f.bd.environment.api.powerplatform.com"
            }
        }

        Context 'Testing Get-HttpClient' {
            It 'Returns an HttpClient with no headers' {
                $client = Get-HttpClient
                $client.DefaultRequestHeaders | ForEach-Object { $_ | Should -BeNullOrEmpty }
            }

            It 'Follows a singleton pattern'{
                Mock New-Object -ParameterFilter { $TypeName -eq 'System.Net.Http.HttpClient' } { [System.Net.Http.HttpClient]::new() } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Get-HttpClient
                Get-HttpClient
                Should -Invoke New-Object -Times 1
            }
        }

        Context 'Testing Send-RequestWithRetries' {
            It 'Returns the result of a successful request' {
                $mockClient = [HttpClientMock]::new()
                $mockResult = [HttpClientResultMock]::new("Some string")
                Mock Get-HttpClient { return $mockClient } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Get-AsyncResult { return $mockResult } -ParameterFilter { $task -eq "SendAsyncResult" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Get-AsyncResult { return $resultJsonString } -ParameterFilter { $task -eq $resultJsonString } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Test-Result { return $true} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                $result = Send-RequestWithRetries -RequestFactory { "RequestMessage" } -MaxRetries 3 -DelaySeconds 1

                $result | Should -Be $mockResult
            }

            It 'Asserts after the specified number of failed requests' {
                $mockClient = [HttpClientMock]::new()
                $mockResult = [HttpClientResultMock]::new("Some string")
                Mock Get-HttpClient { return $mockClient } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Get-AsyncResult { return $mockResult } -ParameterFilter { $task -eq "SendAsyncResult" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Get-AsyncResult { return $resultJsonString } -ParameterFilter { $task -eq $resultJsonString } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Test-Result { return $false} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Assert-Result { } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                $result = Send-RequestWithRetries -RequestFactory { "RequestMessage" } -MaxRetries 3 -DelaySeconds 0

                Should -Invoke Get-AsyncResult -Times 3
                Should -Invoke Assert-Result -Times 1
            }

            It 'Returns the request if it succeeds after retries' {
                $mockClient = [HttpClientMock]::new()
                $mockResult = [HttpClientResultMock]::new("Some string")
                Mock Get-HttpClient { return $mockClient } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Get-AsyncResult { return $mockResult } -ParameterFilter { $task -eq "SendAsyncResult" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Get-AsyncResult { return $resultJsonString } -ParameterFilter { $task -eq $resultJsonString } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                
                $script:callCount = 0
                Mock Test-Result { 
                    $script:callCount++
                    if ($script:callCount -lt 2) {
                        return $false
                    } else {
                        return $true
                    }
                } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

                Mock Assert-Result { } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                $result = Send-RequestWithRetries -RequestFactory { "RequestMessage" } -MaxRetries 3 -DelaySeconds 0

                Should -Not -Invoke Assert-Result
                $result | Should -Be $mockResult
            }
        }
    }
}