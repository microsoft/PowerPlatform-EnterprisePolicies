[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1 -Module
}

Describe 'AuthenticationOperations Tests' {
    InModuleScope 'Microsoft.PowerPlatform.EnterprisePolicies' {
        BeforeAll{
            Mock Write-Host {}
            Mock Get-CachedServicePrincipalAuth { return $null }
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

            It 'Uses the first available matching context' {
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

        Context 'Testing Connect-Azure service principal auth' {
            It 'Logs in with a managed identity when configured' {
                $endpoint = [PPEndpoint]::prod
                Mock Get-CachedServicePrincipalAuth { return @{ Method = "ManagedIdentity"; ClientId = "mi-client-id" } }
                Mock Get-AzContext { return $null }
                Mock Connect-AzAccount { return $true } -ParameterFilter { $Identity -and $AccountId -eq "mi-client-id" } -Verifiable

                Connect-Azure -Endpoint $endpoint | Should -Be $true

                Assert-MockCalled Connect-AzAccount -Exactly 1 -ParameterFilter { $Identity -and $AccountId -eq "mi-client-id" }
            }

            It 'Logs in with a certificate service principal using a thumbprint' {
                $endpoint = [PPEndpoint]::prod
                Mock Get-CachedServicePrincipalAuth { return @{ Method = "Certificate"; ClientId = "app-id"; TenantId = "tenant-id"; CertificateThumbprint = "THUMB123" } }
                Mock Get-AzContext { return $null }
                Mock Connect-AzAccount { return $true } -ParameterFilter { $ServicePrincipal -and $ApplicationId -eq "app-id" -and $CertificateThumbprint -eq "THUMB123" } -Verifiable

                Connect-Azure -Endpoint $endpoint | Should -Be $true

                Assert-MockCalled Connect-AzAccount -Exactly 1 -ParameterFilter { $ServicePrincipal -and $CertificateThumbprint -eq "THUMB123" }
            }

            It 'Resolves the certificate thumbprint from a subject name' {
                $endpoint = [PPEndpoint]::prod
                Mock Get-CachedServicePrincipalAuth { return @{ Method = "Certificate"; ClientId = "app-id"; TenantId = "tenant-id"; CertificateSubjectName = "CN=MyCert" } }
                Mock Get-AzContext { return $null }
                Mock Resolve-CertificateThumbprint { return "RESOLVED-THUMB" } -ParameterFilter { $SubjectName -eq "CN=MyCert" }
                Mock Connect-AzAccount { return $true } -ParameterFilter { $CertificateThumbprint -eq "RESOLVED-THUMB" } -Verifiable

                Connect-Azure -Endpoint $endpoint | Should -Be $true

                Assert-MockCalled Resolve-CertificateThumbprint -Exactly 1
                Assert-MockCalled Connect-AzAccount -Exactly 1 -ParameterFilter { $CertificateThumbprint -eq "RESOLVED-THUMB" }
            }

            It 'Reuses an existing matching service principal context' {
                $endpoint = [PPEndpoint]::prod
                Mock Get-CachedServicePrincipalAuth { return @{ Method = "ManagedIdentity"; ClientId = "mi-client-id" } }
                Mock Get-AzContext {
                    return @(
                        [PSCustomObject]@{ Environment = @{ Name = "AzureCloud" }; Account = @{ Id = "mi-client-id"; Tenants = @("tenant1") } }
                    )
                }
                Mock Set-AzContext {}
                Mock Connect-AzAccount { return $true }

                Connect-Azure -Endpoint $endpoint | Should -Be $true

                Assert-MockCalled Set-AzContext -Exactly 1 -ParameterFilter { $Context.Account.Id -eq "mi-client-id" }
                Assert-MockCalled Connect-AzAccount -Exactly 0
            }

            It 'Ignores service principal configuration when Force is specified' {
                $endpoint = [PPEndpoint]::prod
                Mock Get-CachedServicePrincipalAuth { return @{ Method = "ManagedIdentity"; ClientId = "mi-client-id" } }
                Mock Get-AzContext { return $null }
                Mock Connect-AzAccount { return $true } -ParameterFilter { -not $Identity -and -not $ServicePrincipal } -Verifiable

                Connect-Azure -Endpoint $endpoint -Force | Should -Be $true

                Assert-MockCalled Connect-AzAccount -Exactly 1 -ParameterFilter { -not $Identity -and -not $ServicePrincipal }
            }

            It 'Throws when the configured method is unknown' {
                $endpoint = [PPEndpoint]::prod
                Mock Get-CachedServicePrincipalAuth { return @{ Method = "Bogus"; ClientId = "some-id" } }
                Mock Get-AzContext { return $null }

                { Connect-Azure -Endpoint $endpoint } | Should -Throw "*Unknown service principal auth method*"
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

            It 'Re-authenticates and returns token when initial acquisition fails then succeeds' {
                $mockToken = [PSCustomObject]@{ Token = (ConvertTo-SecureString "test-token" -AsPlainText -Force) }
                # Mock returns null first (with SilentlyContinue), then token on second call
                Mock Get-AzAccessToken { return $null } -ParameterFilter { $ErrorAction -eq 'SilentlyContinue' }
                Mock Get-AzAccessToken { return $mockToken } -ParameterFilter { $ErrorAction -ne 'SilentlyContinue' }
                Mock Connect-Azure { return $true }

                $result = Get-AccessToken -Endpoint ([PPEndpoint]::prod) -ResourceUrl "https://api.test.com"

                $result | Should -Not -BeNullOrEmpty
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
                Mock Set-CachedAuthorizationServiceClientId {}
            }

            It 'Returns true on successful connection' {
                Mock Get-PublicClientApplicationBuilder { return $script:mockBuilder }

                $result = New-AuthorizationServiceMsalClient -ClientId "test-client-id" -TenantId "test-tenant-id"

                $result | Should -Be $true
            }

            It 'Resolves ClientId from cache when not provided' {
                Mock Get-CachedAuthorizationServiceClientId { return "cached-client-id" }
                Mock Get-PublicClientApplicationBuilder { return $script:mockBuilder }

                $result = New-AuthorizationServiceMsalClient -TenantId "test-tenant-id"

                $result | Should -Be $true
            }

            It 'Throws when ClientId not provided and not cached' {
                Mock Get-CachedAuthorizationServiceClientId { return $null }

                { New-AuthorizationServiceMsalClient -TenantId "test-tenant-id" } | Should -Throw "*no cached ClientId was found*"
            }

            It 'Caches ClientId when explicitly provided' {
                Mock Get-PublicClientApplicationBuilder { return $script:mockBuilder }

                New-AuthorizationServiceMsalClient -ClientId "my-client-id" -TenantId "test-tenant-id"

                Should -Invoke Set-CachedAuthorizationServiceClientId -Exactly 1 -ParameterFilter { $AuthorizationServiceClientId -eq "my-client-id" }
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
                $script:mockApp | Add-Member -MemberType ScriptMethod -Name 'AcquireTokenInteractive' -Value { $script:capturedInteractiveScopes = $args[0]; return $script:mockInteractiveRequest }
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

                [System.Net.NetworkCredential]::new("", $result).Password | Should -Be "mock-access-token"
            }

            It 'Passes scopes to the interactive request as a string array' {
                # Regression guard: MSAL's AcquireTokenInteractive expects IEnumerable<string>.
                # @("...") is object[], which fails overload resolution, so scopes must be [string[]].
                Mock Get-PublicClientApplicationBuilder { return $script:mockBuilder }
                Mock Get-APIResourceUrl { return "https://api.powerplatform.com/" }

                $script:capturedInteractiveScopes = $null
                New-AuthorizationServiceMsalClient -ClientId "test-client-id" -TenantId "test-tenant-id"
                Get-AuthorizationServiceToken -Endpoint ([PPEndpoint]::Prod) | Out-Null

                $script:capturedInteractiveScopes -is [string[]] | Should -Be $true
                $script:capturedInteractiveScopes[0] | Should -Be "https://api.powerplatform.com/.default"
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
