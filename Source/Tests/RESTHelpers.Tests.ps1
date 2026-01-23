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
            BeforeEach {
                #This test could be flaky if other tests create HttpClient instances, ensure that doesn't happen
                $script:httpClient = $null
            }
            AfterAll {
                $script:httpClient = $null
            }
            It 'Returns an HttpClient with only the User-Agent header set' {
                $client = Get-HttpClient
                $client.DefaultRequestHeaders.UserAgent.Count | Should -Be 1
                $client.DefaultRequestHeaders.UserAgent[0].Product.Name | Should -Be "Microsoft.PowerPlatform.EnterprisePolicies"
                $client.DefaultRequestHeaders.UserAgent[0].Product.Version | Should -Be "1.0.0"
                $client.DefaultRequestHeaders.Count | Should -Be 1
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

            It 'Honors Retry-After header on 503 response' {
                $mockClient = [HttpClientMock]::new()
                $mock503Result = [HttpClientResultMock]::new("Service Unavailable", "text/plain", @{"Retry-After" = "2"})
                $mock503Result.StatusCode = [System.Net.HttpStatusCode]::ServiceUnavailable
                $mock503Result.IsSuccessStatusCode = $false
                $mockSuccessResult = [HttpClientResultMock]::new("Success")
                
                $script:callCount = 0
                Mock Get-HttpClient { return $mockClient } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Get-AsyncResult { 
                    $script:callCount++
                    if ($script:callCount -eq 1) {
                        return $mock503Result
                    } else {
                        return $mockSuccessResult
                    }
                } -ParameterFilter { $task -eq "SendAsyncResult" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                
                Mock Test-Result { param($Result) return $Result.IsSuccessStatusCode } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Start-Sleep { } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Write-Host { } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                
                $result = Send-RequestWithRetries -RequestFactory { "RequestMessage" } -MaxRetries 3 -DelaySeconds 1

                $result | Should -Be $mockSuccessResult
                Should -Invoke Start-Sleep -Times 1 -ParameterFilter { $Seconds -eq 2 } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            }

            It 'Honors Retry-After header on 429 response' {
                $mockClient = [HttpClientMock]::new()
                $mock429Result = [HttpClientResultMock]::new("Too Many Requests", "text/plain", @{"Retry-After" = (Get-Date).AddSeconds(10)})
                $mock429Result.StatusCode = 429
                $mock429Result.IsSuccessStatusCode = $false
                $mockSuccessResult = [HttpClientResultMock]::new("Success")
                
                $script:callCount = 0
                Mock Get-HttpClient { return $mockClient } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Get-AsyncResult { 
                    $script:callCount++
                    if ($script:callCount -eq 1) {
                        return $mock429Result
                    } else {
                        return $mockSuccessResult
                    }
                } -ParameterFilter { $task -eq "SendAsyncResult" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                
                Mock Test-Result { param($Result) return $Result.IsSuccessStatusCode } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Start-Sleep { } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Write-Host { } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                
                $result = Send-RequestWithRetries -RequestFactory { "RequestMessage" } -MaxRetries 3 -DelaySeconds 1

                $result | Should -Be $mockSuccessResult
                Should -Invoke Start-Sleep -Times 1 -ParameterFilter { $Seconds -gt 5 } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            }
        }

        Context 'Testing ConvertFrom-JsonToClass' {
            It 'Converts simple JSON to a class instance' {
                $json = '{"AzureRegion":"EastUS","EnvironmentId":"env-123","VnetId":"/subscriptions/sub-id/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet","SubnetName":"subnet1"}'
                $result = ConvertFrom-JsonToClass -Json $json -ClassType ([NetworkUsage])

                $result | Should -BeOfType [NetworkUsage]
                $result.AzureRegion | Should -Be "EastUS"
                $result.EnvironmentId | Should -Be "env-123"
                $result.VnetId | Should -Be "/subscriptions/sub-id/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet"
                $result.SubnetName | Should -Be "subnet1"
            }

            It 'Handles primitive types' {
                $json = '"test string"'
                $result = ConvertFrom-JsonToClass -Json $json -ClassType ([string])

                $result | Should -Be "test string"
                $result | Should -BeOfType [string]
            }

            It 'Handles value types' {
                $json = '42'
                $result = ConvertFrom-JsonToClass -Json $json -ClassType ([int])

                $result | Should -Be 42
                $result | Should -BeOfType [int]
            }

            It 'Handles array types' {
                $json = '[{"AzureRegion":"EastUS","SubnetName":"subnet1"},{"AzureRegion":"WestUS","SubnetName":"subnet2"}]'
                $result = ConvertFrom-JsonToClass -Json $json -ClassType ([NetworkUsage[]])

                $result | Should -HaveCount 2
                $result[0].AzureRegion | Should -Be "EastUS"
                $result[0].SubnetName | Should -Be "subnet1"
                $result[1].AzureRegion | Should -Be "WestUS"
                $result[1].SubnetName | Should -Be "subnet2"
            }

            It 'Handles nested class properties' {
                $json = '{"Id":"env123","EnvironmentId":"env-456","AzureRegion":"EastUS","NetworkUsageData":[{"TimeStamp":"2024-01-01","TotalIpUsage":50},{"TimeStamp":"2024-01-02","TotalIpUsage":75}]}'
                
                $result = ConvertFrom-JsonToClass -Json $json -ClassType ([EnvironmentNetworkUsageDocument])

                $result | Should -BeOfType ([EnvironmentNetworkUsageDocument])
                $result.Id | Should -Be "env123"
                $result.EnvironmentId | Should -Be "env-456"
                $result.AzureRegion | Should -Be "EastUS"
                $result.NetworkUsageData | Should -HaveCount 2
                $result.NetworkUsageData[0] | Should -BeOfType ([NetworkUsageData])
                $result.NetworkUsageData[0].TimeStamp | Should -Be "2024-01-01"
                $result.NetworkUsageData[0].TotalIpUsage | Should -Be 50
                $result.NetworkUsageData[1].TotalIpUsage | Should -Be 75
            }

            It 'Handles null or missing properties gracefully' {
                $json = '{"AzureRegion":"EastUS"}'
                $result = ConvertFrom-JsonToClass -Json $json -ClassType ([NetworkUsage])

                $result | Should -BeOfType [NetworkUsage]
                $result.AzureRegion | Should -Be "EastUS"
                $result.EnvironmentId | Should -BeNullOrEmpty
                $result.VnetId | Should -BeNullOrEmpty
            }

            It 'Handles null or missing properties that are other custom classes gracefully' {
                $json = '{"TCPConnectivity":false,"Certificate":null,"SSLWithoutCRL":null,"SSLWithCRL":null}'
                $result = ConvertFrom-JsonToClass -Json $json -ClassType ([TLSConnectivityInformation])

                $result | Should -BeOfType [TLSConnectivityInformation]
                $result.TCPConnectivity | Should -Be $false
                $result.Certificate | Should -Be $null
            }

            It 'Handles hashtable properties' {
                $json = '{"TimeStamp":"2024-01-01","TotalIpUsage":100,"IpAllocations":{"Key1":"Value1","Key2":"Value2"}}'
                $result = ConvertFrom-JsonToClass -Json $json -ClassType ([NetworkUsageData])

                $result | Should -BeOfType [NetworkUsageData]
                $result.TimeStamp | Should -Be "2024-01-01"
                $result.TotalIpUsage | Should -Be 100
                $result.IpAllocations | Should -BeOfType [hashtable]
                $result.IpAllocations["Key1"] | Should -Be "Value1"
                $result.IpAllocations["Key2"] | Should -Be "Value2"
            }

            It 'Handles empty arrays' {
                $json = '[]'
                $result = ConvertFrom-JsonToClass -Json $json -ClassType ([NetworkUsage[]])

                $result | Should -HaveCount 0
            }

            It 'Handles nullable types' {
                Add-Type -TypeDefinition @"
                    public class TestNullableClass {
                        public string Name { get; set; }
                        public int? OptionalNumber { get; set; }
                    }
"@ -ErrorAction SilentlyContinue

                $json = '{"Name":"Test","OptionalNumber":42}'
                $result = ConvertFrom-JsonToClass -Json $json -ClassType ([TestNullableClass])

                $result.Name | Should -Be "Test"
                $result.OptionalNumber | Should -Be 42
            }
        }

        Context 'Testing Get-UnderlyingType' {
            It 'Returns the underlying type for nullable types' {
                $nullableInt = [System.Nullable``1[System.Int32]]
                $result = Get-UnderlyingType $nullableInt

                $result | Should -Be ([int])
            }

            It 'Returns the same type for non-nullable types' {
                $result = Get-UnderlyingType ([string])

                $result | Should -Be ([string])
            }
        }

        Context 'Testing ConvertTo-Hashtable' {
            It 'Converts PSObject to hashtable' {
                $obj = [PSCustomObject]@{
                    Key1 = "Value1"
                    Key2 = "Value2"
                    Key3 = 123
                }
                $result = ConvertTo-Hashtable $obj

                $result | Should -BeOfType [hashtable]
                $result["Key1"] | Should -Be "Value1"
                $result["Key2"] | Should -Be "Value2"
                $result["Key3"] | Should -Be 123
            }

            It 'Returns hashtable if input is already a hashtable' {
                $hash = @{
                    Key1 = "Value1"
                    Key2 = "Value2"
                }
                $result = ConvertTo-Hashtable $hash

                $result | Should -BeOfType [hashtable]
                $result["Key1"] | Should -Be "Value1"
                $result["Key2"] | Should -Be "Value2"
            }

            It 'Handles empty objects' {
                $obj = [PSCustomObject]@{}
                $result = ConvertTo-Hashtable $obj

                $result | Should -BeOfType [hashtable]
                $result.Count | Should -Be 0
            }
        }
    }
}