BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'ValidateAzureResourceIdAttribute Tests' {
    BeforeAll {
        $script:validSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:validResourceGroup = "test-rg"
        $script:validPolicyName = "test-policy"
        $script:validVnetName = "test-vnet"

        $script:validEnterprisePolicyId = "/subscriptions/$script:validSubscriptionId/resourceGroups/$script:validResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:validPolicyName"
        $script:validVnetId = "/subscriptions/$script:validSubscriptionId/resourceGroups/$script:validResourceGroup/providers/Microsoft.Network/virtualNetworks/$script:validVnetName"
    }

    Context 'Valid resource IDs' {
        It 'Should accept valid enterprise policy resource ID' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" -Parameters @{ resourceId = $script:validEnterprisePolicyId } {
                param($resourceId)
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate($resourceId, $null) } | Should -Not -Throw
            }
        }

        It 'Should accept valid virtual network resource ID' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" -Parameters @{ resourceId = $script:validVnetId } {
                param($resourceId)
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.Network/virtualNetworks")
                { $attribute.Validate($resourceId, $null) } | Should -Not -Throw
            }
        }

        It 'Should accept resource ID with lowercase GUID' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                $lowercaseId = "/subscriptions/abcdef12-abcd-abcd-abcd-abcdef123456/resourceGroups/rg/providers/Microsoft.PowerPlatform/enterprisePolicies/policy"
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate($lowercaseId, $null) } | Should -Not -Throw
            }
        }

        It 'Should accept resource ID with uppercase GUID' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                $uppercaseId = "/subscriptions/ABCDEF12-ABCD-ABCD-ABCD-ABCDEF123456/resourceGroups/rg/providers/Microsoft.PowerPlatform/enterprisePolicies/policy"
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate($uppercaseId, $null) } | Should -Not -Throw
            }
        }

        It 'Should accept resource ID with mixed case GUID' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                $mixedCaseId = "/subscriptions/AbCdEf12-AbCd-AbCd-AbCd-AbCdEf123456/resourceGroups/rg/providers/Microsoft.PowerPlatform/enterprisePolicies/policy"
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate($mixedCaseId, $null) } | Should -Not -Throw
            }
        }
    }

    Context 'Null or empty values' {
        It 'Should reject null value' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate($null, $null) } | Should -Throw "*cannot be null or empty*"
            }
        }

        It 'Should reject empty string' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate("", $null) } | Should -Throw "*cannot be null or empty*"
            }
        }

        It 'Should reject whitespace string' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate("   ", $null) } | Should -Throw "*cannot be null or empty*"
            }
        }
    }

    Context 'Trailing slash' {
        It 'Should reject resource ID with trailing slash' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" -Parameters @{ resourceId = $script:validEnterprisePolicyId } {
                param($resourceId)
                $idWithTrailingSlash = "$resourceId/"
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate($idWithTrailingSlash, $null) } | Should -Throw "*trailing slash*"
            }
        }
    }

    Context 'Invalid GUID format' {
        It 'Should reject GUID with wrong length' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                $shortGuidId = "/subscriptions/1234-1234-1234-1234/resourceGroups/rg/providers/Microsoft.PowerPlatform/enterprisePolicies/policy"
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate($shortGuidId, $null) } | Should -Throw "*Invalid resource ID format*"
            }
        }

        It 'Should reject GUID with invalid characters' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                $invalidCharsId = "/subscriptions/1234567g-1234-1234-1234-123456789012/resourceGroups/rg/providers/Microsoft.PowerPlatform/enterprisePolicies/policy"
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate($invalidCharsId, $null) } | Should -Throw "*Invalid resource ID format*"
            }
        }

        It 'Should reject GUID without dashes' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                $noDashesId = "/subscriptions/12345678123412341234123456789012/resourceGroups/rg/providers/Microsoft.PowerPlatform/enterprisePolicies/policy"
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate($noDashesId, $null) } | Should -Throw "*Invalid resource ID format*"
            }
        }

        It 'Should reject GUID with extra segment' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                $extraSegmentId = "/subscriptions/12345678-1234-1234-1234-1234-123456789012/resourceGroups/rg/providers/Microsoft.PowerPlatform/enterprisePolicies/policy"
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate($extraSegmentId, $null) } | Should -Throw "*Invalid resource ID format*"
            }
        }
    }

    Context 'Invalid resource ID structure' {
        It 'Should reject resource ID without subscriptions prefix' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                $noSubscriptionsId = "/resourceGroups/rg/providers/Microsoft.PowerPlatform/enterprisePolicies/policy"
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate($noSubscriptionsId, $null) } | Should -Throw "*Invalid resource ID format*"
            }
        }

        It 'Should reject resource ID without resourceGroups' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" -Parameters @{ subscriptionId = $script:validSubscriptionId } {
                param($subscriptionId)
                $noResourceGroupsId = "/subscriptions/$subscriptionId/providers/Microsoft.PowerPlatform/enterprisePolicies/policy"
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate($noResourceGroupsId, $null) } | Should -Throw "*Invalid resource ID format*"
            }
        }

        It 'Should reject plain string' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" {
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate("invalid-resource-id", $null) } | Should -Throw "*Invalid resource ID format*"
            }
        }

        It 'Should reject resource ID without resource name' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" -Parameters @{ subscriptionId = $script:validSubscriptionId } {
                param($subscriptionId)
                $noNameId = "/subscriptions/$subscriptionId/resourceGroups/rg/providers/Microsoft.PowerPlatform/enterprisePolicies/"
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.PowerPlatform/enterprisePolicies")
                { $attribute.Validate($noNameId, $null) } | Should -Throw "*trailing slash*"
            }
        }
    }

    Context 'Wrong resource type' {
        It 'Should reject enterprise policy ID when expecting virtual network' {
            InModuleScope "Microsoft.PowerPlatform.EnterprisePolicies" -Parameters @{ resourceId = $script:validEnterprisePolicyId } {
                param($resourceId)
                $attribute = [ValidateAzureResourceIdAttribute]::new("Microsoft.Network/virtualNetworks")
                { $attribute.Validate($resourceId, $null) } | Should -Throw "*Invalid resource ID format*"
            }
        }
    }
}
