[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1 -Module
}

Describe 'AuthenticationOperations Tests' {
    InModuleScope 'Microsoft.PowerPlatform.EnterprisePolicies' {
        BeforeAll{
            Mock Write-Host {}
        }
        Context 'Testing Connect-Azure' {
            It 'Connects to Azure with the correct environment' {
                $endpoint = [PPEndpoint]::usgovhigh
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureUSGovernment" } -Verifiable
                Mock Get-AzContext {}
                Connect-Azure -Endpoint $endpoint | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1
            }

            It 'Prefers a context with home tenant if multiple context are available' {
                $endpoint = [PPEndpoint]::prod
                $tenantId = "12345678-1234-1234-1234-123456789012"
                Mock Get-AzContext { 
                    return @(
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "smth"; Tenants = @("87654321-4321-4321-4321-210987654321") }; Tenant = @{ TenantCategory = ""; Id = $tenantId } },
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "smth2"; Tenants = @($tenantId) }; Tenant = @{ TenantCategory = "Home"; Id = $tenantId } }
                    )
                }
                Mock Set-AzContext {}
                Connect-Azure -Endpoint $endpoint -TenantId $tenantId | Should -Be $true
                Assert-MockCalled Set-AzContext -Exactly 1
            }
    
            It 'Connects to Azure with a specific tenant' {
                $endpoint = [PPEndpoint]::china
                $tenantId = "12345678-1234-1234-1234-123456789012"
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureChinaCloud" -and $Tenant -eq $tenantId } -Verifiable
                Mock Get-AzContext {}
                Connect-Azure -Endpoint $endpoint -TenantId $tenantId | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1
            }
    
            It 'Invokes Connect-AzAccount if tenant does not match' {
                $endpoint = [PPEndpoint]::prod
                $tenantId = "12345678-1234-1234-1234-123456789012"
                Mock Get-AzContext { 
                    return @(
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "smth"; Tenants = @("87654321-4321-4321-4321-210987654321") } }
                    )
                }
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureCloud" -and $Tenant -eq $tenantId } -Verifiable
                Connect-Azure -Endpoint $endpoint -TenantId $tenantId | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1
            }

            It 'Prefers service principal context over user context (no tenant)' {
                $endpoint = [PPEndpoint]::prod
                Mock Get-AzContext {
                    return @(
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "user@test.com"; Type = "User"; Tenants = @("tenant1") } },
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "sp-app-id"; Type = "ServicePrincipal"; Tenants = @("tenant1") } }
                    )
                }
                Mock Set-AzContext {}
                Connect-Azure -Endpoint $endpoint | Should -Be $true
                Assert-MockCalled Set-AzContext -Exactly 1 -ParameterFilter { $Context.Account.Id -eq "sp-app-id" }
            }

            It 'Prefers service principal context over user context (with tenant)' {
                $endpoint = [PPEndpoint]::prod
                $tenantId = "12345678-1234-1234-1234-123456789012"
                Mock Get-AzContext {
                    return @(
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "user@test.com"; Type = "User"; Tenants = @($tenantId) }; Tenant = @{ TenantCategory = "Home"; Id = $tenantId } },
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "sp-app-id"; Type = "ServicePrincipal"; Tenants = @($tenantId) }; Tenant = @{ TenantCategory = "Home"; Id = $tenantId } }
                    )
                }
                Mock Set-AzContext {}
                Connect-Azure -Endpoint $endpoint -TenantId $tenantId | Should -Be $true
                Assert-MockCalled Set-AzContext -Exactly 1 -ParameterFilter { $Context.Account.Id -eq "sp-app-id" }
            }

            It 'Falls back to user context when no SP available' {
                $endpoint = [PPEndpoint]::prod
                Mock Get-AzContext {
                    return @(
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "user@test.com"; Type = "User"; Tenants = @("tenant1") } }
                    )
                }
                Mock Set-AzContext {}
                Connect-Azure -Endpoint $endpoint | Should -Be $true
                Assert-MockCalled Set-AzContext -Exactly 1 -ParameterFilter { $Context.Account.Id -eq "user@test.com" }
            }

            It 'Prefers SP in fallback tenant selection' {
                $endpoint = [PPEndpoint]::prod
                $tenantId = "12345678-1234-1234-1234-123456789012"
                Mock Get-AzContext {
                    return @(
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "user@test.com"; Type = "User"; Tenants = @($tenantId) }; Tenant = @{ TenantCategory = ""; Id = "other-tenant" } },
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "sp-app-id"; Type = "ServicePrincipal"; Tenants = @($tenantId) }; Tenant = @{ TenantCategory = ""; Id = "other-tenant" } }
                    )
                }
                Mock Set-AzContext {}
                Connect-Azure -Endpoint $endpoint -TenantId $tenantId | Should -Be $true
                Assert-MockCalled Set-AzContext -Exactly 1 -ParameterFilter { $Context.Account.Id -eq "sp-app-id" }
            }

            It 'Forces a login in with Force switch' {
                $endpoint = [PPEndpoint]::prod
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureCloud" } -Verifiable
                Mock Get-AzContext {
                    return @(
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "smth"; Tenants = @("87654321-4321-4321-4321-210987654321") } }
                    )
                }
                Connect-Azure -Endpoint $endpoint -Force | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1
            }

            It 'Forces a login if auth scope is provided' {
                $endpoint = [PPEndpoint]::prod
                $authScope = "https://management.azure.com/.default"
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureCloud" } -Verifiable
                Mock Get-AzContext {
                    return @(
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "smth"; Tenants = @("87654321-4321-4321-4321-210987654321") } }
                    )
                }
                Connect-Azure -Endpoint $endpoint -AuthScope $authScope | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1
            }

            It 'Forces a login if no context is found' {
                $endpoint = [PPEndpoint]::prod
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureCloud" } -Verifiable
                Mock Get-AzContext { return $null }
                Connect-Azure -Endpoint $endpoint | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1
            }

            It 'Forces a login if no context is found and auth scope is provided and force is set' {
                $endpoint = [PPEndpoint]::prod
                $authScope = "https://management.azure.com/.default"
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Environment -eq "AzureCloud" } -Verifiable
                Mock Get-AzContext { return $null }
                Connect-Azure -Endpoint $endpoint -AuthScope $authScope -Force | Should -Be $true
                Assert-MockCalled Connect-AzAccount -Exactly 1
            }
        }

        Context 'Testing Get-AccessToken' {
            It 'Returns token when Get-AzAccessToken succeeds' {
                $mockToken = [PSCustomObject]@{ Token = (ConvertTo-SecureString "test-token" -AsPlainText -Force) }
                Mock Get-AzAccessToken { return $mockToken }

                $result = Get-AccessToken -Endpoint ([PPEndpoint]::prod) -ResourceUrl "https://api.test.com"

                $result | Should -Not -BeNullOrEmpty
            }

            It 'Throws when token acquisition fails completely' {
                Mock Get-AzAccessToken { return $null }
                Mock Connect-Azure { return $true }

                { Get-AccessToken -Endpoint ([PPEndpoint]::prod) -ResourceUrl "https://api.test.com" } | Should -Throw "*Failed to acquire access token*"
            }
        }

        Context 'Testing Get-PPAPIAccessToken' {
            It 'Calls Get-AccessToken with correct resource URL' {
                $mockToken = [PSCustomObject]@{ Token = (ConvertTo-SecureString "test-token" -AsPlainText -Force) }
                Mock Get-APIResourceUrl { return "https://api.powerplatform.com" }
                Mock Get-AzAccessToken { return $mockToken }

                $result = Get-PPAPIAccessToken -Endpoint ([PPEndpoint]::prod)

                $result | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Testing Get-PPAccessToken' {
            It 'Calls Get-AccessToken with PP resource URL' {
                $mockToken = [PSCustomObject]@{ Token = (ConvertTo-SecureString "test-token" -AsPlainText -Force) }
                Mock Get-PPResourceUrl { return "https://service.powerapps.com" }
                Mock Get-AzAccessToken { return $mockToken }

                $result = Get-PPAccessToken -Endpoint ([PPEndpoint]::prod)

                $result | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Testing ConvertFrom-SecureStringInternal' {
            It 'Converts SecureString to plain text' {
                $secureString = ConvertTo-SecureString "test-value" -AsPlainText -Force

                $result = ConvertFrom-SecureStringInternal -SecureString $secureString

                $result | Should -Be "test-value"
            }
        }

        Context 'Testing New-AuthorizationServiceMsalClient' {
            BeforeAll {
                # Define stub function so it can be mocked (the real one is dot-sourced at runtime)
                function Get-PublicClientApplicationBuilder { param($ClientId) }

                # Create mock objects that simulate MSAL fluent API
                $script:mockApp = [PSCustomObject]@{}
                $script:mockApp | Add-Member -MemberType ScriptMethod -Name 'AcquireTokenInteractive' -Value { return $null }
                $script:mockApp | Add-Member -MemberType ScriptMethod -Name 'AcquireTokenSilent' -Value { return $null }

                $script:mockBuilder = [PSCustomObject]@{}
                $script:mockBuilder | Add-Member -MemberType ScriptMethod -Name 'WithAuthority' -Value { return $script:mockBuilder }
                $script:mockBuilder | Add-Member -MemberType ScriptMethod -Name 'WithRedirectUri' -Value { return $script:mockBuilder }
                $script:mockBuilder | Add-Member -MemberType ScriptMethod -Name 'Build' -Value { return $script:mockApp }
            }

            BeforeEach {
                # Reset module-scoped cache before each test
                $script:AuthorizationServiceCache = @{}
                $script:AuthorizationServiceCurrentKey = $null
                Mock Set-CachedClientId {}
            }

            It 'Returns true on successful connection' {
                Mock Get-PublicClientApplicationBuilder { return $script:mockBuilder }

                $result = New-AuthorizationServiceMsalClient -ClientId "test-client-id" -TenantId "test-tenant-id"

                $result | Should -Be $true
            }

            It 'Resolves ClientId from cache when not provided' {
                Mock Get-CachedClientId { return "cached-client-id" }
                Mock Get-PublicClientApplicationBuilder { return $script:mockBuilder }

                $result = New-AuthorizationServiceMsalClient -TenantId "test-tenant-id"

                $result | Should -Be $true
            }

            It 'Throws when ClientId not provided and not cached' {
                Mock Get-CachedClientId { return $null }

                { New-AuthorizationServiceMsalClient -TenantId "test-tenant-id" } | Should -Throw "*no cached ClientId was found*"
            }

            It 'Caches ClientId when explicitly provided' {
                Mock Get-PublicClientApplicationBuilder { return $script:mockBuilder }

                New-AuthorizationServiceMsalClient -ClientId "my-client-id" -TenantId "test-tenant-id"

                Should -Invoke Set-CachedClientId -Exactly 1 -ParameterFilter { $ClientId -eq "my-client-id" }
            }

            It 'Uses correct authority for prod endpoint' {
                $capturedAuthority = $null
                $builderWithCapture = [PSCustomObject]@{}
                $builderWithCapture | Add-Member -MemberType ScriptMethod -Name 'WithAuthority' -Value {
                    param($auth)
                    $script:capturedAuthority = $auth
                    return $script:mockBuilder
                }
                Mock Get-PublicClientApplicationBuilder { return $builderWithCapture }

                New-AuthorizationServiceMsalClient -ClientId "test-client-id" -TenantId "my-tenant" -Endpoint ([PPEndpoint]::prod)

                $script:capturedAuthority | Should -Be "https://login.microsoftonline.com/my-tenant"
            }

            It 'Uses correct authority for usgovhigh endpoint' {
                $capturedAuthority = $null
                $builderWithCapture = [PSCustomObject]@{}
                $builderWithCapture | Add-Member -MemberType ScriptMethod -Name 'WithAuthority' -Value {
                    param($auth)
                    $script:capturedAuthority = $auth
                    return $script:mockBuilder
                }
                Mock Get-PublicClientApplicationBuilder { return $builderWithCapture }

                New-AuthorizationServiceMsalClient -ClientId "test-client-id" -TenantId "my-tenant" -Endpoint ([PPEndpoint]::usgovhigh)

                $script:capturedAuthority | Should -Be "https://login.microsoftonline.us/my-tenant"
            }

            It 'Uses correct authority for china endpoint' {
                $capturedAuthority = $null
                $builderWithCapture = [PSCustomObject]@{}
                $builderWithCapture | Add-Member -MemberType ScriptMethod -Name 'WithAuthority' -Value {
                    param($auth)
                    $script:capturedAuthority = $auth
                    return $script:mockBuilder
                }
                Mock Get-PublicClientApplicationBuilder { return $builderWithCapture }

                New-AuthorizationServiceMsalClient -ClientId "test-client-id" -TenantId "my-tenant" -Endpoint ([PPEndpoint]::china)

                $script:capturedAuthority | Should -Be "https://login.chinacloudapi.cn/my-tenant"
            }

            It 'Skips connection if already connected and Force not specified' {
                Mock Get-PublicClientApplicationBuilder { return $script:mockBuilder }

                # Connect first time
                New-AuthorizationServiceMsalClient -ClientId "test-client-id" -TenantId "test-tenant-id"
                # Connect second time without Force
                $result = New-AuthorizationServiceMsalClient -ClientId "test-client-id" -TenantId "test-tenant-id"

                $result | Should -Be $true
                Should -Invoke Get-PublicClientApplicationBuilder -Times 1
            }

            It 'Reconnects when Force is specified' {
                Mock Get-PublicClientApplicationBuilder { return $script:mockBuilder }

                # Connect first time
                New-AuthorizationServiceMsalClient -ClientId "test-client-id" -TenantId "test-tenant-id"
                # Connect second time with Force
                New-AuthorizationServiceMsalClient -ClientId "test-client-id" -TenantId "test-tenant-id" -Force

                Should -Invoke Get-PublicClientApplicationBuilder -Times 2
            }
        }

        Context 'Testing Get-AuthorizationServiceToken' {
            BeforeAll {
                # Define stub function so it can be mocked
                function Get-PublicClientApplicationBuilder { param($ClientId) }

                # Create mock objects that simulate MSAL fluent API
                $script:mockAuthResult = [PSCustomObject]@{
                    AccessToken = "mock-access-token"
                    Account = [PSCustomObject]@{ Username = "user@test.com" }
                }

                $script:mockAwaiter = [PSCustomObject]@{}
                $script:mockAwaiter | Add-Member -MemberType ScriptMethod -Name 'GetResult' -Value { return $script:mockAuthResult }

                $script:mockTask = [PSCustomObject]@{}
                $script:mockTask | Add-Member -MemberType ScriptMethod -Name 'GetAwaiter' -Value { return $script:mockAwaiter }

                $script:mockInteractiveRequest = [PSCustomObject]@{}
                $script:mockInteractiveRequest | Add-Member -MemberType ScriptMethod -Name 'ExecuteAsync' -Value { return $script:mockTask }

                $script:mockSilentRequest = [PSCustomObject]@{}
                $script:mockSilentRequest | Add-Member -MemberType ScriptMethod -Name 'ExecuteAsync' -Value { return $script:mockTask }

                $script:mockApp = [PSCustomObject]@{}
                $script:mockApp | Add-Member -MemberType ScriptMethod -Name 'AcquireTokenInteractive' -Value { return $script:mockInteractiveRequest }
                $script:mockApp | Add-Member -MemberType ScriptMethod -Name 'AcquireTokenSilent' -Value { return $script:mockSilentRequest }

                $script:mockBuilder = [PSCustomObject]@{}
                $script:mockBuilder | Add-Member -MemberType ScriptMethod -Name 'WithAuthority' -Value { return $script:mockBuilder }
                $script:mockBuilder | Add-Member -MemberType ScriptMethod -Name 'WithRedirectUri' -Value { return $script:mockBuilder }
                $script:mockBuilder | Add-Member -MemberType ScriptMethod -Name 'Build' -Value { return $script:mockApp }
            }

            BeforeEach {
                # Reset module-scoped cache before each test
                $script:AuthorizationServiceCache = @{}
                $script:AuthorizationServiceCurrentKey = $null
            }

            It 'Throws when not connected' {
                { Get-AuthorizationServiceToken -Endpoint ([PPEndpoint]::Prod) } | Should -Throw "*Call New-AuthorizationServiceMsalClient first*"
            }

            It 'Returns access token after interactive authentication' {
                Mock Get-PublicClientApplicationBuilder { return $script:mockBuilder }
                Mock Get-APIResourceUrl { return "https://api.powerplatform.com/" }

                New-AuthorizationServiceMsalClient -ClientId "test-client-id" -TenantId "test-tenant-id"
                $result = Get-AuthorizationServiceToken -Endpoint ([PPEndpoint]::Prod)

                $result | Should -Be "mock-access-token"
            }

            It 'Throws when token acquisition fails' {
                $mockFailedResult = [PSCustomObject]@{
                    AccessToken = $null
                    Account = $null
                }
                $mockFailedAwaiter = [PSCustomObject]@{}
                $mockFailedAwaiter | Add-Member -MemberType ScriptMethod -Name 'GetResult' -Value { return $mockFailedResult }
                $mockFailedTask = [PSCustomObject]@{}
                $mockFailedTask | Add-Member -MemberType ScriptMethod -Name 'GetAwaiter' -Value { return $mockFailedAwaiter }
                $mockFailedRequest = [PSCustomObject]@{}
                $mockFailedRequest | Add-Member -MemberType ScriptMethod -Name 'ExecuteAsync' -Value { return $mockFailedTask }
                $mockFailedApp = [PSCustomObject]@{}
                $mockFailedApp | Add-Member -MemberType ScriptMethod -Name 'AcquireTokenInteractive' -Value { return $mockFailedRequest }
                $mockFailedApp | Add-Member -MemberType ScriptMethod -Name 'AcquireTokenSilent' -Value { return $mockFailedRequest }
                $mockFailedBuilder = [PSCustomObject]@{}
                $mockFailedBuilder | Add-Member -MemberType ScriptMethod -Name 'WithAuthority' -Value { return $mockFailedBuilder }
                $mockFailedBuilder | Add-Member -MemberType ScriptMethod -Name 'WithRedirectUri' -Value { return $mockFailedBuilder }
                $mockFailedBuilder | Add-Member -MemberType ScriptMethod -Name 'Build' -Value { return $mockFailedApp }

                Mock Get-PublicClientApplicationBuilder { return $mockFailedBuilder }
                Mock Get-APIResourceUrl { return "https://api.powerplatform.com/" }

                New-AuthorizationServiceMsalClient -ClientId "test-client-id" -TenantId "test-tenant-id"
                { Get-AuthorizationServiceToken -Endpoint ([PPEndpoint]::Prod) } | Should -Throw "*Failed to acquire access token*"
            }
        }
    }
}