<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Validates that an Azure Key Vault is correctly configured for use with a customer managed key (CMK) enterprise policy.

.DESCRIPTION
The Test-CMKKeyVault cmdlet checks that a key vault, a CMK enterprise policy, and the encryption key satisfy the
prerequisites required by Power Platform customer managed key encryption. It verifies:

- Key vault: soft delete and purge protection are enabled.
- Enterprise policy: it is of kind Encryption, has a system-assigned managed identity, and references the given key vault.
- Access: the enterprise policy's managed identity has Get/WrapKey/UnwrapKey key permissions (access-policy vaults) or the
  'Key Vault Crypto Service Encryption User' role (RBAC vaults).
- Key: the referenced key exists, is enabled, is activated (past its NotBefore date), and is not expired.

Details for any failed check are written as warnings. Retrieval failures for the vault, policy, or key are thrown as errors.

.OUTPUTS
System.Boolean

Returns $true when every check passes; otherwise returns $false.

.EXAMPLE
Test-CMKKeyVault -SubscriptionId "12345678-1234-1234-1234-123456789012" -KeyVaultName "myVault" -EnterprisePolicyArmId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy"

Validates that 'myVault' is correctly configured for the specified CMK enterprise policy.

.EXAMPLE
Test-CMKKeyVault -SubscriptionId "12345678-1234-1234-1234-123456789012" -KeyVaultName "myVault" -EnterprisePolicyArmId "/subscriptions/.../enterprisePolicies/myPolicy" -AzureEnvironment AzureUSGovernment

Validates the key vault configuration for a policy in the US Government cloud.
#>

