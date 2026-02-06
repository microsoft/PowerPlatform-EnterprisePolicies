[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'New-RoleAssignment Tests' {
    BeforeAll {
        $script:testTenantId = "12345678-1234-1234-1234-123456789012"
        $script:testEnvironmentId = "00000000-0000-0000-0000-000000000001"
        $script:testEnvironmentGroupId = "00000000-0000-0000-0000-000000000002"
        $script:testPrincipalObjectId = "00000000-0000-0000-0000-000000000003"
        $script:testRoleDefinitionId = "c5f0d2b3-8e4a-4c7d-a1b9-6e3f2d8c5a4b"

        $script:mockRoleAssignmentResponse = @{
            id = "role-assignment-id"
            principalObjectId = $script:testPrincipalObjectId
            principalType = "User"
            scope = "/tenants/$($script:testTenantId)/roleAssignments"
            roleDefinitionId = $script:testRoleDefinitionId
        }

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Tenant-scoped role assignment' {
        BeforeAll {
            $script:mockResultJson = ($script:mockRoleAssignmentResponse | ConvertTo-Json)
            $script:mockResult = [HttpClientResultMock]::new($script:mockResultJson)

            Mock Get-AuthorizationServiceToken { return "test-token" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-APIResourceUrl { return "https://api.powerplatform.com/" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-JsonRequestMessage { return [PSCustomObject]@{} } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Send-RequestWithRetries { return $script:mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Assert-Result {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { param($task) return $task } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create a tenant-scoped role assignment' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" -Parameters @{
                testPrincipalObjectId = $script:testPrincipalObjectId
                testRoleDefinitionId = $script:testRoleDefinitionId
                testTenantId = $script:testTenantId
            } {
                $result = New-RoleAssignment -PrincipalObjectId $testPrincipalObjectId -PrincipalType User -RoleDefinitionId $testRoleDefinitionId -TenantId $testTenantId
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should call Send-RequestWithRetries' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" -Parameters @{
                testPrincipalObjectId = $script:testPrincipalObjectId
                testRoleDefinitionId = $script:testRoleDefinitionId
                testTenantId = $script:testTenantId
            } {
                New-RoleAssignment -PrincipalObjectId $testPrincipalObjectId -PrincipalType User -RoleDefinitionId $testRoleDefinitionId -TenantId $testTenantId
            }
            Should -Invoke Send-RequestWithRetries -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should call Get-APIResourceUrl' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" -Parameters @{
                testPrincipalObjectId = $script:testPrincipalObjectId
                testRoleDefinitionId = $script:testRoleDefinitionId
                testTenantId = $script:testTenantId
            } {
                New-RoleAssignment -PrincipalObjectId $testPrincipalObjectId -PrincipalType User -RoleDefinitionId $testRoleDefinitionId -TenantId $testTenantId
            }
            Should -Invoke Get-APIResourceUrl -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Environment-scoped role assignment' {
        BeforeAll {
            $script:mockEnvironmentRoleAssignmentResponse = @{
                id = "role-assignment-id"
                principalObjectId = $script:testPrincipalObjectId
                principalType = "Group"
                scope = "/tenants/$($script:testTenantId)/environments/$($script:testEnvironmentId)/roleAssignments"
                roleDefinitionId = $script:testRoleDefinitionId
            }
            $script:mockResultJson = ($script:mockEnvironmentRoleAssignmentResponse | ConvertTo-Json)
            $script:mockResult = [HttpClientResultMock]::new($script:mockResultJson)

            Mock Get-AuthorizationServiceToken { return "test-token" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-APIResourceUrl { return "https://api.powerplatform.com/" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-JsonRequestMessage { return [PSCustomObject]@{} } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Send-RequestWithRetries { return $script:mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Assert-Result {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { param($task) return $task } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create an environment-scoped role assignment' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" -Parameters @{
                testPrincipalObjectId = $script:testPrincipalObjectId
                testRoleDefinitionId = $script:testRoleDefinitionId
                testTenantId = $script:testTenantId
                testEnvironmentId = $script:testEnvironmentId
            } {
                $result = New-RoleAssignment -PrincipalObjectId $testPrincipalObjectId -PrincipalType Group -RoleDefinitionId $testRoleDefinitionId -TenantId $testTenantId -EnvironmentId $testEnvironmentId
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Environment group-scoped role assignment' {
        BeforeAll {
            $script:mockEnvGroupRoleAssignmentResponse = @{
                id = "role-assignment-id"
                principalObjectId = $script:testPrincipalObjectId
                principalType = "ApplicationUser"
                scope = "/tenants/$($script:testTenantId)/environmentGroups/$($script:testEnvironmentGroupId)/roleAssignments"
                roleDefinitionId = $script:testRoleDefinitionId
            }
            $script:mockResultJson = ($script:mockEnvGroupRoleAssignmentResponse | ConvertTo-Json)
            $script:mockResult = [HttpClientResultMock]::new($script:mockResultJson)

            Mock Get-AuthorizationServiceToken { return "test-token" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-APIResourceUrl { return "https://api.powerplatform.com/" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-JsonRequestMessage { return [PSCustomObject]@{} } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Send-RequestWithRetries { return $script:mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Assert-Result {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { param($task) return $task } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create an environment group-scoped role assignment' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" -Parameters @{
                testPrincipalObjectId = $script:testPrincipalObjectId
                testRoleDefinitionId = $script:testRoleDefinitionId
                testTenantId = $script:testTenantId
                testEnvironmentGroupId = $script:testEnvironmentGroupId
            } {
                $result = New-RoleAssignment -PrincipalObjectId $testPrincipalObjectId -PrincipalType ApplicationUser -RoleDefinitionId $testRoleDefinitionId -TenantId $testTenantId -EnvironmentGroupId $testEnvironmentGroupId
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }
}
