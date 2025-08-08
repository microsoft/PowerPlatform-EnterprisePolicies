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
                Assert-MockCalled Connect-AzAccount -Exactly 1 -Scope It
            }

            It 'Connects to Azure with a specific tenant' {
                $endpoint = [BAPEndpoint]::china
                $tenantId = "12345678-1234-1234-1234-123456789012"
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureChinaCloud" -and $Tenant -eq $tenantId } -Verifiable
                Mock Get-AzContext {}
                Connect-Azure -Endpoint $endpoint -TenantId $tenantId | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1 -Scope It
            }
        }
        Context 'Testing Connect-Azure' {
            It 'Connects to Azure with the correct environment' {
                $endpoint = [BAPEndpoint]::usgovhigh
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureUSGovernment" } -Verifiable
                Mock Get-AzContext {}
                Connect-Azure -Endpoint $endpoint | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1 -Scope It
            }
    
            It 'Connects to Azure with a specific tenant' {
                $endpoint = [BAPEndpoint]::china
                $tenantId = "12345678-1234-1234-1234-123456789012"
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureChinaCloud" -and $Tenant -eq $tenantId } -Verifiable
                Mock Get-AzContext {}
                Connect-Azure -Endpoint $endpoint -TenantId $tenantId | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1 -Scope It
            }
    
            It 'Does not Invoke Connect-AzAccount if already connected' {
                $endpoint = [BAPEndpoint]::prod
                Mock Get-AzContext { 
                    return @(
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "smth"; Tenants = @("12345678-1234-1234-1234-123456789012") } }
                    )
                }
                Mock Set-AzContext {}
                Mock Connect-AzAccount {} -Verifiable
                Connect-Azure -Endpoint $endpoint | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 0 -Scope It
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
                Assert-MockCalled Connect-AzAccount -Exactly 1 -Scope It
            }
        }
    }
    
}