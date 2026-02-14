[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Test-AuthorizationApplication Tests' {
    BeforeAll {
        $script:testTenantId = "12345678-1234-1234-1234-123456789012"
        $script:testAppId = "00000000-0000-0000-0000-000000000001"
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

        $script:mockValidApplication = [PSCustomObject]@{
            Id = "app-object-id"
            AppId = $script:testAppId
            DisplayName = "TestApp"
            IsFallbackPublicClient = $true
            PublicClient = [PSCustomObject]@{
                RedirectUri = @("http://localhost")
            }
            RequiredResourceAccess = @(
                [PSCustomObject]@{
                    ResourceAppId = $script:prodApiId
                    ResourceAccess = @(
                        [PSCustomObject]@{ Id = "read-permission-id"; Type = "Scope" },
                        [PSCustomObject]@{ Id = "write-permission-id"; Type = "Scope" }
                    )
                }
            )
        }

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Warning {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Valid application configuration' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADApplication { return $script:mockValidApplication } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADServicePrincipal { return $script:mockServicePrincipal } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return true for correctly configured application' {
            $result = Test-AuthorizationApplication -ClientId $script:testAppId -TenantId $script:testTenantId

            $result | Should -Be $true
        }

        It 'Should use prod API ID for prod endpoint' {
            Test-AuthorizationApplication -ClientId $script:testAppId -TenantId $script:testTenantId -Endpoint prod

            Should -Invoke Get-AzADServicePrincipal -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter {
                $Filter -like "*$($script:prodApiId)*"
            }
        }
    }

    Context 'TIP endpoint validation' {
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

            $script:mockTipApplication = [PSCustomObject]@{
                Id = "app-object-id"
                AppId = $script:testAppId
                DisplayName = "TestApp"
                IsFallbackPublicClient = $true
                PublicClient = [PSCustomObject]@{
                    RedirectUri = @("http://localhost")
                }
                RequiredResourceAccess = @(
                    [PSCustomObject]@{
                        ResourceAppId = $script:tipApiId
                        ResourceAccess = @(
                            [PSCustomObject]@{ Id = "read-permission-id"; Type = "Scope" },
                            [PSCustomObject]@{ Id = "write-permission-id"; Type = "Scope" }
                        )
                    }
                )
            }

            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADApplication { return $script:mockTipApplication } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADServicePrincipal { return $script:mockTipServicePrincipal } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should use TIP API ID for tip1 endpoint' {
            Test-AuthorizationApplication -ClientId $script:testAppId -TenantId $script:testTenantId -Endpoint tip1

            Should -Invoke Get-AzADServicePrincipal -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter {
                $Filter -like "*$($script:tipApiId)*"
            }
        }
    }

    Context 'Error handling' {
        It 'Should return false when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-AuthorizationApplication -ClientId $script:testAppId -TenantId $script:testTenantId

            $result | Should -Be $false
        }

        It 'Should return false when application not found' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADApplication { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-AuthorizationApplication -ClientId $script:testAppId -TenantId $script:testTenantId

            $result | Should -Be $false
        }

        It 'Should return false when application is not a public client' {
            $mockNonPublicApp = [PSCustomObject]@{
                Id = "app-object-id"
                AppId = $script:testAppId
                DisplayName = "TestApp"
                IsFallbackPublicClient = $false
                RequiredResourceAccess = @()
            }
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADApplication { return $mockNonPublicApp } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-AuthorizationApplication -ClientId $script:testAppId -TenantId $script:testTenantId

            $result | Should -Be $false
        }

        It 'Should return false when application is missing redirect URI' {
            $mockNoRedirectApp = [PSCustomObject]@{
                Id = "app-object-id"
                AppId = $script:testAppId
                DisplayName = "TestApp"
                IsFallbackPublicClient = $true
                PublicClient = [PSCustomObject]@{
                    RedirectUri = @()
                }
                RequiredResourceAccess = @()
            }
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADApplication { return $mockNoRedirectApp } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-AuthorizationApplication -ClientId $script:testAppId -TenantId $script:testTenantId

            $result | Should -Be $false
        }

        It 'Should return false when application has no API permissions' {
            $mockNoPermissionsApp = [PSCustomObject]@{
                Id = "app-object-id"
                AppId = $script:testAppId
                DisplayName = "TestApp"
                IsFallbackPublicClient = $true
                PublicClient = [PSCustomObject]@{
                    RedirectUri = @("http://localhost")
                }
                RequiredResourceAccess = @()
            }
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADApplication { return $mockNoPermissionsApp } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-AuthorizationApplication -ClientId $script:testAppId -TenantId $script:testTenantId

            $result | Should -Be $false
        }

        It 'Should return false when application is missing read permission' {
            $mockMissingReadApp = [PSCustomObject]@{
                Id = "app-object-id"
                AppId = $script:testAppId
                DisplayName = "TestApp"
                IsFallbackPublicClient = $true
                PublicClient = [PSCustomObject]@{
                    RedirectUri = @("http://localhost")
                }
                RequiredResourceAccess = @(
                    [PSCustomObject]@{
                        ResourceAppId = $script:prodApiId
                        ResourceAccess = @(
                            [PSCustomObject]@{ Id = "write-permission-id"; Type = "Scope" }
                        )
                    }
                )
            }
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADApplication { return $mockMissingReadApp } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADServicePrincipal { return $script:mockServicePrincipal } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-AuthorizationApplication -ClientId $script:testAppId -TenantId $script:testTenantId

            $result | Should -Be $false
        }

        It 'Should return false when API service principal not found' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADApplication { return $script:mockValidApplication } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AzADServicePrincipal { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-AuthorizationApplication -ClientId $script:testAppId -TenantId $script:testTenantId

            $result | Should -Be $false
        }
    }
}
