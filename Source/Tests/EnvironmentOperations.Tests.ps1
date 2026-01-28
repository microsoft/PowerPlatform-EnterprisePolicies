[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1 -Module
}

Describe 'EnvironmentOperations Tests' {
    InModuleScope 'Microsoft.PowerPlatform.EnterprisePolicies'{
        BeforeAll {
            $script:testEnvironmentId = "00000000-0000-0000-0000-000000000001"
            $script:testTenantId = "87654321-4321-4321-4321-210987654321"

            $script:mockEnvironment = [PSCustomObject]@{
                name = $script:testEnvironmentId
                properties = @{
                    displayName = "Test Environment"
                    enterprisePolicies = @{
                        VNets = @{
                            id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.PowerPlatform/enterprisePolicies/test-policy"
                        }
                    }
                }
            }

            Mock Write-Verbose {}
        }

        Context 'Get-BAPEnvironment' {
            BeforeAll {
                $mockClient = [HttpClientMock]::new()
                $mockSuccessResult = [HttpClientResultMock]::new(($script:mockEnvironment | ConvertTo-Json -Depth 10), "application/json")

                Mock Get-HttpClient { return $mockClient }
                Mock Get-BAPEndpointUrl { return "https://api.powerplatform.com/" }
                Mock Get-BAPAccessToken { return (ConvertTo-SecureString "mock-token" -AsPlainText -Force) }
                Mock Send-RequestWithRetries { return $mockSuccessResult }
                Mock Get-AsyncResult {
                    param($task)
                    if ($task -eq "SendAsyncResult") { return $mockSuccessResult }
                    return ($script:mockEnvironment | ConvertTo-Json -Depth 10)
                }
            }

            It 'Should retrieve environment successfully' {
                $result = Get-BAPEnvironment -EnvironmentId $script:testEnvironmentId -Endpoint ([BAPEndpoint]::Prod)

                $result | Should -Not -BeNullOrEmpty
                $result.name | Should -Be $script:testEnvironmentId
            }

            It 'Should call Get-BAPEndpointUrl with correct endpoint' {
                Get-BAPEnvironment -EnvironmentId $script:testEnvironmentId -Endpoint ([BAPEndpoint]::usgovhigh)

                Should -Invoke Get-BAPEndpointUrl -Times 1 -ParameterFilter { $Endpoint -eq [BAPEndpoint]::usgovhigh }
            }

            It 'Should throw when API call fails' {
                $mockErrorResult = [HttpClientResultMock]::new("Not Found", "text/plain")
                $mockErrorResult.IsSuccessStatusCode = $false
                $mockErrorResult.StatusCode = 404
                Mock Send-RequestWithRetries { return $mockErrorResult }
                Mock Get-AsyncResult { return "Environment not found" } -ParameterFilter { $task -ne "SendAsyncResult" }

                { Get-BAPEnvironment -EnvironmentId "invalid-id" -Endpoint ([BAPEndpoint]::Prod) } | Should -Throw "*Failed to retrieve environment*"
            }
        }
    }
}
