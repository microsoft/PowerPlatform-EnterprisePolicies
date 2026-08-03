BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1 -Module
}

Describe 'CacheMethods Tests' {
    InModuleScope 'Microsoft.PowerPlatform.EnterprisePolicies' {
        BeforeAll{
            Mock Write-Host {}
            Mock Write-Verbose {}
            
            # Store original cache values to restore later
            $script:OriginalCachePath = $script:CachePath
            $script:OriginalCacheData = $script:CacheData
            
            # Set up a temporary cache path for testing
            $script:TestCachePath = Join-Path $TestDrive 'TestCache\config.json'
            $script:CachePath = $script:TestCachePath
        }

        AfterAll {
            # Restore original cache values
            $script:CachePath = $script:OriginalCachePath
            $script:CacheData = $script:OriginalCacheData
        }

        BeforeEach {
            # Clean up cache before each test
            $script:CacheData = $null
            if (Test-Path $script:TestCachePath) {
                Remove-Item $script:TestCachePath -Force
            }
        }

        Context 'Initialize-Cache' {
            It 'Initializes new cache when file does not exist' {
                Initialize-Cache

                $script:CacheData | Should -Not -BeNullOrEmpty
                $script:CacheData.Version | Should -Be "1.1"
                $script:CacheData.SubscriptionsValidated.Count | Should -Be 0
                $script:CacheData.PSObject.Properties.Name | Should -Contain "RegionCache"
            }

            It 'Loads existing cache from file and upgrades from 1.0 to 1.1' {
                # Create a v1.0 cache file (no RegionCache)
                $testCache = @{
                    "Version" = "1.0"
                    "SubscriptionsValidated" = @("sub-123", "sub-456")
                }
                New-Item -ItemType Directory -Path (Split-Path $script:TestCachePath) -Force | Out-Null
                $testCache | ConvertTo-Json | Out-File -FilePath $script:TestCachePath -Force

                Initialize-Cache

                $script:CacheData | Should -Not -BeNullOrEmpty
                $script:CacheData.Version | Should -Be "1.1"
                $script:CacheData.SubscriptionsValidated.Count | Should -Be 2
                $script:CacheData.SubscriptionsValidated | Should -Contain "sub-123"
                $script:CacheData.SubscriptionsValidated | Should -Contain "sub-456"
                $script:CacheData.PSObject.Properties.Name | Should -Contain "RegionCache"
            }

            It 'Loads existing 1.1 cache without modification' {
                $testCache = [PSCustomObject]@{
                    "Version" = "1.1"
                    "SubscriptionsValidated" = @("sub-789")
                    "RegionCache" = [PSCustomObject]@{}
                }
                New-Item -ItemType Directory -Path (Split-Path $script:TestCachePath) -Force | Out-Null
                $testCache | ConvertTo-Json | Out-File -FilePath $script:TestCachePath -Force

                Initialize-Cache

                $script:CacheData.Version | Should -Be "1.1"
                $script:CacheData.SubscriptionsValidated | Should -Contain "sub-789"
                $script:CacheData.PSObject.Properties.Name | Should -Contain "RegionCache"
            }

            It 'Handles empty cache file gracefully' {
                New-Item -ItemType Directory -Path (Split-Path $script:TestCachePath) -Force | Out-Null
                "" | Out-File -FilePath $script:TestCachePath -Force

                { Initialize-Cache } | Should -Not -Throw
            }
        }

        Context 'Save-Cache' {
            It 'Creates cache directory if it does not exist' {
                $script:CacheData = @{
                    "Version" = "1.0"
                    "SubscriptionsValidated" = @()
                }
                
                $cacheDir = Split-Path $script:TestCachePath
                if (Test-Path $cacheDir) {
                    Remove-Item $cacheDir -Recurse -Force
                }
                
                Save-Cache
                
                Test-Path $cacheDir | Should -Be $true
                Test-Path $script:TestCachePath | Should -Be $true
            }

            It 'Saves cache data to file' {
                $script:CacheData = @{
                    "Version" = "1.0"
                    "SubscriptionsValidated" = @("sub-789")
                }
                
                Save-Cache
                
                Test-Path $script:TestCachePath | Should -Be $true
                $savedData = Get-Content $script:TestCachePath | ConvertFrom-Json
                $savedData.Version | Should -Be "1.0"
                $savedData.SubscriptionsValidated | Should -Contain "sub-789"
            }

            It 'Overwrites existing cache file' {
                # Create initial cache
                $script:CacheData = @{
                    "Version" = "1.0"
                    "SubscriptionsValidated" = @("sub-old")
                }
                Save-Cache
                
                # Update and save again
                $script:CacheData = @{
                    "Version" = "1.0"
                    "SubscriptionsValidated" = @("sub-new")
                }
                Save-Cache
                
                $savedData = Get-Content $script:TestCachePath | ConvertFrom-Json
                $savedData.SubscriptionsValidated | Should -Not -Contain "sub-old"
                $savedData.SubscriptionsValidated | Should -Contain "sub-new"
            }
        }

        Context 'Test-SubscriptionValidated' {
            BeforeEach {
                Initialize-Cache
            }

            It 'Returns false when subscription is not in cache' {
                Test-SubscriptionValidated -SubscriptionId "sub-notfound" | Should -Be $false
            }

            It 'Returns true when subscription is in cache' {
                $script:CacheData.SubscriptionsValidated += "sub-exists"
                
                Test-SubscriptionValidated -SubscriptionId "sub-exists" | Should -Be $true
            }

            It 'Is not case-sensitive when checking subscription ID' {
                $script:CacheData.SubscriptionsValidated += "sub-lowercase"
                
                Test-SubscriptionValidated -SubscriptionId "sub-lowercase" | Should -Be $true
                Test-SubscriptionValidated -SubscriptionId "SUB-LOWERCASE" | Should -Be $true
            }

            It 'Handles GUID format subscription IDs' {
                $subId = "12345678-1234-1234-1234-123456789012"
                $script:CacheData.SubscriptionsValidated += $subId
                
                Test-SubscriptionValidated -SubscriptionId $subId | Should -Be $true
            }

            It 'Throws when SubscriptionId is null or empty' {
                { Test-SubscriptionValidated -SubscriptionId $null } | Should -Throw
                { Test-SubscriptionValidated -SubscriptionId "" } | Should -Throw
            }
        }

        Context 'Get-EnvironmentRegionFromCache' {
            BeforeEach {
                Initialize-Cache
                Mock Get-EnvironmentRegion { return "westus" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            }

            It 'Calls Get-EnvironmentRegion on cache miss and caches result' {
                $result = Get-EnvironmentRegionFromCache -EnvironmentId "env-123" -Endpoint ([PPEndpoint]::Prod)

                $result | Should -Be "westus"
                Should -Invoke Get-EnvironmentRegion -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            }

            It 'Returns cached value without calling Get-EnvironmentRegion' {
                # First call populates the cache
                Get-EnvironmentRegionFromCache -EnvironmentId "env-123" -Endpoint ([PPEndpoint]::Prod)
                # Second call should use cache
                $result = Get-EnvironmentRegionFromCache -EnvironmentId "env-123" -Endpoint ([PPEndpoint]::Prod)

                $result | Should -Be "westus"
                Should -Invoke Get-EnvironmentRegion -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            }

            It 'Uses separate cache entries for different endpoints' {
                Mock Get-EnvironmentRegion { return "westus" } -ParameterFilter { $Endpoint -eq [PPEndpoint]::Prod } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
                Mock Get-EnvironmentRegion { return "usgovvirginia" } -ParameterFilter { $Endpoint -eq [PPEndpoint]::usgovhigh } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

                $result1 = Get-EnvironmentRegionFromCache -EnvironmentId "env-123" -Endpoint ([PPEndpoint]::Prod)
                $result2 = Get-EnvironmentRegionFromCache -EnvironmentId "env-123" -Endpoint ([PPEndpoint]::usgovhigh)

                $result1 | Should -Be "westus"
                $result2 | Should -Be "usgovvirginia"
                Should -Invoke Get-EnvironmentRegion -Times 2 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            }

            It 'Refreshes expired entries' {
                # Populate cache with an expired entry
                $cacheKey = "env-123|Prod"
                $script:CacheData.RegionCache | Add-Member -NotePropertyName $cacheKey -NotePropertyValue ([PSCustomObject]@{
                    Region = "oldregion"
                    Expiry = [DateTime]::UtcNow.AddHours(-1).ToString("o")
                })

                $result = Get-EnvironmentRegionFromCache -EnvironmentId "env-123" -Endpoint ([PPEndpoint]::Prod)

                $result | Should -Be "westus"
                Should -Invoke Get-EnvironmentRegion -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            }

            It 'Refreshes expired entries after disk roundtrip' {
                # Populate cache with an expired entry and save to disk
                $cacheKey = "env-123|prod"
                $script:CacheData.RegionCache | Add-Member -NotePropertyName $cacheKey -NotePropertyValue ([PSCustomObject]@{
                    Region = "oldregion"
                    Expiry = [DateTime]::UtcNow.AddHours(-1).ToString("o")
                })
                Save-Cache

                # Reload from disk (ConvertFrom-Json in PS Core converts date strings to DateTime)
                Initialize-Cache

                $result = Get-EnvironmentRegionFromCache -EnvironmentId "env-123" -Endpoint ([PPEndpoint]::Prod)

                $result | Should -Be "westus"
                Should -Invoke Get-EnvironmentRegion -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            }

            It 'Returns cached value after disk roundtrip when not expired' {
                # First call populates the cache
                Get-EnvironmentRegionFromCache -EnvironmentId "env-123" -Endpoint ([PPEndpoint]::Prod)
                # Save and reload from disk
                Save-Cache
                Initialize-Cache

                # Second call should use cache loaded from disk
                $result = Get-EnvironmentRegionFromCache -EnvironmentId "env-123" -Endpoint ([PPEndpoint]::Prod)

                $result | Should -Be "westus"
                Should -Invoke Get-EnvironmentRegion -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            }

            It 'Passes TenantId through when provided' {
                Mock Get-EnvironmentRegion { return "eastus" } -ParameterFilter { $TenantId -eq "tenant-abc" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

                $result = Get-EnvironmentRegionFromCache -EnvironmentId "env-123" -Endpoint ([PPEndpoint]::Prod) -TenantId "tenant-abc"

                $result | Should -Be "eastus"
                Should -Invoke Get-EnvironmentRegion -Times 1 -ParameterFilter { $TenantId -eq "tenant-abc" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            }
        }

        Context 'Add-ValidatedSubscriptionToCache' {
            BeforeEach {
                Initialize-Cache
            }

            It 'Adds new subscription to cache' {
                Add-ValidatedSubscriptionToCache -SubscriptionId "sub-new"
                
                $script:CacheData.SubscriptionsValidated | Should -Contain "sub-new"
            }

            It 'Saves cache after adding subscription' {
                Add-ValidatedSubscriptionToCache -SubscriptionId "sub-persist"
                
                Test-Path $script:TestCachePath | Should -Be $true
                $savedData = Get-Content $script:TestCachePath | ConvertFrom-Json
                $savedData.SubscriptionsValidated | Should -Contain "sub-persist"
            }

            It 'Does not add duplicate subscriptions' {
                Add-ValidatedSubscriptionToCache -SubscriptionId "sub-duplicate"
                Add-ValidatedSubscriptionToCache -SubscriptionId "sub-duplicate"
                
                $count = ($script:CacheData.SubscriptionsValidated | Where-Object { $_ -eq "sub-duplicate" }).Count
                $count | Should -Be 1
            }

            It 'Throws when SubscriptionId is null or empty' {
                { Add-ValidatedSubscriptionToCache -SubscriptionId $null } | Should -Throw
                { Add-ValidatedSubscriptionToCache -SubscriptionId "" } | Should -Throw
            }

            It 'Handles multiple subscriptions correctly' {
                Add-ValidatedSubscriptionToCache -SubscriptionId "sub-1"
                Add-ValidatedSubscriptionToCache -SubscriptionId "sub-2"
                Add-ValidatedSubscriptionToCache -SubscriptionId "sub-3"

                $script:CacheData.SubscriptionsValidated.Count | Should -Be 3
                $script:CacheData.SubscriptionsValidated | Should -Contain "sub-1"
                $script:CacheData.SubscriptionsValidated | Should -Contain "sub-2"
                $script:CacheData.SubscriptionsValidated | Should -Contain "sub-3"
            }
        }

        Context 'Get-CachedServicePrincipalAuth' {
            BeforeEach {
                Initialize-Cache
            }

            It 'Returns null when service principal auth is not set' {
                Get-CachedServicePrincipalAuth | Should -BeNullOrEmpty
            }

            It 'Stores and retrieves a configuration' {
                $config = [PSCustomObject]@{ Method = "ManagedIdentity"; ClientId = "mi-client-id" }
                Set-CachedConfiguration -Name "ServicePrincipalAuth" -Value $config

                $result = Get-CachedServicePrincipalAuth
                $result.Method | Should -Be "ManagedIdentity"
                $result.ClientId | Should -Be "mi-client-id"
            }

            It 'Persists the configuration to disk' {
                $config = [PSCustomObject]@{ Method = "ManagedIdentity"; ClientId = "persisted-id" }
                Set-CachedConfiguration -Name "ServicePrincipalAuth" -Value $config

                Test-Path $script:TestCachePath | Should -Be $true
                $savedData = Get-Content $script:TestCachePath | ConvertFrom-Json
                $savedData.Configuration.ServicePrincipalAuth.ClientId | Should -Be "persisted-id"
            }

            It 'Round-trips a configuration through disk' {
                $config = [PSCustomObject]@{ Method = "Certificate"; ClientId = "app-id"; TenantId = "tenant-id"; CertificateThumbprint = "THUMB123" }
                Set-CachedConfiguration -Name "ServicePrincipalAuth" -Value $config

                # Reload from disk
                Initialize-Cache

                $result = Get-CachedServicePrincipalAuth
                $result.Method | Should -Be "Certificate"
                $result.CertificateThumbprint | Should -Be "THUMB123"
            }

            It 'Removes the configuration when set to null' {
                Set-CachedConfiguration -Name "ServicePrincipalAuth" -Value ([PSCustomObject]@{ Method = "ManagedIdentity"; ClientId = "mi-client-id" })
                Set-CachedConfiguration -Name "ServicePrincipalAuth" -Value $null

                Get-CachedServicePrincipalAuth | Should -BeNullOrEmpty
            }

            It 'Overwrites an existing configuration' {
                Set-CachedConfiguration -Name "ServicePrincipalAuth" -Value ([PSCustomObject]@{ Method = "ManagedIdentity"; ClientId = "old-id" })
                Set-CachedConfiguration -Name "ServicePrincipalAuth" -Value ([PSCustomObject]@{ Method = "ManagedIdentity"; ClientId = "new-id" })

                (Get-CachedServicePrincipalAuth).ClientId | Should -Be "new-id"
            }

            It 'Handles cache files created before the Configuration feature' {
                # Simulate an old cache without the Configuration key
                $script:CacheData = [PSCustomObject]@{
                    Version = "1.1"
                    SubscriptionsValidated = @()
                    RegionCache = [PSCustomObject]@{}
                }

                Get-CachedServicePrincipalAuth | Should -BeNullOrEmpty
                { Set-CachedConfiguration -Name "ServicePrincipalAuth" -Value ([PSCustomObject]@{ Method = "ManagedIdentity"; ClientId = "mi-client-id" }) } | Should -Not -Throw
                (Get-CachedServicePrincipalAuth).ClientId | Should -Be "mi-client-id"
            }
        }

        Context 'Get-CachedConfiguration and Set-CachedConfiguration' {
            BeforeEach {
                Initialize-Cache
            }

            It 'Returns an empty container when nothing is configured' {
                $all = Get-CachedConfiguration
                # An empty [PSCustomObject]@{} is treated as null/empty by -BeNullOrEmpty,
                # so assert non-null explicitly and that it has no properties.
                $null -ne $all | Should -Be $true
                $all.PSObject.Properties.Name.Count | Should -Be 0
            }

            It 'Returns null for an unset named entry' {
                Get-CachedConfiguration -Name "Missing" | Should -BeNullOrEmpty
            }

            It 'Stores and retrieves a named value' {
                Set-CachedConfiguration -Name "MySetting" -Value "SomeValue"

                Get-CachedConfiguration -Name "MySetting" | Should -Be "SomeValue"
            }

            It 'Returns all stored values when no name is provided' {
                Set-CachedConfiguration -Name "First" -Value "1"
                Set-CachedConfiguration -Name "Second" -Value "2"

                $all = Get-CachedConfiguration
                $all.First | Should -Be "1"
                $all.Second | Should -Be "2"
            }

            It 'Removes a named value when set to null' {
                Set-CachedConfiguration -Name "MySetting" -Value "SomeValue"
                Set-CachedConfiguration -Name "MySetting" -Value $null

                Get-CachedConfiguration -Name "MySetting" | Should -BeNullOrEmpty
            }

            It 'Persists named values to disk' {
                Set-CachedConfiguration -Name "Persisted" -Value "OnDisk"

                Initialize-Cache
                Get-CachedConfiguration -Name "Persisted" | Should -Be "OnDisk"
            }
        }
    }
}
