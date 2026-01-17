BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1 -Module
}

Describe 'AzHelper Tests' {
    InModuleScope 'Microsoft.PowerPlatform.EnterprisePolicies' {
        BeforeAll{
            Mock Write-Host {}
            Mock Write-Verbose {}
            Mock Start-Sleep {}
        }

        Context 'Register-ResourceProvider' {
            It 'Returns true when provider is already registered' {
                Mock Get-AzResourceProvider {
                    return [PSCustomObject]@{
                        ProviderNamespace = "Microsoft.PowerPlatform"
                        RegistrationState = "Registered"
                    }
                }

                $result = Register-ResourceProvider -ProviderNamespace "Microsoft.PowerPlatform"

                $result | Should -Be $true
                Should -Invoke Get-AzResourceProvider -Times 1
            }

            It 'Registers provider when not registered and returns true immediately if registered' {
                Mock Get-AzResourceProvider {
                    return [PSCustomObject]@{
                        ProviderNamespace = "Microsoft.Network"
                        RegistrationState = "NotRegistered"
                    }
                }
                Mock Register-AzResourceProvider {
                    return [PSCustomObject]@{
                        ProviderNamespace = "Microsoft.Network"
                        RegistrationState = "Registered"
                    }
                }

                $result = Register-ResourceProvider -ProviderNamespace "Microsoft.Network"

                $result | Should -Be $true
                Should -Invoke Get-AzResourceProvider -Times 1
                Should -Invoke Register-AzResourceProvider -Times 1
            }

            It 'Polls for registration completion when state is Registering' {
                $script:callCount = 0
                Mock Get-AzResourceProvider {
                    if ($script:callCount -eq 0) {
                        $script:callCount++
                        return [PSCustomObject]@{
                            ProviderNamespace = "Microsoft.PowerPlatform"
                            RegistrationState = "NotRegistered"
                        }
                    }
                    elseif ($script:callCount -eq 1) {
                        $script:callCount++
                        return [PSCustomObject]@{
                            ProviderNamespace = "Microsoft.PowerPlatform"
                            RegistrationState = "Registering"
                        }
                    }
                    else {
                        return [PSCustomObject]@{
                            ProviderNamespace = "Microsoft.PowerPlatform"
                            RegistrationState = "Registered"
                        }
                    }
                }
                Mock Register-AzResourceProvider {
                    return [PSCustomObject]@{
                        ProviderNamespace = "Microsoft.PowerPlatform"
                        RegistrationState = "Registering"
                    }
                }

                $result = Register-ResourceProvider -ProviderNamespace "Microsoft.PowerPlatform" -PollIntervalSeconds 1

                $result | Should -Be $true
                Should -Invoke Start-Sleep
            }

            It 'Returns false when registration times out' {
                $script:timeoutCallCount = 0
                Mock Get-AzResourceProvider {
                    if ($script:timeoutCallCount -eq 0) {
                        $script:timeoutCallCount++
                        return [PSCustomObject]@{
                            ProviderNamespace = "Microsoft.PowerPlatform"
                            RegistrationState = "NotRegistered"
                        }
                    }
                    else {
                        return [PSCustomObject]@{
                            ProviderNamespace = "Microsoft.PowerPlatform"
                            RegistrationState = "Registering"
                        }
                    }
                }
                Mock Register-AzResourceProvider {
                    return [PSCustomObject]@{
                        ProviderNamespace = "Microsoft.PowerPlatform"
                        RegistrationState = "Registering"
                    }
                }

                $result = Register-ResourceProvider -ProviderNamespace "Microsoft.PowerPlatform" -MaxWaitTimeSeconds 2 -PollIntervalSeconds 1

                $result | Should -Be $false
            }

            It 'Returns false when Register-AzResourceProvider returns null' {
                Mock Get-AzResourceProvider {
                    return [PSCustomObject]@{
                        ProviderNamespace = "Microsoft.PowerPlatform"
                        RegistrationState = "NotRegistered"
                    }
                }
                Mock Register-AzResourceProvider { return $null }

                $result = Register-ResourceProvider -ProviderNamespace "Microsoft.PowerPlatform"

                $result | Should -Be $false
            }

            It 'Returns false when Register-AzResourceProvider has no RegistrationState' {
                Mock Get-AzResourceProvider {
                    return [PSCustomObject]@{
                        ProviderNamespace = "Microsoft.PowerPlatform"
                        RegistrationState = "NotRegistered"
                    }
                }
                Mock Register-AzResourceProvider {
                    return [PSCustomObject]@{
                        ProviderNamespace = "Microsoft.PowerPlatform"
                    }
                }

                $result = Register-ResourceProvider -ProviderNamespace "Microsoft.PowerPlatform"

                $result | Should -Be $false
            }

            It 'Returns false when Get-AzResourceProvider throws exception' {
                Mock Get-AzResourceProvider { throw "Network error" }

                $result = Register-ResourceProvider -ProviderNamespace "Microsoft.PowerPlatform"

                $result | Should -Be $false
            }

            It 'Returns false when Register-AzResourceProvider throws exception' {
                Mock Get-AzResourceProvider {
                    return [PSCustomObject]@{
                        ProviderNamespace = "Microsoft.PowerPlatform"
                        RegistrationState = "NotRegistered"
                    }
                }
                Mock Register-AzResourceProvider { throw "Registration failed" }

                $result = Register-ResourceProvider -ProviderNamespace "Microsoft.PowerPlatform"

                $result | Should -Be $false
            }

            It 'Accepts custom MaxWaitTimeSeconds parameter' {
                $script:customTimeoutCallCount = 0
                Mock Get-AzResourceProvider {
                    if ($script:customTimeoutCallCount -eq 0) {
                        $script:customTimeoutCallCount++
                        return [PSCustomObject]@{
                            ProviderNamespace = "Microsoft.PowerPlatform"
                            RegistrationState = "NotRegistered"
                        }
                    }
                    else {
                        return [PSCustomObject]@{
                            ProviderNamespace = "Microsoft.PowerPlatform"
                            RegistrationState = "Registering"
                        }
                    }
                }
                Mock Register-AzResourceProvider {
                    return [PSCustomObject]@{
                        ProviderNamespace = "Microsoft.PowerPlatform"
                        RegistrationState = "Registering"
                    }
                }

                $result = Register-ResourceProvider -ProviderNamespace "Microsoft.PowerPlatform" -MaxWaitTimeSeconds 5 -PollIntervalSeconds 1

                $result | Should -Be $false
            }
        }

        Context 'Register-ProviderFeature' {
            It 'Returns true when feature is already registered' {
                Mock Get-AzProviderFeature {
                    return [PSCustomObject]@{
                        FeatureName = "enterprisePoliciesPreview"
                        ProviderName = "Microsoft.PowerPlatform"
                        RegistrationState = "Registered"
                    }
                }

                $result = Register-ProviderFeature -FeatureName "enterprisePoliciesPreview" -ProviderNamespace "Microsoft.PowerPlatform"

                $result | Should -Be $true
                Should -Invoke Get-AzProviderFeature -Times 1
            }

            It 'Registers feature when not registered' {
                Mock Get-AzProviderFeature { return $null }
                Mock Register-AzProviderFeature {
                    return [PSCustomObject]@{
                        FeatureName = "enterprisePoliciesPreview"
                        ProviderName = "Microsoft.PowerPlatform"
                        RegistrationState = "Registered"
                    }
                }

                $result = Register-ProviderFeature -FeatureName "enterprisePoliciesPreview" -ProviderNamespace "Microsoft.PowerPlatform"

                $result | Should -Be $true
                Should -Invoke Register-AzProviderFeature -Times 1
            }

            It 'Registers feature when registration state is not Registered' {
                Mock Get-AzProviderFeature {
                    return [PSCustomObject]@{
                        FeatureName = "enterprisePoliciesPreview"
                        ProviderName = "Microsoft.PowerPlatform"
                        RegistrationState = "NotRegistered"
                    }
                }
                Mock Register-AzProviderFeature {
                    return [PSCustomObject]@{
                        FeatureName = "enterprisePoliciesPreview"
                        ProviderName = "Microsoft.PowerPlatform"
                        RegistrationState = "Registering"
                    }
                }

                $result = Register-ProviderFeature -FeatureName "enterprisePoliciesPreview" -ProviderNamespace "Microsoft.PowerPlatform"

                $result | Should -Be $true
            }

            It 'Returns false when Register-AzProviderFeature returns null' {
                Mock Get-AzProviderFeature { return $null }
                Mock Register-AzProviderFeature { return $null }

                $result = Register-ProviderFeature -FeatureName "enterprisePoliciesPreview" -ProviderNamespace "Microsoft.PowerPlatform"

                $result | Should -Be $false
            }

            It 'Returns false when Register-AzProviderFeature has no RegistrationState' {
                Mock Get-AzProviderFeature { return $null }
                Mock Register-AzProviderFeature {
                    return [PSCustomObject]@{
                        FeatureName = "enterprisePoliciesPreview"
                        ProviderName = "Microsoft.PowerPlatform"
                    }
                }

                $result = Register-ProviderFeature -FeatureName "enterprisePoliciesPreview" -ProviderNamespace "Microsoft.PowerPlatform"

                $result | Should -Be $false
            }

            It 'Returns false when Get-AzProviderFeature throws exception' {
                Mock Get-AzProviderFeature { throw "Network error" }

                $result = Register-ProviderFeature -FeatureName "enterprisePoliciesPreview" -ProviderNamespace "Microsoft.PowerPlatform"

                $result | Should -Be $false
            }

            It 'Returns false when Register-AzProviderFeature throws exception' {
                Mock Get-AzProviderFeature { return $null }
                Mock Register-AzProviderFeature { throw "Registration failed" }

                $result = Register-ProviderFeature -FeatureName "enterprisePoliciesPreview" -ProviderNamespace "Microsoft.PowerPlatform"

                $result | Should -Be $false
            }
        }

        Context 'Initialize-SubscriptionForPowerPlatform' {
            It 'Returns true when subscription is already validated' {
                Mock Test-SubscriptionValidated { return $true }
                Mock Register-ResourceProvider { return $true }
                Mock Register-ProviderFeature { return $true }
                Mock Add-ValidatedSubscriptionToCache {}

                $result = Initialize-SubscriptionForPowerPlatform -SubscriptionId "sub-123"

                $result | Should -Be $true
                Should -Invoke Test-SubscriptionValidated -Times 1
                Should -Invoke Register-ResourceProvider -Times 0
                Should -Invoke Register-ProviderFeature -Times 0
                Should -Invoke Add-ValidatedSubscriptionToCache -Times 0
            }

            It 'Registers all required providers and features for new subscription' {
                Mock Test-SubscriptionValidated { return $false }
                Mock Register-ResourceProvider { return $true }
                Mock Register-ProviderFeature { return $true }
                Mock Add-ValidatedSubscriptionToCache {}

                $result = Initialize-SubscriptionForPowerPlatform -SubscriptionId "sub-456"

                $result | Should -Be $true
                Should -Invoke Register-ResourceProvider -Times 2
                Should -Invoke Register-ProviderFeature -Times 1
                Should -Invoke Add-ValidatedSubscriptionToCache -Times 1
            }

            It 'Returns false when Microsoft.Network registration fails' {
                Mock Test-SubscriptionValidated { return $false }
                $script:networkCallCount = 0
                Mock Register-ResourceProvider { 
                    $script:networkCallCount++
                    if ($script:networkCallCount -eq 1) {
                        return $false
                    }
                    return $true
                }
                Mock Register-ProviderFeature { return $true }
                Mock Add-ValidatedSubscriptionToCache {}

                $result = Initialize-SubscriptionForPowerPlatform -SubscriptionId "sub-789"

                $result | Should -Be $false
                Should -Invoke Add-ValidatedSubscriptionToCache -Times 0
            }

            It 'Returns false when Microsoft.PowerPlatform registration fails' {
                Mock Test-SubscriptionValidated { return $false }
                $script:platformCallCount = 0
                Mock Register-ResourceProvider { 
                    $script:platformCallCount++
                    if ($script:platformCallCount -eq 2) {
                        return $false
                    }
                    return $true
                }
                Mock Register-ProviderFeature { return $true }
                Mock Add-ValidatedSubscriptionToCache {}

                $result = Initialize-SubscriptionForPowerPlatform -SubscriptionId "sub-abc"

                $result | Should -Be $false
                Should -Invoke Add-ValidatedSubscriptionToCache -Times 0
            }

            It 'Returns false when feature registration fails' {
                Mock Test-SubscriptionValidated { return $false }
                Mock Register-ResourceProvider { return $true }
                Mock Register-ProviderFeature { return $false }
                Mock Add-ValidatedSubscriptionToCache {}

                $result = Initialize-SubscriptionForPowerPlatform -SubscriptionId "sub-def"

                $result | Should -Be $false
                Should -Invoke Add-ValidatedSubscriptionToCache -Times 0
            }

            It 'Adds subscription to cache after successful initialization' {
                Mock Test-SubscriptionValidated { return $false }
                Mock Register-ResourceProvider { return $true }
                Mock Register-ProviderFeature { return $true }
                Mock Add-ValidatedSubscriptionToCache {}
                $subscriptionId = "sub-ghi"

                $result = Initialize-SubscriptionForPowerPlatform -SubscriptionId $subscriptionId

                $result | Should -Be $true
                Should -Invoke Add-ValidatedSubscriptionToCache -Times 1
            }
        }

        Context 'New-EnterprisePolicyBody' {
            It 'Creates NetworkInjection policy body with single VNet' {
                $vnet = [PSCustomObject]@{ ResourceId = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet" }
                $vnetInfo = [VnetInformation]::new($vnet, "subnet1")

                $result = New-EnterprisePolicyBody -PolicyType ([PolicyType]::NetworkInjection) -PolicyLocation "unitedstates" -PolicyName "testPolicy" -VnetInformation @($vnetInfo)

                $result.resources[0].kind | Should -Be "NetworkInjection"
                $result.resources[0].name | Should -Be "testPolicy"
                $result.resources[0].location | Should -Be "unitedstates"
                $result.resources[0].properties.networkInjection.virtualNetworks.Count | Should -Be 1
            }

            It 'Creates NetworkInjection policy body with paired VNets' {
                $vnet1 = [PSCustomObject]@{ ResourceId = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet1" }
                $vnet2 = [PSCustomObject]@{ ResourceId = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet2" }
                $vnetInfo = @(
                    [VnetInformation]::new($vnet1, "subnet1"),
                    [VnetInformation]::new($vnet2, "subnet2")
                )

                $result = New-EnterprisePolicyBody -PolicyType ([PolicyType]::NetworkInjection) -PolicyLocation "unitedstates" -PolicyName "testPolicy" -VnetInformation $vnetInfo

                $result.resources[0].properties.networkInjection.virtualNetworks.Count | Should -Be 2
            }

            It 'Creates Encryption policy body with KeyVault info' {
                $result = New-EnterprisePolicyBody -PolicyType ([PolicyType]::Encryption) -PolicyLocation "unitedstates" -PolicyName "testPolicy" -KeyVaultId "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/vault" -KeyName "mykey" -KeyVersion "1.0"

                $result.resources[0].kind | Should -Be "Encryption"
                $result.resources[0].properties.encryption.keyVault.id | Should -Be "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/vault"
                $result.resources[0].properties.encryption.keyVault.key.name | Should -Be "mykey"
            }

            It 'Creates Identity policy body' {
                $result = New-EnterprisePolicyBody -PolicyType ([PolicyType]::Identity) -PolicyLocation "unitedstates" -PolicyName "testPolicy"

                $result.resources[0].kind | Should -Be "Identity"
                $result.resources[0].identity.type | Should -Be "SystemAssigned"
            }
        }

        Context 'Set-EnterprisePolicy' {
            It 'Returns true when deployment succeeds' {
                Mock New-TemporaryFile { return [PSCustomObject]@{ FullName = "C:\temp\test.json" } }
                Mock Out-File {}
                Mock Remove-Item {}
                Mock New-AzResourceGroupDeployment {
                    return [PSCustomObject]@{ ProvisioningState = "Succeeded" }
                }

                $body = @{ resources = @() }
                $result = Set-EnterprisePolicy -ResourceGroup "test-rg" -Body $body

                $result | Should -Be $true
            }

            It 'Returns false when deployment fails' {
                Mock New-TemporaryFile { return [PSCustomObject]@{ FullName = "C:\temp\test.json" } }
                Mock Out-File {}
                Mock Remove-Item {}
                Mock Write-Error {}
                Mock New-AzResourceGroupDeployment {
                    return [PSCustomObject]@{ ProvisioningState = "Failed" }
                }

                $body = @{ resources = @() }
                $result = Set-EnterprisePolicy -ResourceGroup "test-rg" -Body $body

                $result | Should -Be $false
            }
        }

        Context 'Get-EnterprisePolicy' {
            It 'Returns policy resource' {
                $mockPolicy = [PSCustomObject]@{
                    ResourceId = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.PowerPlatform/enterprisePolicies/policy"
                    Name = "policy"
                    Properties = @{}
                }
                Mock Get-AzResource { return $mockPolicy }

                $result = Get-EnterprisePolicy -PolicyArmId $mockPolicy.ResourceId

                $result.Name | Should -Be "policy"
                Should -Invoke Get-AzResource -Times 1 -ParameterFilter { $ExpandProperties -eq $true }
            }
        }
    }
}
