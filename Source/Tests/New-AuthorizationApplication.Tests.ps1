[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'New-AuthorizationApplication Tests' {
    BeforeAll {
        $script:testTenantId = "12345678-1234-1234-1234-123456789012"
        $script:testDisplayName = "TestAuthorizationApp"
        $script:testAppId = "00000000-0000-0000-0000-000000000001"
        $script:testAppObjectId = "00000000-0000-0000-0000-000000000002"
        $script:testSpObjectId = "00000000-0000-0000-0000-000000000003"
        $script:prodApiId = "8578e004-a5c6-46e7-913e-12f58912df43"
        $script:tipApiId = "0ddb742a-e7dc-4899-a31e-80e797ec7144"

        $script:mockServicePrincipal = [PSCustomObject]@{
            Id = "sp-object-id"
            AppId = $script:prodApiId
            Oauth2PermissionScope = @(
                [PSCustomObject]@{
                    Id = "read-permission-id"
                    Value = "Authorization.RoleAssignments.Read"
                },
                [PSCustomObject]@{
                    Id = "write-permission-id"
                    Value = "Authorization.RoleAssignments.Write"
                }
            )
        }

        $script:mockApplication = [PSCustomObject]@{
            Id = $script:testAppObjectId
            AppId = $script:testAppId
            DisplayName = $script:testDisplayName
        }

        $script:mockAppServicePrincipal = [PSCustomObject]@{
            Id = $script:testSpObjectId
            AppId = $script:testAppId
            DisplayName = $script:testDisplayName
        }

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Successful application creation for prod endpoint' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADServicePrincipal { return $script:mockServicePrincipal } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-AzADApplication { return $script:mockApplication } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Update-AzADApplication {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-AzADServicePrincipal { return $script:mockAppServicePrincipal } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create application and return AppId' {
            $result = New-AuthorizationApplication -DisplayName $script:testDisplayName -TenantId $script:testTenantId

            $result | Should -Be $script:testAppId
        }

        It 'Should call Get-AzADServicePrincipal to look up API permissions' {
            New-AuthorizationApplication -DisplayName $script:testDisplayName -TenantId $script:testTenantId -Endpoint prod

            Should -Invoke Get-AzADServicePrincipal -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create service principal for the application' {
            New-AuthorizationApplication -DisplayName $script:testDisplayName -TenantId $script:testTenantId

            Should -Invoke New-AzADServicePrincipal -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'TIP endpoints use different API ID' {
        BeforeAll {
            $script:mockTipServicePrincipal = [PSCustomObject]@{
                Id = "sp-object-id"
                AppId = $script:tipApiId
                Oauth2PermissionScope = @(
                    [PSCustomObject]@{
                        Id = "read-permission-id"
                        Value = "Authorization.RoleAssignments.Read"
                    },
                    [PSCustomObject]@{
                        Id = "write-permission-id"
                        Value = "Authorization.RoleAssignments.Write"
                    }
                )
            }

            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADServicePrincipal { return $script:mockTipServicePrincipal } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-AzADApplication { return $script:mockApplication } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Update-AzADApplication {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-AzADServicePrincipal { return $script:mockAppServicePrincipal } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should succeed with tip1 endpoint' {
            $result = New-AuthorizationApplication -DisplayName $script:testDisplayName -TenantId $script:testTenantId -Endpoint tip1

            $result | Should -Be $script:testAppId
        }

        It 'Should succeed with tip2 endpoint' {
            $result = New-AuthorizationApplication -DisplayName $script:testDisplayName -TenantId $script:testTenantId -Endpoint tip2

            $result | Should -Be $script:testAppId
        }
    }

    Context 'Error handling' {
        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-AuthorizationApplication -DisplayName $script:testDisplayName -TenantId $script:testTenantId } | Should -Throw "*Failed to connect to Azure*"
        }

        It 'Should throw when API service principal not found' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADServicePrincipal { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-AuthorizationApplication -DisplayName $script:testDisplayName -TenantId $script:testTenantId } | Should -Throw "*Could not find service principal*"
        }

        It 'Should throw when application creation fails' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADServicePrincipal { return $script:mockServicePrincipal } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-AzADApplication { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-AuthorizationApplication -DisplayName $script:testDisplayName -TenantId $script:testTenantId } | Should -Throw "*Failed to create the application*"
        }

        It 'Should throw when service principal creation fails' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADServicePrincipal { return $script:mockServicePrincipal } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-AzADApplication { return $script:mockApplication } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Update-AzADApplication {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-AzADServicePrincipal { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-AuthorizationApplication -DisplayName $script:testDisplayName -TenantId $script:testTenantId } | Should -Throw "*Failed to create the service principal*"
        }
    }
}
