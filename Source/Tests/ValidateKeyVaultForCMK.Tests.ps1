BeforeDiscovery {
    . $PSScriptRoot\Shared.ps1
}

Describe 'Legacy CMK validator permissions' {
    BeforeAll {
        $validatorPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Cmk\ValidateKeyVaultForCMK.ps1'
        $parseTokens = $null
        $parseErrors = $null
        $validatorAst = [System.Management.Automation.Language.Parser]::ParseFile($validatorPath, [ref]$parseTokens, [ref]$parseErrors)
        if ($parseErrors.Count -gt 0) {
            throw "Validator parse errors: $parseErrors"
        }
        $permissionFunction = $validatorAst.Find({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq 'GetAndValidateEnterprisePolicyForKeyVault'
        }, $false)
        . ([scriptblock]::Create($permissionFunction.Extent.Text))
    }

    BeforeEach {
        $script:principalId = '11111111-1111-1111-1111-111111111111'
        $script:vaultId = '/subscriptions/test-sub/resourceGroups/test-rg/providers/Microsoft.KeyVault/vaults/test-vault'
        $script:policyId = '/subscriptions/test-sub/resourceGroups/test-rg/providers/Microsoft.PowerPlatform/enterprisePolicies/test-policy'
        $script:policy = [pscustomobject]@{
            ResourceId = $script:policyId
            Kind = 'Encryption'
            Identity = [pscustomobject]@{ Type = 'SystemAssigned'; PrincipalId = $script:principalId }
            Properties = @{ Encryption = @{ KeyVault = @{ Id = $script:vaultId } } }
        }
        $script:vault = [pscustomobject]@{
            ResourceId = $script:vaultId
            EnableRbacAuthorization = $true
            AccessPolicies = @([pscustomobject]@{
                ObjectId = '22222222-2222-2222-2222-222222222222'
                PermissionsToKeys = @('Get', 'WrapKey', 'UnwrapKey')
            })
        }
        Mock Write-Host {}
        Mock Get-AzResource { $script:policy }
        Mock Get-AzRoleAssignment { $null }
    }

    It 'Accepts an RBAC grant with <Collection> legacy access policies' -ForEach @(
        @{ Collection = 'populated' }
        @{ Collection = 'empty' }
        @{ Collection = 'null' }
    ) {
        if ($Collection -eq 'empty') { $script:vault.AccessPolicies = @() }
        if ($Collection -eq 'null') { $script:vault.AccessPolicies = $null }
        Mock Get-AzRoleAssignment {
            [pscustomobject]@{ ObjectId = $script:principalId }
        } -ParameterFilter {
            $Scope -eq $script:vaultId -and $ObjectId -eq $script:principalId -and
                $RoleDefinitionName -eq 'Key Vault Crypto Service Encryption User'
        }

        $result = GetAndValidateEnterprisePolicyForKeyVault -enterprisePolicyArmId $script:policyId -keyVault $script:vault

        $result | Should -Be $script:policy
    }

    It 'Rejects missing RBAC even when a legacy access policy grants all key permissions' {
        $script:vault.AccessPolicies[0].ObjectId = $script:principalId

        $result = GetAndValidateEnterprisePolicyForKeyVault -enterprisePolicyArmId $script:policyId -keyVault $script:vault

        $result | Should -BeNullOrEmpty
    }

    It 'Accepts complete access-policy permissions when RBAC is <RbacEnabled>' -ForEach @(
        @{ RbacEnabled = $false }
        @{ RbacEnabled = $null }
    ) {
        $script:vault.EnableRbacAuthorization = $RbacEnabled
        $script:vault.AccessPolicies[0].ObjectId = $script:principalId
        Mock Get-AzRoleAssignment { throw 'RBAC must not be queried in access-policy mode' }

        $result = GetAndValidateEnterprisePolicyForKeyVault -enterprisePolicyArmId $script:policyId -keyVault $script:vault

        $result | Should -Be $script:policy
    }

    It 'Rejects access policies missing <MissingPermission>' -ForEach @(
        @{ MissingPermission = 'Get' }
        @{ MissingPermission = 'UnwrapKey' }
        @{ MissingPermission = 'WrapKey' }
    ) {
        $script:vault.EnableRbacAuthorization = $false
        $script:vault.AccessPolicies[0].ObjectId = $script:principalId
        $script:vault.AccessPolicies[0].PermissionsToKeys = @('Get', 'UnwrapKey', 'WrapKey') |
            Where-Object { $_ -ne $MissingPermission }
        Mock Get-AzRoleAssignment { [pscustomobject]@{ ObjectId = $script:principalId } }

        $result = GetAndValidateEnterprisePolicyForKeyVault -enterprisePolicyArmId $script:policyId -keyVault $script:vault

        $result | Should -BeNullOrEmpty
    }

    It 'Rejects access-policy mode with <Collection> matching grants' -ForEach @(
        @{ Collection = 'unrelated' }
        @{ Collection = 'empty' }
        @{ Collection = 'null' }
    ) {
        $script:vault.EnableRbacAuthorization = $false
        if ($Collection -eq 'empty') { $script:vault.AccessPolicies = @() }
        if ($Collection -eq 'null') { $script:vault.AccessPolicies = $null }
        Mock Get-AzRoleAssignment { [pscustomobject]@{ ObjectId = $script:principalId } }

        $result = GetAndValidateEnterprisePolicyForKeyVault -enterprisePolicyArmId $script:policyId -keyVault $script:vault

        $result | Should -BeNullOrEmpty
    }

    It 'Rejects a policy with <InvalidProperty> before accepting permissions' -ForEach @(
        @{ InvalidProperty = 'missing resource' }
        @{ InvalidProperty = 'wrong kind' }
        @{ InvalidProperty = 'missing identity' }
        @{ InvalidProperty = 'wrong identity type' }
        @{ InvalidProperty = 'different vault' }
    ) {
        switch ($InvalidProperty) {
            'missing resource' { $script:policy = $null }
            'wrong kind' { $script:policy.Kind = 'NetworkInjection' }
            'missing identity' { $script:policy.Identity = $null }
            'wrong identity type' { $script:policy.Identity.Type = 'UserAssigned' }
            'different vault' { $script:policy.Properties.Encryption.KeyVault.Id = 'different-vault' }
        }
        Mock Get-AzRoleAssignment { [pscustomobject]@{ ObjectId = $script:principalId } }

        $result = GetAndValidateEnterprisePolicyForKeyVault -enterprisePolicyArmId $script:policyId -keyVault $script:vault

        $result | Should -BeNullOrEmpty
    }
}