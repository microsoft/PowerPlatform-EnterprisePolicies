[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'New-RBACRoleAssignment Tests' {
    BeforeAll {
        $script:testClientId = "00000000-0000-0000-0000-000000789012"
        $script:testTenantId = "12345678-1234-1234-1234-123456789012"
        $script:testEnvironmentId = "00000000-0000-0000-0000-000000000001"
        $script:testEnvironmentGroupId = "00000000-0000-0000-0000-000000000002"
        $script:testPrincipalObjectId = "00000000-0000-0000-0000-000000000003"
        $script:testRoleName = "Power Platform Reader"
        $script:testRoleDefinitionId = "c886ad2e-27f7-4874-8381-5849b8d8a090"

        $script:mockRoleAssignmentResponse = @{
            id = "role-assignment-id"
            principalObjectId = $script:testPrincipalObjectId
            principalType = "User"
            scope = "/tenants/$($script:testTenantId)/roleAssignments"
            roleDefinitionId = $script:testRoleDefinitionId
        }

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Tenant-scoped role assignment' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Resolve-RoleDefinitionId { return $script:testRoleDefinitionId } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-RoleAssignment { return $script:mockRoleAssignmentResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create a tenant-scoped role assignment' {
            $result = New-RBACRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role $script:testRoleName -TenantId $script:testTenantId

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should call Resolve-RoleDefinitionId with the role name' {
            New-RBACRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role $script:testRoleName -TenantId $script:testTenantId

            Should -Invoke Resolve-RoleDefinitionId -Times 1 -ParameterFilter {
                $RoleName -eq $script:testRoleName
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should call New-RoleAssignment with resolved role definition ID' {
            New-RBACRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role $script:testRoleName -TenantId $script:testTenantId

            Should -Invoke New-RoleAssignment -Times 1 -ParameterFilter {
                $RoleDefinitionId -eq $script:testRoleDefinitionId
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Environment-scoped role assignment' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Resolve-RoleDefinitionId { return $script:testRoleDefinitionId } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-RoleAssignment { return $script:mockRoleAssignmentResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create an environment-scoped role assignment' {
            $result = New-RBACRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType Group -Role $script:testRoleName -TenantId $script:testTenantId -EnvironmentId $script:testEnvironmentId

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Environment group-scoped role assignment' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Resolve-RoleDefinitionId { return $script:testRoleDefinitionId } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-RoleAssignment { return $script:mockRoleAssignmentResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create an environment group-scoped role assignment' {
            $result = New-RBACRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType ApplicationUser -Role $script:testRoleName -TenantId $script:testTenantId -EnvironmentGroupId $script:testEnvironmentGroupId

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'RefreshRoles parameter' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Resolve-RoleDefinitionId { return $script:testRoleDefinitionId } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-RoleAssignment { return $script:mockRoleAssignmentResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should pass RefreshRoles to Resolve-RoleDefinitionId' {
            New-RBACRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role $script:testRoleName -TenantId $script:testTenantId -RefreshRoles

            Should -Invoke Resolve-RoleDefinitionId -Times 1 -ParameterFilter {
                $RefreshRoles -eq $true
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Error handling' {
        It 'Should throw when New-AuthorizationServiceMsalClient fails' {
            Mock New-AuthorizationServiceMsalClient { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-RBACRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role $script:testRoleName -TenantId $script:testTenantId } | Should -Throw "*Failed to connect to Authorization Service*"
        }
    }
}
