[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-SubnetHistoricalUsage Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
        $secureString = (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force)

        $script:testTenantId = "e9651b85-8b04-482f-a1e2-3e03421b4398"
        $script:testRegion = "EastUs"
        $script:testSystemIdGuid = "00000000-0000-0000-0000-000000000002"
        $script:testPolicySystemIdPath = "/regions/unitedstates/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:testSystemIdGuid"
        $script:testEnvironmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
        $script:testPolicyArmId = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.PowerPlatform/enterprisePolicies/test-policy"

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyArmId
            Kind = "NetworkInjection"
            Location = "unitedstates"
            Properties = @{
                systemId = $script:testPolicySystemIdPath
            }
        }

        $script:mockEnvironmentWithPolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            properties = @{
                enterprisePolicies = @{
                    VNets = @{
                        id = $script:testPolicyArmId
                    }
                }
            }
        }

        $script:mockEnvironmentWithoutPolicy = [PSCustomObject]@{
            name = $script:testEnvironmentId
            properties = @{
                enterprisePolicies = $null
            }
        }

        $resultClass = [SubnetUsageDocument]::new()
        $resultClass.AzureRegion = $script:testRegion
        $resultClass.SubnetName = "default"
        $script:expectedResult = $resultClass
        $script:resultJsonString = ($resultClass | ConvertTo-Json)
        $script:mockHttpResult = [HttpClientResultMock]::new($script:resultJsonString)
        $script:httpClientMock = [HttpClientMock]::new()

        Mock Get-PPAPIAccessToken { return $secureString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {}
        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-AzContext {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

        Mock Get-HttpClient { return $script:httpClientMock } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Get-AsyncResult -ParameterFilter { $task -eq "SendAsyncResult" } { return $script:mockHttpResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Get-AsyncResult -ParameterFilter { $task -ne "SendAsyncResult" } { return $script:resultJsonString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'BySystemId' {
        It 'Sends the supplied SystemId GUID in the API query and returns a SubnetUsageDocument' {
            Mock New-HomeTenantRouteRequest { return "request" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Get-SubnetHistoricalUsage `
                -SystemId $script:testSystemIdGuid `
                -TenantId $script:testTenantId `
                -Region $script:testRegion

            $result.AzureRegion | Should -Be $script:testRegion
            $result.SubnetName | Should -Be "default"
            Should -Invoke New-HomeTenantRouteRequest -Times 1 -ParameterFilter {
                $Query -like "*enterprisePolicyId=$($script:testSystemIdGuid)*"
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'ByEnterprisePolicyId' {
        It 'Resolves SystemId GUID from ARM policy and sends it in the API query' {
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-HomeTenantRouteRequest { return "request" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Get-SubnetHistoricalUsage `
                -EnterprisePolicyId $script:testPolicyArmId `
                -TenantId $script:testTenantId `
                -Region $script:testRegion

            $result.AzureRegion | Should -Be $script:testRegion
            Should -Invoke New-HomeTenantRouteRequest -Times 1 -ParameterFilter {
                $Query -like "*enterprisePolicyId=$($script:testSystemIdGuid)*"
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'ByEnvironmentId' {
        It 'Resolves linked policy via BAP and sends its SystemId GUID in the API query' {
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-HomeTenantRouteRequest { return "request" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Get-SubnetHistoricalUsage `
                -EnvironmentId $script:testEnvironmentId `
                -TenantId $script:testTenantId `
                -Region $script:testRegion

            $result.AzureRegion | Should -Be $script:testRegion
            Should -Invoke New-HomeTenantRouteRequest -Times 1 -ParameterFilter {
                $Query -like "*enterprisePolicyId=$($script:testSystemIdGuid)*"
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Throws when the environment has no linked Subnet Injection policy' {
            Mock Get-PPEnvironment { return $script:mockEnvironmentWithoutPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-SubnetHistoricalUsage `
                -EnvironmentId $script:testEnvironmentId `
                -TenantId $script:testTenantId `
                -Region $script:testRegion } | Should -Throw "*No Subnet Injection Enterprise Policy is linked*"
        }
    }

    Context 'Peak usage thresholds' {
        BeforeAll {
            Mock New-HomeTenantRouteRequest { return "request" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Write-Warning { } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Write-Error { } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Emits nothing when peak usage is below 75%' {
            $json = @{ SubnetSize = 32; NetworkUsageDataByWorkload = @(@{ TotalIpUsage = 23 }) } | ConvertTo-Json -Depth 10  # 71.9%
            Mock Get-AsyncResult -ParameterFilter { $task -ne "SendAsyncResult" } { return $json } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $null = Get-SubnetHistoricalUsage -SystemId $script:testSystemIdGuid -TenantId $script:testTenantId -Region $script:testRegion

            Should -Invoke Write-Warning -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Should -Invoke Write-Error -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Emits Write-Warning at the 75% threshold' {
            $json = @{ SubnetSize = 32; NetworkUsageDataByWorkload = @(@{ TotalIpUsage = 24 }) } | ConvertTo-Json -Depth 10  # 75%
            Mock Get-AsyncResult -ParameterFilter { $task -ne "SendAsyncResult" } { return $json } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $null = Get-SubnetHistoricalUsage -SystemId $script:testSystemIdGuid -TenantId $script:testTenantId -Region $script:testRegion

            Should -Invoke Write-Warning -Times 1 -ParameterFilter { $Message -like '*Usage is high*' } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Should -Invoke Write-Error -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Emits Write-Error close-to-full at 90%' {
            $json = @{ SubnetSize = 32; NetworkUsageDataByWorkload = @(@{ TotalIpUsage = 29 }) } | ConvertTo-Json -Depth 10  # 90.6%
            Mock Get-AsyncResult -ParameterFilter { $task -ne "SendAsyncResult" } { return $json } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $null = Get-SubnetHistoricalUsage -SystemId $script:testSystemIdGuid -TenantId $script:testTenantId -Region $script:testRegion

            Should -Invoke Write-Error -Times 1 -ParameterFilter { $Message -like '*close to full*' } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Should -Invoke Write-Warning -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Emits Write-Error subnet-is-full at 100%' {
            $json = @{ SubnetSize = 32; NetworkUsageDataByWorkload = @(@{ TotalIpUsage = 32 }) } | ConvertTo-Json -Depth 10  # 100%
            Mock Get-AsyncResult -ParameterFilter { $task -ne "SendAsyncResult" } { return $json } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $null = Get-SubnetHistoricalUsage -SystemId $script:testSystemIdGuid -TenantId $script:testTenantId -Region $script:testRegion

            Should -Invoke Write-Error -Times 1 -ParameterFilter { $Message -like '*The subnet is full*' } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }
}
