[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'New-SubnetInjectionDiagnosticsRoleAssignment Tests' {
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
            roleDefinitionId = "c5f0d2b3-8e4a-4c7d-a1b9-6e3f2d8c5a4b"
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
            $result = New-SubnetInjectionDiagnosticsRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role Reader -TenantId $script:testTenantId

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should call New-AuthorizationServiceMsalClient' {
            New-SubnetInjectionDiagnosticsRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role Reader -TenantId $script:testTenantId

            Should -Invoke New-AuthorizationServiceMsalClient -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should call New-RoleAssignment' {
            New-SubnetInjectionDiagnosticsRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role Reader -TenantId $script:testTenantId

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
                roleDefinitionId = "b4e9c1a2-6d3f-4a8b-9e7c-5f2d1b8a3c6e"
            }

            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-RoleAssignment { return $script:mockEnvironmentRoleAssignmentResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create an environment-scoped role assignment' {
            $result = New-SubnetInjectionDiagnosticsRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType Group -Role Operator -TenantId $script:testTenantId -EnvironmentId $script:testEnvironmentId

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
                roleDefinitionId = "d6a1e3c4-9f5b-4d8e-b2c7-7a4e3f1d9b8c"
            }

            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-RoleAssignment { return $script:mockEnvGroupRoleAssignmentResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create an environment group-scoped role assignment' {
            $result = New-SubnetInjectionDiagnosticsRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType ApplicationUser -Role Administrator -TenantId $script:testTenantId -EnvironmentGroupId $script:testEnvironmentGroupId

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Role mapping' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-RoleAssignment { return $script:mockRoleAssignmentResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should accept Administrator role' {
            { New-SubnetInjectionDiagnosticsRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role Administrator -TenantId $script:testTenantId } | Should -Not -Throw
        }

        It 'Should accept Operator role' {
            { New-SubnetInjectionDiagnosticsRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role Operator -TenantId $script:testTenantId } | Should -Not -Throw
        }

        It 'Should accept Reader role' {
            { New-SubnetInjectionDiagnosticsRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role Reader -TenantId $script:testTenantId } | Should -Not -Throw
        }
    }

    Context 'Error handling' {
        It 'Should throw when New-AuthorizationServiceMsalClient fails' {
            Mock New-AuthorizationServiceMsalClient { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-SubnetInjectionDiagnosticsRoleAssignment -ClientId $script:testClientId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -Role Reader -TenantId $script:testTenantId } | Should -Throw "*Failed to connect to Authorization Service*"
        }
    }
}
