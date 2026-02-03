[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'New-AuthorizationRoleAssignment Tests' {
    BeforeAll {
        $script:testClientId = "00000000-0000-0000-0000-000000789012"
        $script:testTenantId = "12345678-1234-1234-1234-123456789012"
        $script:testEnvironmentId = "00000000-0000-0000-0000-000000000001"
        $script:testEnvironmentGroupId = "00000000-0000-0000-0000-000000000002"
        $script:testPrincipalObjectId = "00000000-0000-0000-0000-000000000003"
        $script:testToken = ConvertTo-SecureString -String "test-token" -AsPlainText -Force

        $script:mockRoleAssignmentResponse = @{
            id = "role-assignment-id"
            principalObjectId = $script:testPrincipalObjectId
            principalType = "User"
            scope = "/tenants/$($script:testTenantId)/roleAssignments"
            roleDefinitionId = "c886ad2e-27f7-4874-8381-5849b8d8a090"
        }

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Tenant-scoped role assignment' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-RoleAssignment { return $script:mockRoleAssignmentResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create a tenant-scoped role assignment' {
            $result = New-AuthorizationRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role Reader -TenantId $script:testTenantId

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should call New-AuthorizationServiceMsalClient' {
            New-AuthorizationRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role Reader -TenantId $script:testTenantId

            Should -Invoke New-AuthorizationServiceMsalClient -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should call New-RoleAssignment' {
            New-AuthorizationRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role Reader -TenantId $script:testTenantId

            Should -Invoke New-RoleAssignment -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Environment-scoped role assignment' {
        BeforeAll {
            $script:mockEnvironmentRoleAssignmentResponse = @{
                id = "role-assignment-id"
                principalObjectId = $script:testPrincipalObjectId
                principalType = "Group"
                scope = "/tenants/$($script:testTenantId)/environments/$($script:testEnvironmentId)/roleAssignments"
                roleDefinitionId = "ff954d61-a89a-4fbe-ace9-01c367b89f87"
            }

            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-RoleAssignment { return $script:mockEnvironmentRoleAssignmentResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create an environment-scoped role assignment' {
            $result = New-AuthorizationRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType Group -Role Contributor -TenantId $script:testTenantId -EnvironmentId $script:testEnvironmentId

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Environment group-scoped role assignment' {
        BeforeAll {
            $script:mockEnvGroupRoleAssignmentResponse = @{
                id = "role-assignment-id"
                principalObjectId = $script:testPrincipalObjectId
                principalType = "ApplicationUser"
                scope = "/tenants/$($script:testTenantId)/environmentGroups/$($script:testEnvironmentGroupId)/roleAssignments"
                roleDefinitionId = "0cb07c69-1631-4725-ab35-e59e001c51ea"
            }

            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-RoleAssignment { return $script:mockEnvGroupRoleAssignmentResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create an environment group-scoped role assignment' {
            $result = New-AuthorizationRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType ApplicationUser -Role Owner -TenantId $script:testTenantId -EnvironmentGroupId $script:testEnvironmentGroupId

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Role mapping' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-RoleAssignment { return $script:mockRoleAssignmentResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should accept Administrator role' {
            { New-AuthorizationRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role Administrator -TenantId $script:testTenantId } | Should -Not -Throw
        }

        It 'Should accept Reader role' {
            { New-AuthorizationRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role Reader -TenantId $script:testTenantId } | Should -Not -Throw
        }

        It 'Should accept Contributor role' {
            { New-AuthorizationRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role Contributor -TenantId $script:testTenantId } | Should -Not -Throw
        }

        It 'Should accept Owner role' {
            { New-AuthorizationRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role Owner -TenantId $script:testTenantId } | Should -Not -Throw
        }
    }

    Context 'Error handling' {
        It 'Should throw when New-AuthorizationServiceMsalClient fails' {
            Mock New-AuthorizationServiceMsalClient { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-AuthorizationRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role Reader -TenantId $script:testTenantId } | Should -Throw "*Failed to connect to Authorization Service*"
        }
    }
}
