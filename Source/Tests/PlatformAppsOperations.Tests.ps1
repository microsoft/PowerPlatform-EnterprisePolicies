[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery {
    . $PSScriptRoot\Shared.ps1 -Module
}

InModuleScope 'Microsoft.PowerPlatform.EnterprisePolicies' {
    Describe 'PlatformAppsData CMK operations' {
        BeforeAll {
            $script:policyArmId = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.PowerPlatform/enterprisePolicies/test-cmk"
            $script:policySystemId = "/regions/unitedstates/providers/Microsoft.PowerPlatform/enterprisePolicies/00000000-0000-0000-0000-000000000001"

            Mock Get-PPEndpointUrl { return "https://api.bap.microsoft.com/" }
            Mock Get-PPAccessToken { return ConvertTo-SecureString "mockToken" -AsPlainText -Force }
            Mock Get-AsyncResult { return $Task }
            Mock Set-SubscriptionContext {}
            Mock Write-Host {}
        }

        BeforeEach {
            $script:requests = @()
            $script:statusResponse = [HttpClientResultMock]::new((@{
                enrollmentState = "Enrolled"
                enterprisePolicies = @{ CustomerManagedKeys = @{ id = $script:policyArmId } }
            } | ConvertTo-Json -Depth 4))
            $script:operationResponse = [HttpClientResultMock]::new("")
            $script:operationResponse.StatusCode = 202
            Mock Get-EnterprisePolicy {
                return [PSCustomObject]@{
                    Kind = "Encryption"
                    Properties = @{ systemId = $script:policySystemId }
                }
            }
            Mock Send-RequestWithRetries {
                $request = & $RequestFactory
                $script:requests += $request
                if ($request.Method.Method -eq "GET") {
                    return $script:statusResponse
                }
                return $script:operationResponse
            }
        }

        AfterEach {
            foreach ($request in $script:requests) {
                $request.Dispose()
            }
        }

        It 'Uses the PlatformApps status and Encryption/<Operation> routes and sends only the system ID' -TestCases @(
            @{ Operation = 'link' }
            @{ Operation = 'unlink' }
        ) {
            param($Operation)

            Set-PlatformAppsDataCMK -PolicyArmId $script:policyArmId -Operation $Operation -Endpoint prod | Should -Be $true

            $script:requests.Count | Should -Be 2
            $script:requests[0].Method.Method | Should -Be "GET"
            $script:requests[0].RequestUri.AbsoluteUri | Should -Be "https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/platformapps/status?api-version=2024-05-01"
            $script:requests[1].Method.Method | Should -Be "POST"
            $script:requests[1].RequestUri.AbsoluteUri | Should -Be "https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/platformapps/enterprisePolicies/Encryption/${Operation}?api-version=2024-05-01"
            $body = $script:requests[1].Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
            $body.SystemId | Should -Be $script:policySystemId
            @($body.PSObject.Properties).Count | Should -Be 1
        }

        It 'Uses the selected endpoint and tenant for both requests' {
            Mock Get-PPEndpointUrl { return "https://high.api.bap.microsoft.us/" } -ParameterFilter { $Endpoint -eq 'usgovhigh' }
            $tenantId = "00000000-0000-0000-0000-000000000002"

            Set-PlatformAppsDataCMK -PolicyArmId $script:policyArmId -Operation link -Endpoint usgovhigh -TenantId $tenantId | Should -Be $true

            $script:requests[0].RequestUri.Host | Should -Be "high.api.bap.microsoft.us"
            $script:requests[1].RequestUri.Host | Should -Be "high.api.bap.microsoft.us"
            Should -Invoke Get-PPAccessToken -Times 2 -Exactly -ParameterFilter { $Endpoint -eq 'usgovhigh' -and $TenantId -eq "00000000-0000-0000-0000-000000000002" }
        }

        It 'Rejects missing or incomplete enrollment before retrieving or mutating a policy: <StatusContent>' -TestCases @(
            @{ StatusContent = 'null' }
            @{ StatusContent = '{}' }
            @{ StatusContent = '{"enrollmentState":"Enrolling"}' }
        ) {
            param($StatusContent)
            $script:statusResponse = [HttpClientResultMock]::new($StatusContent)

            { Set-PlatformAppsDataCMK -PolicyArmId $script:policyArmId -Operation link -Endpoint prod } | Should -Throw "*not enrolled*"

            $script:requests.Count | Should -Be 1
            Should -Invoke Get-EnterprisePolicy -Times 0
        }

        It 'Reports status retrieval failures with the service error' {
            $script:statusResponse = [HttpClientResultMock]::new('{"error":"access denied"}')
            $script:statusResponse.IsSuccessStatusCode = $false
            $script:statusResponse.StatusCode = 403

            { Set-PlatformAppsDataCMK -PolicyArmId $script:policyArmId -Operation link -Endpoint prod } | Should -Throw "*403*access denied*"

            $script:requests.Count | Should -Be 1
            Should -Invoke Get-EnterprisePolicy -Times 0
        }

        It 'Refuses to unlink when no CMK policy is linked' {
            $script:statusResponse = [HttpClientResultMock]::new('{"enrollmentState":"Enrolled","enterprisePolicies":{}}')

            { Set-PlatformAppsDataCMK -PolicyArmId $script:policyArmId -Operation unlink -Endpoint prod } | Should -Throw "*No CMK enterprise policy is linked*"

            $script:requests.Count | Should -Be 1
        }

        It 'Refuses to unlink a policy other than the supplied policy' {
            $otherPolicyArmId = $script:policyArmId.Replace("test-cmk", "another-cmk")

            { Set-PlatformAppsDataCMK -PolicyArmId $otherPolicyArmId -Operation unlink -Endpoint prod } | Should -Throw "*does not match*"

            $script:requests.Count | Should -Be 1
            Should -Invoke Get-EnterprisePolicy -Times 0
        }

        It 'Matches linked ARM IDs case-insensitively' {
            Set-PlatformAppsDataCMK -PolicyArmId $script:policyArmId.ToUpperInvariant() -Operation unlink -Endpoint prod | Should -Be $true
        }

        It 'Preserves legacy linking behavior when a different policy is already linked' {
            $newPolicyArmId = $script:policyArmId.Replace("test-cmk", "new-cmk")

            Set-PlatformAppsDataCMK -PolicyArmId $newPolicyArmId -Operation link -Endpoint prod | Should -Be $true

            $script:requests.Count | Should -Be 2
        }

        It 'Rejects a missing policy before issuing a mutation' {
            Mock Get-EnterprisePolicy { return $null }

            { Set-PlatformAppsDataCMK -PolicyArmId $script:policyArmId -Operation link -Endpoint prod } | Should -Throw "*Failed to retrieve enterprise policy*"

            $script:requests.Count | Should -Be 1
        }

        It 'Rejects policies that are not Encryption policies' {
            Mock Get-EnterprisePolicy { return [PSCustomObject]@{ Kind = 'Identity' } }

            { Set-PlatformAppsDataCMK -PolicyArmId $script:policyArmId -Operation link -Endpoint prod } | Should -Throw "*not a CMK*"

            $script:requests.Count | Should -Be 1
        }

        It 'Rejects a policy without a provisioned system ID' {
            Mock Get-EnterprisePolicy { return [PSCustomObject]@{ Kind = 'Encryption'; Properties = @{} } }

            { Set-PlatformAppsDataCMK -PolicyArmId $script:policyArmId -Operation link -Endpoint prod } | Should -Throw "*does not have a systemId*"

            $script:requests.Count | Should -Be 1
        }

        It 'Requires HTTP 202 rather than treating another response as initiation: <StatusCode>' -TestCases @(
            @{ StatusCode = 200 }
            @{ StatusCode = 400 }
        ) {
            param($StatusCode)
            $script:operationResponse = [HttpClientResultMock]::new('{"error":"not accepted"}')
            $script:operationResponse.StatusCode = $StatusCode

            { Set-PlatformAppsDataCMK -PolicyArmId $script:policyArmId -Operation link -Endpoint prod } | Should -Throw "*$StatusCode*not accepted*"
        }
    }
}
