[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-RoleDefinitions Tests' {
    BeforeAll {
        $script:mockRoleDefinitions = @(
            @{
                roleDefinitionId = "11111111-1111-1111-1111-111111111111"
                roleDefinitionName = "Power Platform Reader"
                permissions = @(@{ actions = @("read") })
            },
            @{
                roleDefinitionId = "22222222-2222-2222-2222-222222222222"
                roleDefinitionName = "Power Platform Role Based Access Control Administrator"
                permissions = @(@{ actions = @("read", "write", "delete") })
            }
        )

        $script:mockApiResponse = @{
            value = $script:mockRoleDefinitions
        } | ConvertTo-Json -Depth 10

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Fetching role definitions from API' {
        BeforeAll {
            Mock Get-CachedRoleDefinitions { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-CachedRoleDefinitions {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-APIResourceUrl { return "https://api.powerplatform.com/" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AuthorizationServiceToken { return "test-token" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $mockResultContent = [System.Net.Http.StringContent]::new($script:mockApiResponse, [System.Text.Encoding]::UTF8, "application/json")
            $mockResult = New-Object -TypeName System.Net.Http.HttpResponseMessage -ArgumentList @([System.Net.HttpStatusCode]::OK)
            $mockResult.Content = $mockResultContent

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return role definitions from the API' {
            $result = InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                Get-RoleDefinitions -Endpoint Prod
            }

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }

        It 'Should store results in the shared cache' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                Get-RoleDefinitions -Endpoint Prod
            }

            Should -Invoke Set-CachedRoleDefinitions -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Cache behavior' {
        BeforeAll {
            Mock Get-CachedRoleDefinitions { return $script:mockRoleDefinitions } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-CachedRoleDefinitions {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Send-RequestWithRetries {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return cached data when cache is fresh' {
            $result = InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                Get-RoleDefinitions -Endpoint Prod
            }

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Send-RequestWithRetries -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should call API when RefreshRoles is specified' {
            $mockResultContent = [System.Net.Http.StringContent]::new($script:mockApiResponse, [System.Text.Encoding]::UTF8, "application/json")
            $mockResult = New-Object -TypeName System.Net.Http.HttpResponseMessage -ArgumentList @([System.Net.HttpStatusCode]::OK)
            $mockResult.Content = $mockResultContent

            Mock Get-APIResourceUrl { return "https://api.powerplatform.com/" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AuthorizationServiceToken { return "test-token" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                Get-RoleDefinitions -Endpoint Prod -RefreshRoles
            }

            Should -Invoke Send-RequestWithRetries -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }
}

Describe 'Resolve-RoleDefinitionId Tests' {
    BeforeAll {
        $script:mockRoleDefinitions = @(
            @{
                roleDefinitionId = "11111111-1111-1111-1111-111111111111"
                roleDefinitionName = "Power Platform Reader"
            },
            @{
                roleDefinitionId = "22222222-2222-2222-2222-222222222222"
                roleDefinitionName = "Power Platform Role Based Access Control Administrator"
            }
        )

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Resolving role names' {
        BeforeAll {
            Mock Get-RoleDefinitions { return $script:mockRoleDefinitions } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return the correct role definition ID for a valid role name' {
            $result = InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                Resolve-RoleDefinitionId -RoleName "Power Platform Reader"
            }

            $result | Should -Be "11111111-1111-1111-1111-111111111111"
        }

        It 'Should throw for an invalid role name' {
            { InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                Resolve-RoleDefinitionId -RoleName "NonExistentRole"
            } } | Should -Throw "*NonExistentRole*not found*"
        }
    }
}
