<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Creates a new customer managed key (CMK) enterprise policy for Power Platform.

.DESCRIPTION
The New-CMKEnterprisePolicy cmdlet creates a customer managed key enterprise policy that enables Power Platform
environments to encrypt their data with a key stored in an Azure Key Vault.

The policy is created with a system-assigned managed identity. After creation, you must grant that identity access
to the key vault (the 'Key Vault Crypto Service Encryption User' role, or Get/WrapKey/UnwrapKey key permissions when
the vault uses access policies) before linking the policy to an environment.

.OUTPUTS
Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource

Returns the PSResource object representing the created enterprise policy Azure resource.

.EXAMPLE
New-CMKEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myCmkPolicy" -PolicyLocation "unitedstates" -KeyVaultId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.KeyVault/vaults/myVault" -KeyName "myKey" -KeyVersion "0123456789abcdef0123456789abcdef"

Creates a CMK enterprise policy in the United States region that references a specific key version.

.EXAMPLE
New-CMKEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myCmkPolicy" -PolicyLocation "unitedstates" -KeyVaultId "/subscriptions/.../providers/Microsoft.KeyVault/vaults/myVault" -KeyName "myKey"

Creates a CMK enterprise policy that references the key without pinning a version, so the latest enabled key version is used.

.EXAMPLE
New-CMKEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myCmkPolicy" -PolicyLocation "usgov" -KeyVaultId "/subscriptions/.../providers/Microsoft.KeyVault/vaults/myVault" -KeyName "myKey" -TenantId "87654321-4321-4321-4321-210987654321" -AzureEnvironment AzureUSGovernment

Creates a CMK enterprise policy in the US Government cloud.
#>

function New-CMKEnterprisePolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage="The Azure subscription ID where the enterprise policy will be created")]
        [ValidateNotNullOrEmpty()]
        [string]$SubscriptionId,

        [Parameter(Mandatory, HelpMessage="The name of the resource group where the enterprise policy will be created")]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,

        [Parameter(Mandatory, HelpMessage="The name for the enterprise policy")]
        [ValidateNotNullOrEmpty()]
        [string]$PolicyName,

        [Parameter(Mandatory, HelpMessage="The Power Platform region for the enterprise policy (e.g., 'unitedstates', 'europe')")]
        [ValidateNotNullOrEmpty()]
        [string]$PolicyLocation,

        [Parameter(Mandatory, HelpMessage="The full Azure resource ID of the key vault that holds the encryption key")]
        [ValidateAzureResourceId("Microsoft.KeyVault/vaults")]
        [string]$KeyVaultId,

        [Parameter(Mandatory, HelpMessage="The name of the key in the key vault")]
        [ValidateNotNullOrEmpty()]
        [string]$KeyName,

        [Parameter(Mandatory=$false, HelpMessage="The version of the key in the key vault. Omit to use the latest enabled key version.")]
        [string]$KeyVersion,

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

    if (-not(Initialize-SubscriptionForPowerPlatform -SubscriptionId $SubscriptionId)) {
        throw "Failed to initialize subscription for Power Platform. Please ensure the subscription is registered for Microsoft.PowerPlatform and Microsoft.Network."
    }

    $bodyParams = @{
        PolicyType     = [PolicyType]::Encryption
        PolicyLocation = $PolicyLocation
        PolicyName     = $PolicyName
        KeyVaultId     = $KeyVaultId
        KeyName        = $KeyName
    }
    if (-not [string]::IsNullOrWhiteSpace($KeyVersion)) {
        $bodyParams['KeyVersion'] = $KeyVersion
    }

    $body = New-EnterprisePolicyBody @bodyParams

    if (-not(Set-EnterprisePolicy -ResourceGroup $ResourceGroupName -Body $body)) {
        throw "Failed to create CMK Enterprise Policy."
    }

    Write-Verbose "CMK Enterprise Policy $PolicyName created successfully."

    $policyArmId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.PowerPlatform/enterprisePolicies/$PolicyName"
    return Get-EnterprisePolicy -PolicyArmId $policyArmId
}
