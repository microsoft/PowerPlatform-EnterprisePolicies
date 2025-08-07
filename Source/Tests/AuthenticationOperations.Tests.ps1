BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1 -Module
}

Describe 'AuthenticationOperations Tests' {
    BeforeAll{
        Mock Write-Host {} -ModuleName "AuthenticationOperations"
    }
    Context 'Testing Connect-Azure' {
        It 'Connects to Azure with the correct environment' {
            $endpoint = [BAPEndpoint]::usgovhigh
            Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureUSGovernment" } -ModuleName "AuthenticationOperations" -Verifiable
            Mock Get-AzContext {}
            Connect-Azure -Endpoint $endpoint | Should -Be $true
            Assert-MockCalled Connect-AzAccount -Exactly 1 -Scope It -ModuleName "AuthenticationOperations"
        }

        It 'Connects to Azure with a specific tenant' {
            $endpoint = [BAPEndpoint]::china
            $tenantId = "12345678-1234-1234-1234-123456789012"
            Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureChinaCloud" -and $Tenant -eq $tenantId } -ModuleName "AuthenticationOperations" -Verifiable
            Mock Get-AzContext {}
            Connect-Azure -Endpoint $endpoint -TenantId $tenantId | Should -Be $true
            Assert-MockCalled Connect-AzAccount -Exactly 1 -Scope It -ModuleName "AuthenticationOperations"
        }

        It 'Does not Invoke Connect-AzAccount if already connected' {
            $endpoint = [BAPEndpoint]::prod
            Mock Get-AzContext { 
                return @(
                    [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "smth"; Tenants = @("12345678-1234-1234-1234-123456789012") } }
                )
            } -ModuleName "AuthenticationOperations"
            Mock Set-AzContext {} -ModuleName "AuthenticationOperations"
            Mock Connect-AzAccount {} -ModuleName "AuthenticationOperations" -Verifiable
            Connect-Azure -Endpoint $endpoint | Should -Be $true
            Assert-MockCalled Connect-AzAccount -Exactly 0 -Scope It -ModuleName "AuthenticationOperations"
        }

        It 'Invokes Connect-AzAccount if tenant does not match' {
            $endpoint = [BAPEndpoint]::prod
            $tenantId = "12345678-1234-1234-1234-123456789012"
            Mock Get-AzContext { 
                return @(
                    [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "smth"; Tenants = @("87654321-4321-4321-4321-210987654321") } }
                )
            } -ModuleName "AuthenticationOperations"
            Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureCloud" -and $Tenant -eq $tenantId } -ModuleName "AuthenticationOperations" -Verifiable
            Connect-Azure -Endpoint $endpoint -TenantId $tenantId | Should -Be $true
            Assert-MockCalled Connect-AzAccount -Exactly 1 -Scope It -ModuleName "AuthenticationOperations"
        }
    }
}