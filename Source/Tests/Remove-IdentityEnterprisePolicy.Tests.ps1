[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Remove-IdentityEnterprisePolicy Tests' {
    BeforeAll {
        $script:testSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:testResourceGroup = "test-rg"
        $script:testPolicyName = "test-identity-policy"
        $script:testPolicyArmId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/$script:testPolicyName"

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyArmId
            Name = $script:testPolicyName
            Kind = "Identity"
            Properties = @{ systemId = "test-system-id" }
        }

        $script:mockPolicy2 = [PSCustomObject]@{
            ResourceId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/test-policy-2"
            Name = "test-policy-2"
            Kind = "Identity"
            Properties = @{ systemId = "test-system-id-2" }
        }

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-AzContext {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Successful removal by resource ID' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Initialize-SubscriptionForPowerPlatform { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Remove-AzResource {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should remove the policy' {
            Remove-IdentityEnterprisePolicy -PolicyResourceId $script:testPolicyArmId -Force

            Should -Invoke Remove-AzResource -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Multiple policies found' {
        BeforeAll {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Initialize-SubscriptionForPowerPlatform { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return @($script:mockPolicy, $script:mockPolicy2) } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Remove-AzResource {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should not remove and should list policies' {
            Remove-IdentityEnterprisePolicy -SubscriptionId $script:testSubscriptionId -Force

            Should -Invoke Remove-AzResource -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }

    Context 'Error handling' {
        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Remove-IdentityEnterprisePolicy -PolicyResourceId $script:testPolicyArmId -Force } | Should -Throw "*Failed to connect to Azure*"
        }

        It 'Should throw when no policies found' {
            Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Initialize-SubscriptionForPowerPlatform { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            { Remove-IdentityEnterprisePolicy -PolicyResourceId $script:testPolicyArmId -Force } | Should -Throw "*No enterprise policies found*"
        }
    }
}
