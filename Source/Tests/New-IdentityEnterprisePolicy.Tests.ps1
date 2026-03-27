[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'New-IdentityEnterprisePolicy Tests' {
    BeforeAll {
        $script:testSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:testResourceGroup = "test-rg"
        $script:testPolicyName = "test-identity-policy"
        $script:testPolicyLocation = "unitedstates"
        $script:testTenantId = "87654321-4321-4321-4321-210987654321"

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:testPolicyName"
            Name = $script:testPolicyName
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
            $result = New-IdentityEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testPolicyName
        }
    }

    Context 'Error handling' {
        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-IdentityEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation } | Should -Throw "*Failed to connect to Azure*"
        }

        It 'Should throw when subscription initialization fails' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Initialize-SubscriptionForPowerPlatform { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-IdentityEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation } | Should -Throw "*Failed to initialize subscription*"
        }

        It 'Should throw when policy deployment fails' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Initialize-SubscriptionForPowerPlatform { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-EnterprisePolicyBody { return $script:mockBody } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Set-EnterprisePolicy { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { New-IdentityEnterprisePolicy `
                -SubscriptionId $script:testSubscriptionId `
                -ResourceGroupName $script:testResourceGroup `
                -PolicyName $script:testPolicyName `
                -PolicyLocation $script:testPolicyLocation } | Should -Throw "*Failed to create Identity Enterprise Policy*"
        }
    }
}
