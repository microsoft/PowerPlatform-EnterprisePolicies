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
                $script:CacheData.Version | Should -Be "1.0"
                $script:CacheData.SubscriptionsValidated.Count | Should -Be 0
            }

            It 'Loads existing cache from file' {
                # Create a cache file with test data
                $testCache = @{
                    "Version" = "1.0"
                    "SubscriptionsValidated" = @("sub-123", "sub-456")
                }
                New-Item -ItemType Directory -Path (Split-Path $script:TestCachePath) -Force | Out-Null
                $testCache | ConvertTo-Json | Out-File -FilePath $script:TestCachePath -Force
                
                Initialize-Cache
                
                $script:CacheData | Should -Not -BeNullOrEmpty
                $script:CacheData.Version | Should -Be "1.0"
                $script:CacheData.SubscriptionsValidated.Count | Should -Be 2
                $script:CacheData.SubscriptionsValidated | Should -Contain "sub-123"
                $script:CacheData.SubscriptionsValidated | Should -Contain "sub-456"
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
    }
}
