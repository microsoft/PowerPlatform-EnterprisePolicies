[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Remove-AuthorizationRoleAssignment Tests' {
    BeforeAll {
        $script:testClientId = "00000000-0000-0000-0000-000000789012"
        $script:testTenantId = "12345678-1234-1234-1234-123456789012"
        $script:testEnvironmentId = "00000000-0000-0000-0000-000000000001"
        $script:testEnvironmentGroupId = "00000000-0000-0000-0000-000000000002"
        $script:testRoleAssignmentId = "00000000-0000-0000-0000-000000000003"

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Tenant-scoped role assignment removal' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Remove-RoleAssignment { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should remove a tenant-scoped role assignment' {
            $result = Remove-AuthorizationRoleAssignment -ClientId $script:testClientId -RoleAssignmentId $script:testRoleAssignmentId -TenantId $script:testTenantId -Force

            $result | Should -Be $true
        }

        It 'Should call New-AuthorizationServiceMsalClient' {
            Remove-AuthorizationRoleAssignment -ClientId $script:testClientId -RoleAssignmentId $script:testRoleAssignmentId -TenantId $script:testTenantId -Force

            Should -Invoke New-AuthorizationServiceMsalClient -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should call Remove-RoleAssignment with correct parameters' {
            Remove-AuthorizationRoleAssignment -ClientId $script:testClientId -RoleAssignmentId $script:testRoleAssignmentId -TenantId $script:testTenantId -Force

            Should -Invoke Remove-RoleAssignment -Times 1 -ParameterFilter {
                $RoleAssignmentId -eq $script:testRoleAssignmentId
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Environment-scoped role assignment removal' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Remove-RoleAssignment { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should remove an environment-scoped role assignment' {
            $result = Remove-AuthorizationRoleAssignment -ClientId $script:testClientId -RoleAssignmentId $script:testRoleAssignmentId -TenantId $script:testTenantId -EnvironmentId $script:testEnvironmentId -Force

            $result | Should -Be $true
        }

        It 'Should pass EnvironmentId to Remove-RoleAssignment' {
            Remove-AuthorizationRoleAssignment -ClientId $script:testClientId -RoleAssignmentId $script:testRoleAssignmentId -TenantId $script:testTenantId -EnvironmentId $script:testEnvironmentId -Force

            Should -Invoke Remove-RoleAssignment -Times 1 -ParameterFilter {
                $EnvironmentId -eq $script:testEnvironmentId
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Environment group-scoped role assignment removal' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Remove-RoleAssignment { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should remove an environment group-scoped role assignment' {
            $result = Remove-AuthorizationRoleAssignment -ClientId $script:testClientId -RoleAssignmentId $script:testRoleAssignmentId -TenantId $script:testTenantId -EnvironmentGroupId $script:testEnvironmentGroupId -Force

            $result | Should -Be $true
        }

        It 'Should pass EnvironmentGroupId to Remove-RoleAssignment' {
            Remove-AuthorizationRoleAssignment -ClientId $script:testClientId -RoleAssignmentId $script:testRoleAssignmentId -TenantId $script:testTenantId -EnvironmentGroupId $script:testEnvironmentGroupId -Force

            Should -Invoke Remove-RoleAssignment -Times 1 -ParameterFilter {
                $EnvironmentGroupId -eq $script:testEnvironmentGroupId
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Role assignment not found' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Remove-RoleAssignment { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return false when role assignment is not found' {
            $result = Remove-AuthorizationRoleAssignment -ClientId $script:testClientId -RoleAssignmentId $script:testRoleAssignmentId -TenantId $script:testTenantId -Force

            $result | Should -Be $false
        }
    }

    Context 'Error handling' {
        It 'Should throw when New-AuthorizationServiceMsalClient fails' {
            Mock New-AuthorizationServiceMsalClient { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Remove-AuthorizationRoleAssignment -ClientId $script:testClientId -RoleAssignmentId $script:testRoleAssignmentId -TenantId $script:testTenantId -Force } | Should -Throw "*Failed to connect to Authorization Service*"
        }
    }
}
