[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-RBACRoleAssignment Tests' {
    BeforeAll {
        $script:testClientId = "00000000-0000-0000-0000-000000789012"
        $script:testTenantId = "12345678-1234-1234-1234-123456789012"
        $script:testEnvironmentId = "00000000-0000-0000-0000-000000000001"

        $script:mockRoleAssignmentsResponse = @(
            @{
                id = "role-assignment-id-1"
                principalObjectId = "00000000-0000-0000-0000-000000000003"
                principalType = "User"
                scope = "/tenants/$($script:testTenantId)"
                roleDefinitionId = "c886ad2e-27f7-4874-8381-5849b8d8a090"
            },
            @{
                id = "role-assignment-id-2"
                principalObjectId = "00000000-0000-0000-0000-000000000004"
                principalType = "Group"
                scope = "/tenants/$($script:testTenantId)"
                roleDefinitionId = "ff954d61-a89a-4fbe-ace9-01c367b89f87"
            }
        )

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Tenant-scoped role assignments' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-RoleAssignments { return $script:mockRoleAssignmentsResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-CachedClientId {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should get tenant-scoped role assignments' {
            $result = Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should call New-AuthorizationServiceMsalClient' {
            Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId

            Should -Invoke New-AuthorizationServiceMsalClient -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should call Get-RoleAssignments with correct parameters' {
            Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId

            Should -Invoke Get-RoleAssignments -Times 1 -ParameterFilter {
                $TenantId -eq $script:testTenantId
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Environment-scoped role assignments' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-RoleAssignments { return $script:mockRoleAssignmentsResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-CachedClientId {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should get environment-scoped role assignments' {
            $result = Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId -EnvironmentId $script:testEnvironmentId

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should pass EnvironmentId to Get-RoleAssignments' {
            Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId -EnvironmentId $script:testEnvironmentId

            Should -Invoke Get-RoleAssignments -Times 1 -ParameterFilter {
                $EnvironmentId -eq $script:testEnvironmentId
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Default behavior enables all expansions' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-RoleAssignments { return $script:mockRoleAssignmentsResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-CachedClientId {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should default IncludeParentScopes to true' {
            Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId

            Should -Invoke Get-RoleAssignments -Times 1 -ParameterFilter {
                $IncludeParentScopes -eq $true
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should default ExpandSecurityGroups to true' {
            Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId

            Should -Invoke Get-RoleAssignments -Times 1 -ParameterFilter {
                $ExpandSecurityGroups -eq $true
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should default ExpandEnvironmentGroups to true' {
            Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId

            Should -Invoke Get-RoleAssignments -Times 1 -ParameterFilter {
                $ExpandEnvironmentGroups -eq $true
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should default IncludeNestedScopes to true' {
            Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId

            Should -Invoke Get-RoleAssignments -Times 1 -ParameterFilter {
                $IncludeNestedScopes -eq $true
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Negative switches disable expansions' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-RoleAssignments { return $script:mockRoleAssignmentsResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-CachedClientId {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should set IncludeParentScopes to false when ExcludeParentScopes is specified' {
            Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId -ExcludeParentScopes

            Should -Invoke Get-RoleAssignments -Times 1 -ParameterFilter {
                $IncludeParentScopes -eq $false
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should set ExpandSecurityGroups to false when NoExpandSecurityGroups is specified' {
            Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId -NoExpandSecurityGroups

            Should -Invoke Get-RoleAssignments -Times 1 -ParameterFilter {
                $ExpandSecurityGroups -eq $false
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should set ExpandEnvironmentGroups to false when NoExpandEnvironmentGroups is specified' {
            Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId -NoExpandEnvironmentGroups

            Should -Invoke Get-RoleAssignments -Times 1 -ParameterFilter {
                $ExpandEnvironmentGroups -eq $false
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should set IncludeNestedScopes to false when ExcludeNestedScopes is specified' {
            Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId -ExcludeNestedScopes

            Should -Invoke Get-RoleAssignments -Times 1 -ParameterFilter {
                $IncludeNestedScopes -eq $false
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Optional filter parameters' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-RoleAssignments { return $script:mockRoleAssignmentsResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-CachedClientId {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should pass PrincipalType when specified' {
            Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId -PrincipalType User

            Should -Invoke Get-RoleAssignments -Times 1 -ParameterFilter {
                $PrincipalType -eq [AuthorizationPrincipalType]::User
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should pass PrincipalObjectId when specified' {
            $testPrincipalId = "00000000-0000-0000-0000-000000000005"
            Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId -PrincipalObjectId $testPrincipalId

            Should -Invoke Get-RoleAssignments -Times 1 -ParameterFilter {
                $PrincipalObjectId -eq $testPrincipalId
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should pass Permission when specified' {
            Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId -Permission "Read"

            Should -Invoke Get-RoleAssignments -Times 1 -ParameterFilter {
                $Permission -eq "Read"
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Uses cached ClientId when not specified' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-RoleAssignments { return $script:mockRoleAssignmentsResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-CachedClientId { return $script:testClientId } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-CachedClientId {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should use cached ClientId when not specified' {
            $result = Get-RBACRoleAssignment -TenantId $script:testTenantId

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Throws when no ClientId specified and none cached' {
        BeforeAll {
            Mock Get-CachedClientId { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should throw when no ClientId specified and none cached' {
            { Get-RBACRoleAssignment -TenantId $script:testTenantId } | Should -Throw "*ClientId was not provided and no cached ClientId was found*"
        }
    }

    Context 'Error handling' {
        It 'Should throw when New-AuthorizationServiceMsalClient fails' {
            Mock New-AuthorizationServiceMsalClient { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-CachedClientId {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Get-RBACRoleAssignment -ClientId $script:testClientId -TenantId $script:testTenantId } | Should -Throw "*Failed to connect to Authorization Service*"
        }
    }
}
