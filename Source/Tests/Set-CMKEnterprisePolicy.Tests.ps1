[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Set-CMKEnterprisePolicy Tests' {
    BeforeAll {
        $script:testSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:testResourceGroup = "test-rg"
        $script:testPolicyName = "test-cmk-policy"
        $script:testPolicyArmId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:testPolicyName"
        $script:testKeyVaultId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.KeyVault/vaults/myVault"
        $script:newKeyVaultId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.KeyVault/vaults/newVault"

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyArmId
            Name = $script:testPolicyName
            Kind = "Encryption"
            Location = "unitedstates"
            Properties = [PSCustomObject]@{
                encryption = [PSCustomObject]@{
                    keyVault = [PSCustomObject]@{
                        id = $script:testKeyVaultId
                        key = [PSCustomObject]@{ name = "currentKey"; version = "currentVersion" }
                    }
                }
            }
        }

        $script:mockIdentityPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyArmId
            Name = $script:testPolicyName
            Kind = "Identity"
            Location = "unitedstates"
        }

        $script:mockBody = @{ "resources" = @(@{ "type" = "Microsoft.PowerPlatform/enterprisePolicies" }) }

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-AzContext {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock New-EnterprisePolicyBody { return $script:mockBody } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-EnterprisePolicy { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Updating specific fields' {
        BeforeAll {
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should update only the key version and keep other values' {
            Set-CMKEnterprisePolicy -PolicyResourceId $script:testPolicyArmId -KeyVersion "newVersion"

            Should -Invoke New-EnterprisePolicyBody -Times 1 -ParameterFilter {
                $KeyVaultId -eq $script:testKeyVaultId -and
                $KeyName -eq "currentKey" -and
                $KeyVersion -eq "newVersion"
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should update all provided values' {
            Set-CMKEnterprisePolicy -PolicyResourceId $script:testPolicyArmId -KeyVaultId $script:newKeyVaultId -KeyName "newKey" -KeyVersion "newVersion"

            Should -Invoke New-EnterprisePolicyBody -Times 1 -ParameterFilter {
                $KeyVaultId -eq $script:newKeyVaultId -and
                $KeyName -eq "newKey" -and
                $KeyVersion -eq "newVersion"
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return the updated policy' {
            $result = Set-CMKEnterprisePolicy -PolicyResourceId $script:testPolicyArmId -KeyName "newKey"
            $result.Name | Should -Be $script:testPolicyName
        }
    }

    Context 'Error handling' {
        It 'Should throw when no updates are provided' {
            { Set-CMKEnterprisePolicy -PolicyResourceId $script:testPolicyArmId } | Should -Throw "*No updates provided*"
        }

        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            { Set-CMKEnterprisePolicy -PolicyResourceId $script:testPolicyArmId -KeyName "newKey" } | Should -Throw "*Failed to connect to Azure*"
        }

        It 'Should throw when policy is not found' {
            Mock Get-EnterprisePolicy { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            { Set-CMKEnterprisePolicy -PolicyResourceId $script:testPolicyArmId -KeyName "newKey" } | Should -Throw "*No enterprise policy found*"
        }

        It 'Should throw when policy is not an Encryption policy' {
            Mock Get-EnterprisePolicy { return $script:mockIdentityPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            { Set-CMKEnterprisePolicy -PolicyResourceId $script:testPolicyArmId -KeyName "newKey" } | Should -Throw "*not a CMK (Encryption) policy*"
        }
    }
}
