[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Test-RBACDiagnosticPermission Tests' {
    BeforeAll {
        $script:testClientId = "00000000-0000-0000-0000-000000789012"
        $script:testTenantId = "12345678-1234-1234-1234-123456789012"
        $script:testEnvironmentId = "00000000-0000-0000-0000-000000000001"
        $script:testPrincipalObjectId = "00000000-0000-0000-0000-000000000003"

        $script:mockPermissionResponse = @{
            hasPermission = $true
            permissions = @(
                @{ permission = "EnvironmentManagement.SubnetDiagnostics.Read"; granted = $true }
            )
        }

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Return value' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Test-PrincipalPermission { return $script:mockPermissionResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-CachedClientId {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return permission results' {
            $result = Test-RBACDiagnosticPermission -ClientId $script:testClientId -TenantId $script:testTenantId -EnvironmentId $script:testEnvironmentId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -ReadDiagnostic

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Testing individual permissions' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Test-PrincipalPermission { return $script:mockPermissionResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-CachedClientId {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should test only Read permission when -ReadDiagnostic specified' {
            Test-RBACDiagnosticPermission -ClientId $script:testClientId -TenantId $script:testTenantId -EnvironmentId $script:testEnvironmentId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -ReadDiagnostic

            Should -Invoke Test-PrincipalPermission -Times 1 -ParameterFilter {
                $Permissions.Count -eq 1 -and
                $Permissions -contains "EnvironmentManagement.SubnetDiagnostics.Read"
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should test only Action permission when -RunDiagnostic specified' {
            Test-RBACDiagnosticPermission -ClientId $script:testClientId -TenantId $script:testTenantId -EnvironmentId $script:testEnvironmentId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType ApplicationUser -RunDiagnostic

            Should -Invoke Test-PrincipalPermission -Times 1 -ParameterFilter {
                $Permissions.Count -eq 1 -and
                $Permissions -contains "EnvironmentManagement.SubnetDiagnostics.Action"
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should test only Write permission when -RunMitigation specified' {
            Test-RBACDiagnosticPermission -ClientId $script:testClientId -TenantId $script:testTenantId -EnvironmentId $script:testEnvironmentId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType Group -RunMitigation

            Should -Invoke Test-PrincipalPermission -Times 1 -ParameterFilter {
                $Permissions.Count -eq 1 -and
                $Permissions -contains "EnvironmentManagement.SubnetDiagnostics.Write"
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Parameter passing' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Test-PrincipalPermission { return $script:mockPermissionResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-CachedClientId {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should pass correct parameters to Test-PrincipalPermission' {
            Test-RBACDiagnosticPermission -ClientId $script:testClientId -TenantId $script:testTenantId -EnvironmentId $script:testEnvironmentId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -ReadDiagnostic

            Should -Invoke Test-PrincipalPermission -Times 1 -ParameterFilter {
                $TenantId -eq $script:testTenantId -and
                $EnvironmentId -eq $script:testEnvironmentId -and
                $PrincipalObjectId -eq $script:testPrincipalObjectId -and
                $PrincipalType -eq [AuthorizationPrincipalType]::User
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Uses cached ClientId when not specified' {
        BeforeAll {
            Mock New-AuthorizationServiceMsalClient { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Test-PrincipalPermission { return $script:mockPermissionResponse } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-CachedClientId { return $script:testClientId } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-CachedClientId {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should use cached ClientId when not specified' {
            $result = Test-RBACDiagnosticPermission -TenantId $script:testTenantId -EnvironmentId $script:testEnvironmentId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -ReadDiagnostic

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Throws when no ClientId specified and none cached' {
        BeforeAll {
            Mock Get-CachedClientId { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should throw when no ClientId specified and none cached' {
            { Test-RBACDiagnosticPermission -TenantId $script:testTenantId -EnvironmentId $script:testEnvironmentId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -ReadDiagnostic } | Should -Throw "*ClientId was not provided and no cached ClientId was found*"
        }
    }

    Context 'Error handling' {
        It 'Should throw when New-AuthorizationServiceMsalClient fails' {
            Mock New-AuthorizationServiceMsalClient { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-CachedClientId {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Test-RBACDiagnosticPermission -ClientId $script:testClientId -TenantId $script:testTenantId -EnvironmentId $script:testEnvironmentId -PrincipalObjectId $script:testPrincipalObjectId -PrincipalType User -ReadDiagnostic } | Should -Throw "*Failed to connect to Authorization Service*"
        }
    }
}
