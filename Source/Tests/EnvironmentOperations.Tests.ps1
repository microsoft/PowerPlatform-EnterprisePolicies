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

        Context 'Set-EnvironmentEnterprisePolicy' {
            BeforeAll {
                $script:testPolicySystemId = "/regions/unitedstates/providers/Microsoft.PowerPlatform/enterprisePolicies/00000000-0000-0000-0000-000000000002"

                $mockClient = [HttpClientMock]::new()
                $mock202Result = [HttpClientResultMock]::new('{"id":"operation-1"}', "application/json")
                $mock202Result.StatusCode = 202

                Mock Get-HttpClient { return $mockClient }
                Mock Get-BAPEndpointUrl { return "https://api.bap.microsoft.com/" }
                Mock Get-BAPAccessToken { return (ConvertTo-SecureString "mock-token" -AsPlainText -Force) }
                Mock Send-RequestWithRetries { return $mock202Result }
            }

            It 'Should call the link API with correct URL' {
                Set-EnvironmentEnterprisePolicy `
                    -EnvironmentId $script:testEnvironmentId `
                    -PolicyType ([PolicyType]::NetworkInjection) `
                    -PolicySystemId $script:testPolicySystemId `
                    -Operation ([LinkOperation]::link) `
                    -Endpoint ([BAPEndpoint]::Prod)

                Should -Invoke Send-RequestWithRetries -Times 1
            }

            It 'Should return 202 response for successful initiation' {
                $result = Set-EnvironmentEnterprisePolicy `
                    -EnvironmentId $script:testEnvironmentId `
                    -PolicyType ([PolicyType]::NetworkInjection) `
                    -PolicySystemId $script:testPolicySystemId `
                    -Operation ([LinkOperation]::link) `
                    -Endpoint ([BAPEndpoint]::Prod)

                $result.StatusCode | Should -Be 202
            }
        }

        Context 'Wait-EnterprisePolicyOperation' {
            BeforeAll {
                $mockClient = [HttpClientMock]::new()
                Mock Get-HttpClient { return $mockClient }
                Mock Get-BAPAccessToken { return (ConvertTo-SecureString "mock-token" -AsPlainText -Force) }
            }

            It 'Should return operation result when succeeded' {
                $mockSuccessResult = [HttpClientResultMock]::new('{"id":"op-1","state":{"id":"Succeeded"}}', "application/json")
                Mock Send-RequestWithRetries { return $mockSuccessResult }
                Mock Get-AsyncResult { return '{"id":"op-1","state":{"id":"Succeeded"}}' }

                $result = Wait-EnterprisePolicyOperation `
                    -OperationUrl "https://api.bap.microsoft.com/operations/op-1" `
                    -Endpoint ([BAPEndpoint]::Prod) `
                    -TimeoutSeconds 60

                $result.state.id | Should -Be "Succeeded"
            }

            It 'Should throw when operation fails' {
                $mockFailedResult = [HttpClientResultMock]::new('{"id":"op-1","state":{"id":"Failed"},"error":{"message":"Test error"}}', "application/json")
                Mock Send-RequestWithRetries { return $mockFailedResult }
                Mock Get-AsyncResult { return '{"id":"op-1","state":{"id":"Failed"},"error":{"message":"Test error"}}' }

                { Wait-EnterprisePolicyOperation `
                    -OperationUrl "https://api.bap.microsoft.com/operations/op-1" `
                    -Endpoint ([BAPEndpoint]::Prod) `
                    -TimeoutSeconds 60 } | Should -Throw "*operation failed*"
            }
        }
    }
}