function Test-CMKKeyVault {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, HelpMessage="The Azure subscription ID that contains the key vault")]
        [ValidateNotNullOrEmpty()]
        [string]$SubscriptionId,

        [Parameter(Mandatory, HelpMessage="The name of the key vault to validate")]
        [ValidateNotNullOrEmpty()]
        [string]$KeyVaultName,

        [Parameter(Mandatory, HelpMessage="The full Azure ARM resource ID of the CMK enterprise policy")]
        [ValidateAzureResourceId("Microsoft.PowerPlatform/enterprisePolicies")]
        [string]$EnterprisePolicyArmId,

        [Parameter(Mandatory=$false, HelpMessage="The Entra tenant ID")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The Azure environment to use")]
        [AzureEnvironment]$AzureEnvironment = [AzureEnvironment]::AzureCloud,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication instead of reusing existing session")]
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    if (-not(Connect-Azure -AzureEnvironment $AzureEnvironment -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    Write-Verbose "Setting subscription context to $SubscriptionId"
    $null = Set-SubscriptionContext -SubscriptionId $SubscriptionId

    $isValid = $true

    # --- Validate key vault properties ---
    Write-Verbose "Retrieving key vault: $KeyVaultName"
    $keyVault = Get-AzKeyVault -VaultName $KeyVaultName
    if ($null -eq $keyVault -or [string]::IsNullOrWhiteSpace($keyVault.VaultName)) {
        throw "Could not retrieve key vault '$KeyVaultName'. Please check that the key vault exists and is accessible."
    }

    if (-not $keyVault.EnableSoftDelete) {
        Write-Warning "Soft delete is not enabled for key vault '$KeyVaultName'. Enable it as described at https://learn.microsoft.com/azure/key-vault/general/soft-delete-change"
        $isValid = $false
    }

    if (-not $keyVault.EnablePurgeProtection) {
        Write-Warning "Purge protection is not enabled for key vault '$KeyVaultName'. Enable it as described at https://learn.microsoft.com/azure/key-vault/general/soft-delete-overview#permitted-purge"
        $isValid = $false
    }

    # --- Validate enterprise policy ---
    Write-Verbose "Retrieving enterprise policy: $EnterprisePolicyArmId"
    $policy = Get-EnterprisePolicy -PolicyArmId $EnterprisePolicyArmId
    if ($null -eq $policy -or [string]::IsNullOrWhiteSpace($policy.ResourceId)) {
        throw "Could not retrieve CMK enterprise policy '$EnterprisePolicyArmId'."
    }

    if ($policy.Kind -ne "Encryption") {
        throw "Enterprise policy '$EnterprisePolicyArmId' is not a CMK (Encryption) policy. Policy kind: $($policy.Kind)"
    }

    if ($null -eq $policy.Identity -or $policy.Identity.Type -ne "SystemAssigned") {
        throw "Enterprise policy '$EnterprisePolicyArmId' does not have a system-assigned managed identity."
    }

    $policyPrincipalId = $policy.Identity.PrincipalId

    $epKeyVaultConfig = $policy.Properties.encryption.keyVault
    if ($epKeyVaultConfig.id -ne $keyVault.ResourceId) {
        Write-Warning "Enterprise policy '$EnterprisePolicyArmId' references key vault '$($epKeyVaultConfig.id)', which does not match '$($keyVault.ResourceId)'."
        $isValid = $false
    }

    # Validate the managed identity has the required access to the key vault
    if (-not $keyVault.EnableRbacAuthorization) {
        $epAccessPolicy = $keyVault.AccessPolicies | Where-Object { $_.ObjectId -eq $policyPrincipalId }
        foreach ($requiredPermission in @("Get", "UnwrapKey", "WrapKey")) {
            if ($requiredPermission -notin $epAccessPolicy.PermissionsToKeys) {
                Write-Warning "'$requiredPermission' key permission is not present for the enterprise policy identity in key vault '$KeyVaultName'."
                $isValid = $false
            }
        }
    }
    else {
        $epRoleAssignment = Get-AzRoleAssignment -Scope $keyVault.ResourceId -ObjectId $policyPrincipalId -RoleDefinitionName "Key Vault Crypto Service Encryption User"
        if ($null -eq $epRoleAssignment) {
            Write-Warning "The enterprise policy identity is not assigned the 'Key Vault Crypto Service Encryption User' role on key vault '$KeyVaultName'."
            $isValid = $false
        }
    }

    # --- Validate the encryption key ---
    $keyName = $epKeyVaultConfig.key.name
    $keyVersion = $epKeyVaultConfig.key.version

    Write-Verbose "Validating key '$keyName' in key vault '$KeyVaultName'"
    if (-not [string]::IsNullOrWhiteSpace($keyVersion)) {
        $key = Get-AzKeyVaultKey -VaultName $KeyVaultName -Name $keyName -Version $keyVersion
    }
    else {
        $key = Get-AzKeyVaultKey -VaultName $KeyVaultName -Name $keyName
    }

    if ($null -eq $key -or [string]::IsNullOrWhiteSpace($key.Id)) {
        throw "Key '$keyName' could not be retrieved from key vault '$KeyVaultName'."
    }

    if (-not $key.Enabled) {
        Write-Warning "Key '$keyName' is not enabled."
        $isValid = $false
    }

    $currentDateUtc = (Get-Date).ToUniversalTime()
    if ($null -ne $key.NotBefore -and ([datetime]$key.NotBefore) -ge $currentDateUtc) {
        Write-Warning "Key '$keyName' is not yet activated. Activation date: $($key.NotBefore)"
        $isValid = $false
    }

    if ($null -ne $key.Expires -and ([datetime]$key.Expires) -le $currentDateUtc) {
        Write-Warning "Key '$keyName' has expired. Expiry date: $($key.Expires)"
        $isValid = $false
    }

    if ($isValid) {
        Write-Host "Key vault '$KeyVaultName' is correctly configured for CMK enterprise policy '$EnterprisePolicyArmId'." -ForegroundColor Green
    }
    else {
        Write-Warning "Key vault '$KeyVaultName' is not correctly configured for CMK enterprise policy '$EnterprisePolicyArmId'. Review the warnings above."
    }

    return $isValid
}
