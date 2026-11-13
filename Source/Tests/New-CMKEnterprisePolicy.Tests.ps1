[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'New-CMKEnterprisePolicy Tests' {
    BeforeAll {
        $script:testSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:testResourceGroup = "test-rg"
        $script:testPolicyName = "test-cmk-policy"
        $script:testPolicyLocation = "unitedstates"
        $script:testKeyVaultId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.KeyVault/vaults/myVault"
        $script:testKeyName = "myKey"
        $script:testKeyVersion = "0123456789abcdef0123456789abcdef"

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:testPolicyName"
            Name = $script:testPolicyName
            Kind = "Encryption"
            Properties = @{ systemId = "test-system-id" }
        }

        $script:mockBody = @{
            "`$schema" = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
            "contentVersion" = "1.0.0.0"
            "resources" = @(@{ "type" = "Microsoft.PowerPlatform/enterprisePolicies" })
        }

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-AzContext {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Successful policy creation' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Initialize-SubscriptionForPowerPlatform { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-EnterprisePolicyBody { return $script:mockBody } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnterprisePolicy { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should create policy and return PSResource object' {
            $result = New-CMKEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation `
                -KeyVaultId $script:testKeyVaultId `
                -KeyName $script:testKeyName `
                -KeyVersion $script:testKeyVersion

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testPolicyName
        }

        It 'Should pass the key version to the policy body when provided' {
            New-CMKEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation `
                -KeyVaultId $script:testKeyVaultId `
                -KeyName $script:testKeyName `
                -KeyVersion $script:testKeyVersion

            Should -Invoke New-EnterprisePolicyBody -Times 1 -ParameterFilter {
                $KeyVersion -eq $script:testKeyVersion
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should omit the key version when not provided' {
            New-CMKEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation `
                -KeyVaultId $script:testKeyVaultId `
                -KeyName $script:testKeyName

            Should -Invoke New-EnterprisePolicyBody -Times 1 -ParameterFilter {
                -not $PSBoundParameters.ContainsKey('KeyVersion')
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Error handling' {
        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-CMKEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation `
                -KeyVaultId $script:testKeyVaultId `
                -KeyName $script:testKeyName } | Should -Throw "*Failed to connect to Azure*"
        }

        It 'Should throw when subscription initialization fails' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Initialize-SubscriptionForPowerPlatform { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-CMKEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation `
                -KeyVaultId $script:testKeyVaultId `
                -KeyName $script:testKeyName } | Should -Throw "*Failed to initialize subscription*"
        }

        It 'Should throw when policy deployment fails' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Initialize-SubscriptionForPowerPlatform { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-EnterprisePolicyBody { return $script:mockBody } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnterprisePolicy { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-CMKEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation `
                -KeyVaultId $script:testKeyVaultId `
                -KeyName $script:testKeyName } | Should -Throw "*Failed to create CMK Enterprise Policy*"
        }
    }
}
