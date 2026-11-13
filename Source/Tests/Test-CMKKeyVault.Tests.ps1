[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Test-CMKKeyVault Tests' {
    BeforeAll {
        $script:testSubscriptionId = "12345678-1234-1234-1234-123456789012"
        $script:testResourceGroup = "test-rg"
        $script:testKeyVaultName = "myVault"
        $script:testVaultId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.KeyVault/vaults/$script:testKeyVaultName"
        $script:testPolicyArmId = "/subscriptions/$script:testSubscriptionId/resourceGroups/$script:testResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy"
        $script:testPrincipalId = "11111111-1111-1111-1111-111111111111"

        $script:mockKeyVaultRbac = [PSCustomObject]@{
            VaultName = $script:testKeyVaultName
            ResourceId = $script:testVaultId
            EnableSoftDelete = $true
            EnablePurgeProtection = $true
            EnableRbacAuthorization = $true
            AccessPolicies = @()
        }

        $script:mockKeyVaultAccessPolicyValid = [PSCustomObject]@{
            VaultName = $script:testKeyVaultName
            ResourceId = $script:testVaultId
            EnableSoftDelete = $true
            EnablePurgeProtection = $true
            EnableRbacAuthorization = $false
            AccessPolicies = @([PSCustomObject]@{ ObjectId = $script:testPrincipalId; PermissionsToKeys = @("Get", "UnwrapKey", "WrapKey") })
        }

        $script:mockKeyVaultAccessPolicyMissing = [PSCustomObject]@{
            VaultName = $script:testKeyVaultName
            ResourceId = $script:testVaultId
            EnableSoftDelete = $true
            EnablePurgeProtection = $true
            EnableRbacAuthorization = $false
            AccessPolicies = @([PSCustomObject]@{ ObjectId = $script:testPrincipalId; PermissionsToKeys = @("Get") })
        }

        $script:mockKeyVaultNoSoftDelete = [PSCustomObject]@{
            VaultName = $script:testKeyVaultName
            ResourceId = $script:testVaultId
            EnableSoftDelete = $false
            EnablePurgeProtection = $true
            EnableRbacAuthorization = $true
            AccessPolicies = @()
        }

        $script:mockPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyArmId
            Kind = "Encryption"
            Identity = [PSCustomObject]@{ Type = "SystemAssigned"; PrincipalId = $script:testPrincipalId }
            Properties = [PSCustomObject]@{
                encryption = [PSCustomObject]@{
                    keyVault = [PSCustomObject]@{
                        id = $script:testVaultId
                        key = [PSCustomObject]@{ name = "myKey"; version = "myVersion" }
                    }
                }
            }
        }

        $script:mockIdentityPolicy = [PSCustomObject]@{
            ResourceId = $script:testPolicyArmId
            Kind = "Identity"
            Identity = [PSCustomObject]@{ Type = "SystemAssigned"; PrincipalId = $script:testPrincipalId }
        }

        $script:mockKeyValid = [PSCustomObject]@{ Id = "https://myvault.vault.azure.net/keys/myKey/myVersion"; Enabled = $true; NotBefore = $null; Expires = $null }
        $script:mockKeyExpired = [PSCustomObject]@{ Id = "https://myvault.vault.azure.net/keys/myKey/myVersion"; Enabled = $true; NotBefore = $null; Expires = (Get-Date).AddDays(-1) }

        Mock Write-Verbose {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Warning {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Set-AzContext {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Get-EnterprisePolicy { return $script:mockPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Get-AzRoleAssignment { return [PSCustomObject]@{ RoleDefinitionName = "Key Vault Crypto Service Encryption User" } } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Get-AzKeyVaultKey { return $script:mockKeyValid } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'RBAC-based key vault' {
        BeforeAll {
            Mock Get-AzKeyVault { return $script:mockKeyVaultRbac } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return true when everything is valid' {
            Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId | Should -Be $true
        }

        It 'Should return false when the role assignment is missing' {
            Mock Get-AzRoleAssignment { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId | Should -Be $false
        }
    }

    Context 'Access-policy-based key vault' {
        It 'Should return true when required key permissions are present' {
            Mock Get-AzKeyVault { return $script:mockKeyVaultAccessPolicyValid } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId | Should -Be $true
        }

        It 'Should return false when a required key permission is missing' {
            Mock Get-AzKeyVault { return $script:mockKeyVaultAccessPolicyMissing } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId | Should -Be $false
        }
    }

    Context 'Key vault property validation' {
        It 'Should return false when soft delete is disabled' {
            Mock Get-AzKeyVault { return $script:mockKeyVaultNoSoftDelete } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId | Should -Be $false
        }
    }

    Context 'Authorization-mode regression cases' {
        BeforeEach {
            $script:authorizationVault = [PSCustomObject]@{
                VaultName = $script:testKeyVaultName
                ResourceId = $script:testVaultId
                EnableSoftDelete = $true
                EnablePurgeProtection = $true
                EnableRbacAuthorization = $true
                AccessPolicies = @([PSCustomObject]@{
                    ObjectId = $script:testPrincipalId
                    PermissionsToKeys = @("Get", "UnwrapKey", "WrapKey")
                })
            }
            Mock Get-AzKeyVault { return $script:authorizationVault } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Accepts RBAC permissions with <Collection> legacy access policies' -ForEach @(
            @{ Collection = 'populated' }
            @{ Collection = 'empty' }
            @{ Collection = 'null' }
        ) {
            if ($Collection -eq 'empty') {
                $script:authorizationVault.AccessPolicies = @()
            }
            if ($Collection -eq 'null') {
                $script:authorizationVault.AccessPolicies = $null
            }

            Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId | Should -Be $true
        }

        It 'Rejects missing RBAC even when an ignored access policy grants all key permissions' {
            Mock Get-AzRoleAssignment { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId | Should -Be $false
        }

        It 'Accepts complete access-policy permissions when RBAC is <RbacEnabled>' -ForEach @(
            @{ RbacEnabled = $false }
            @{ RbacEnabled = $null }
        ) {
            $script:authorizationVault.EnableRbacAuthorization = $RbacEnabled
            Mock Get-AzRoleAssignment { throw 'RBAC must not be queried in access-policy mode' } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId | Should -Be $true
        }

        It 'Rejects access policies missing <MissingPermission>' -ForEach @(
            @{ MissingPermission = 'Get' }
            @{ MissingPermission = 'UnwrapKey' }
            @{ MissingPermission = 'WrapKey' }
        ) {
            $script:authorizationVault.EnableRbacAuthorization = $false
            $script:authorizationVault.AccessPolicies[0].PermissionsToKeys = @("Get", "UnwrapKey", "WrapKey") |
                Where-Object { $_ -ne $MissingPermission }

            Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId | Should -Be $false
        }

        It 'Rejects access-policy mode with <Collection> matching grants despite an RBAC role' -ForEach @(
            @{ Collection = 'unrelated' }
            @{ Collection = 'empty' }
            @{ Collection = 'null' }
        ) {
            $script:authorizationVault.EnableRbacAuthorization = $false
            switch ($Collection) {
                'unrelated' { $script:authorizationVault.AccessPolicies[0].ObjectId = "22222222-2222-2222-2222-222222222222" }
                'empty' { $script:authorizationVault.AccessPolicies = @() }
                'null' { $script:authorizationVault.AccessPolicies = $null }
            }

            Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId | Should -Be $false
        }
    }

    Context 'Key validation' {
        BeforeAll {
            Mock Get-AzKeyVault { return $script:mockKeyVaultRbac } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Should return false when the key is expired' {
            Mock Get-AzKeyVaultKey { return $script:mockKeyExpired } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId | Should -Be $false
        }
    }

    Context 'Error handling' {
        It 'Should throw when the key vault cannot be retrieved' {
            Mock Get-AzKeyVault { return $null } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            { Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId } | Should -Throw "*Could not retrieve key vault*"
        }

        It 'Should throw when the policy is not an Encryption policy' {
            Mock Get-AzKeyVault { return $script:mockKeyVaultRbac } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:mockIdentityPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            { Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId } | Should -Throw "*not a CMK (Encryption) policy*"
        }

        It 'Rejects a policy with <InvalidProperty>' -ForEach @(
            @{ InvalidProperty = 'missing resource' }
            @{ InvalidProperty = 'missing identity' }
            @{ InvalidProperty = 'wrong identity type' }
            @{ InvalidProperty = 'different vault' }
        ) {
            $script:invalidPolicy = $script:mockPolicy | ConvertTo-Json -Depth 10 | ConvertFrom-Json
            switch ($InvalidProperty) {
                'missing resource' { $script:invalidPolicy = $null }
                'missing identity' { $script:invalidPolicy.Identity = $null }
                'wrong identity type' { $script:invalidPolicy.Identity.Type = 'UserAssigned' }
                'different vault' { $script:invalidPolicy.Properties.encryption.keyVault.id = 'different-vault' }
            }
            Mock Get-AzKeyVault { return $script:mockKeyVaultRbac } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnterprisePolicy { return $script:invalidPolicy } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            if ($InvalidProperty -eq 'different vault') {
                Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId | Should -Be $false
            }
            else {
                { Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId } | Should -Throw
            }
        }

        It 'Should throw when Connect-Azure fails' {
            Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            { Test-CMKKeyVault -SubscriptionId $script:testSubscriptionId -KeyVaultName $script:testKeyVaultName -EnterprisePolicyArmId $script:testPolicyArmId } | Should -Throw "*Failed to connect to Azure*"
        }
    }
}
