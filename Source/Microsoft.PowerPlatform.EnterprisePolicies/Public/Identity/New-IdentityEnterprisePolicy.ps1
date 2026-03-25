<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Creates a new identity enterprise policy for Power Platform.

.DESCRIPTION
The New-IdentityEnterprisePolicy cmdlet creates an identity enterprise policy that enables Power Platform environments
to use a system-assigned managed identity. The managed identity can be used to access Azure resources
such as Azure Key Vault, Azure SQL, and other services that support managed identity authentication.

.OUTPUTS
Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource

Returns the PSResource object representing the created enterprise policy Azure resource.

.EXAMPLE
New-IdentityEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myIdentityPolicy" -PolicyLocation "unitedstates"

Creates an identity enterprise policy in the United States region with default Azure Cloud settings.

.EXAMPLE
New-IdentityEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myIdentityPolicy" -PolicyLocation "unitedstates" -TenantId "87654321-4321-4321-4321-210987654321" -AzureEnvironment AzureUSGovernment

Creates an identity enterprise policy in the US Government cloud.
#>

function New-IdentityEnterprisePolicy {
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

        [Parameter(Mandatory=$false, HelpMessage="The Azure AD tenant ID")]
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
    $null = Set-AzContext -Subscription $SubscriptionId

    if (-not(Initialize-SubscriptionForPowerPlatform -SubscriptionId $SubscriptionId)) {
        throw "Failed to initialize subscription for Power Platform. Please ensure the subscription is registered for Microsoft.PowerPlatform, Microsoft.Network and the enterprisePoliciesPreview feature is enabled."
    }

    $body = New-EnterprisePolicyBody -PolicyType ([PolicyType]::Identity) -PolicyLocation $PolicyLocation -PolicyName $PolicyName

    if (-not(Set-EnterprisePolicy -ResourceGroup $ResourceGroupName -Body $body)) {
        throw "Failed to create Identity Enterprise Policy."
    }

    Write-Verbose "Identity Enterprise Policy $PolicyName created successfully."

    $policyArmId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.PowerPlatform/enterprisePolicies/$PolicyName"
    return Get-EnterprisePolicy -PolicyArmId $policyArmId
}
