BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1 -Module
}

Describe 'AuthenticationOperations Tests' {
    InModuleScope 'EnterprisePolicies' {
        BeforeAll{
            Mock Write-Host {}
        }
        Context 'Testing Connect-Azure' {
            It 'Connects to Azure with the correct environment' {
                $endpoint = [BAPEndpoint]::usgovhigh
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureUSGovernment" } -Verifiable
                Mock Get-AzContext {}
                Connect-Azure -Endpoint $endpoint | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1
            }

            It 'Prefers a context with home tenant if multiple context are available' {
                $endpoint = [BAPEndpoint]::prod
                $tenantId = "12345678-1234-1234-1234-123456789012"
                Mock Get-AzContext { 
                    return @(
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "smth"; Tenants = @("87654321-4321-4321-4321-210987654321") }; Tenant = @{ TenantCategory = ""; Id = $tenantId } },
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "smth2"; Tenants = @($tenantId) }; Tenant = @{ TenantCategory = "Home"; Id = $tenantId } }
                    )
                }
                Mock Set-AzContext {}
                Connect-Azure -Endpoint $endpoint -TenantId $tenantId | Should -Be $true
                Assert-MockCalled Set-AzContext -Exactly 1
            }
    
            It 'Connects to Azure with a specific tenant' {
                $endpoint = [BAPEndpoint]::china
                $tenantId = "12345678-1234-1234-1234-123456789012"
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureChinaCloud" -and $Tenant -eq $tenantId } -Verifiable
                Mock Get-AzContext {}
                Connect-Azure -Endpoint $endpoint -TenantId $tenantId | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1
            }
    
            It 'Invokes Connect-AzAccount if tenant does not match' {
                $endpoint = [BAPEndpoint]::prod
                $tenantId = "12345678-1234-1234-1234-123456789012"
                Mock Get-AzContext { 
                    return @(
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "smth"; Tenants = @("87654321-4321-4321-4321-210987654321") } }
                    )
                }
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureCloud" -and $Tenant -eq $tenantId } -Verifiable
                Connect-Azure -Endpoint $endpoint -TenantId $tenantId | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1
            }

            It 'Forces a login in with Force switch' {
                $endpoint = [BAPEndpoint]::prod
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureCloud" } -Verifiable
                Mock Get-AzContext {
                    return @(
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "smth"; Tenants = @("87654321-4321-4321-4321-210987654321") } }
                    )
                }
                Connect-Azure -Endpoint $endpoint -Force | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1
            }

            It 'Forces a login if auth scope is provided' {
                $endpoint = [BAPEndpoint]::prod
                $authScope = "https://management.azure.com/.default"
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureCloud" } -Verifiable
                Mock Get-AzContext {
                    return @(
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "smth"; Tenants = @("87654321-4321-4321-4321-210987654321") } }
                    )
                }
                Connect-Azure -Endpoint $endpoint -AuthScope $authScope | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1
            }

            It 'Forces a login if no context is found' {
                $endpoint = [BAPEndpoint]::prod
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureCloud" } -Verifiable
                Mock Get-AzContext { return $null }
                Connect-Azure -Endpoint $endpoint | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1
            }

            It 'Forces a login if no context is found and auth scope is provided and force is set' {
                $endpoint = [BAPEndpoint]::prod
                $authScope = "https://management.azure.com/.default"
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureCloud" } -Verifiable
                Mock Get-AzContext { return $null }
                Connect-Azure -Endpoint $endpoint -AuthScope $authScope -Force | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1
            }
        }
    }
}