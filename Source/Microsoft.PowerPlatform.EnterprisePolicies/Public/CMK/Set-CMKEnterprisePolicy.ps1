<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Updates the key vault configuration of an existing customer managed key (CMK) enterprise policy.

.DESCRIPTION
The Set-CMKEnterprisePolicy cmdlet updates the key vault, key name, and/or key version referenced by an existing
CMK enterprise policy. Only the values you provide are changed; any parameter you omit keeps its current value.

The policy's system-assigned managed identity is preserved. At least one of KeyVaultId, KeyName, or KeyVersion
must be provided.

.OUTPUTS
Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource

Returns the PSResource object representing the updated enterprise policy Azure resource.

.EXAMPLE
Set-CMKEnterprisePolicy -PolicyResourceId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy" -KeyVersion "fedcba9876543210fedcba9876543210"

Updates only the key version referenced by the policy, leaving the key vault and key name unchanged.

.EXAMPLE
Set-CMKEnterprisePolicy -PolicyResourceId "/subscriptions/.../enterprisePolicies/myPolicy" -KeyVaultId "/subscriptions/.../providers/Microsoft.KeyVault/vaults/newVault" -KeyName "newKey" -KeyVersion "0123456789abcdef0123456789abcdef"

Points the policy at a different key vault, key, and key version.

.EXAMPLE
Set-CMKEnterprisePolicy -PolicyResourceId "/subscriptions/.../enterprisePolicies/myPolicy" -KeyName "rotatedKey" -AzureEnvironment AzureUSGovernment

Updates the key name for a policy in the US Government cloud.
#>

function Set-CMKEnterprisePolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage="The full Azure ARM resource ID of the CMK enterprise policy to update")]
        [ValidateAzureResourceId("Microsoft.PowerPlatform/enterprisePolicies")]
        [string]$PolicyResourceId,

        [Parameter(Mandatory=$false, HelpMessage="The full Azure resource ID of the key vault. Omit to keep the current value.")]
        [ValidateAzureResourceId("Microsoft.KeyVault/vaults")]
        [string]$KeyVaultId,

        [Parameter(Mandatory=$false, HelpMessage="The name of the key in the key vault. Omit to keep the current value.")]
        [string]$KeyName,

        [Parameter(Mandatory=$false, HelpMessage="The version of the key in the key vault. Omit to keep the current value.")]
        [string]$KeyVersion,

        [Parameter(Mandatory=$false, HelpMessage="The Entra tenant ID")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The Azure environment to use")]
        [AzureEnvironment]$AzureEnvironment = [AzureEnvironment]::AzureCloud,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication instead of reusing existing session")]
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    if (-not $PSBoundParameters.ContainsKey('KeyVaultId') -and
        -not $PSBoundParameters.ContainsKey('KeyName') -and
        -not $PSBoundParameters.ContainsKey('KeyVersion')) {
        throw "No updates provided. Specify at least one of -KeyVaultId, -KeyName, or -KeyVersion."
    }

    # Extract subscription, resource group, and name from the resource ID (format already validated by attribute)
    $null = $PolicyResourceId -match "/subscriptions/([^/]+)/resourceGroups/([^/]+)/providers/Microsoft.PowerPlatform/enterprisePolicies/([^/]+)$"
    $subscriptionId = $Matches[1]
    $resourceGroupName = $Matches[2]

    # Connect to Azure
    if (-not(Connect-Azure -AzureEnvironment $AzureEnvironment -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    Write-Verbose "Setting subscription context to $subscriptionId"
    $null = Set-SubscriptionContext -SubscriptionId $subscriptionId

    # Retrieve the existing policy
    Write-Verbose "Retrieving enterprise policy: $PolicyResourceId"
    $policy = Get-EnterprisePolicy -PolicyArmId $PolicyResourceId

    if ($null -eq $policy) {
        throw "No enterprise policy found with resource ID: $PolicyResourceId"
    }

    if ($policy.Kind -ne "Encryption") {
        throw "The specified policy is not a CMK (Encryption) policy. Policy kind: $($policy.Kind)"
    }

    # Determine the updated values, defaulting to the current configuration for any omitted parameter
    $currentKeyVault = $policy.Properties.encryption.keyVault
    $updatedKeyVaultId = if ($PSBoundParameters.ContainsKey('KeyVaultId')) { $KeyVaultId } else { $currentKeyVault.id }
    $updatedKeyName    = if ($PSBoundParameters.ContainsKey('KeyName'))    { $KeyName }    else { $currentKeyVault.key.name }
    $updatedKeyVersion = if ($PSBoundParameters.ContainsKey('KeyVersion')) { $KeyVersion } else { $currentKeyVault.key.version }

    $bodyParams = @{
        PolicyType     = [PolicyType]::Encryption
        PolicyLocation = $policy.Location
        PolicyName     = $policy.Name
        KeyVaultId     = $updatedKeyVaultId
        KeyName        = $updatedKeyName
    }
    if (-not [string]::IsNullOrWhiteSpace($updatedKeyVersion)) {
        $bodyParams['KeyVersion'] = $updatedKeyVersion
    }

    $body = New-EnterprisePolicyBody @bodyParams

    if (-not(Set-EnterprisePolicy -ResourceGroup $resourceGroupName -Body $body)) {
        throw "Failed to update CMK Enterprise Policy."
    }

    Write-Verbose "CMK Enterprise Policy $($policy.Name) updated successfully."

    return Get-EnterprisePolicy -PolicyArmId $PolicyResourceId
}
