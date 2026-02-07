<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Removes a Subnet Injection Enterprise Policy for Power Platform.

.DESCRIPTION
This cmdlet removes a Subnet Injection Enterprise Policy using one of three methods:
- By Resource ID: Removes a specific policy using its Azure ARM resource ID
- By Subscription: Lists all Subnet Injection policies in a subscription (use -PolicyResourceId to remove a specific one)
- By Resource Group: Lists all Subnet Injection policies in a resource group (use -PolicyResourceId to remove a specific one)

When using BySubscription or ByResourceGroup, if multiple policies are found, the cmdlet outputs the policy ARM IDs
so you can specify which one to remove using -PolicyResourceId.

Note: A policy cannot be deleted if it is associated with any Power Platform environments.
Unlink the policy from all environments before attempting to remove it.

.OUTPUTS
None

Returns nothing on success. Throws an error if no policy is found or removal fails.
When multiple policies are found, outputs the policy ARM IDs.

.EXAMPLE
Remove-SubnetInjectionEnterprisePolicy -PolicyResourceId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy"

Removes the specified Subnet Injection Enterprise Policy by its ARM resource ID.

.EXAMPLE
Remove-SubnetInjectionEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012"

Lists all Subnet Injection Enterprise Policies in the subscription. If only one policy exists, it will be removed.
If multiple policies exist, their ARM IDs are output so you can specify which one to remove.

.EXAMPLE
Remove-SubnetInjectionEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup"

Lists all Subnet Injection Enterprise Policies in the resource group. If only one policy exists, it will be removed.
If multiple policies exist, their ARM IDs are output so you can specify which one to remove.

.EXAMPLE
Remove-SubnetInjectionEnterprisePolicy -PolicyResourceId "/subscriptions/.../enterprisePolicies/myPolicy" -AzureEnvironment AzureUSGovernment

Removes the specified policy in the Azure US Government cloud.

.EXAMPLE
Remove-SubnetInjectionEnterprisePolicy -PolicyResourceId "/subscriptions/.../enterprisePolicies/myPolicy" -Force

Removes the specified policy without prompting for confirmation.
#>

function Remove-SubnetInjectionEnterprisePolicy{
    [CmdletBinding(DefaultParameterSetName = 'ByResourceId', SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByResourceId', HelpMessage="The full Azure ARM resource ID of the enterprise policy")]
        [ValidateAzureResourceId("Microsoft.PowerPlatform/enterprisePolicies")]
        [string]$PolicyResourceId,

        [Parameter(Mandatory, ParameterSetName = 'BySubscription', HelpMessage="The Azure subscription ID to search for policies")]
        [Parameter(Mandatory, ParameterSetName = 'ByResourceGroup', HelpMessage="The Azure subscription ID containing the resource group")]
        [ValidateNotNullOrEmpty()]
        [string]$SubscriptionId,

        [Parameter(Mandatory, ParameterSetName = 'ByResourceGroup', HelpMessage="The Azure resource group name to search for policies")]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,

        [Parameter(Mandatory=$false, HelpMessage="The Azure AD tenant ID")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The Azure environment to connect to")]
        [AzureEnvironment]$AzureEnvironment = [AzureEnvironment]::AzureCloud,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication instead of reusing existing session")]
        [switch]$ForceAuth,

        [Parameter(Mandatory=$false, HelpMessage="Remove the policy without prompting for confirmation")]
        [switch]$Force
    )

    $ErrorActionPreference = "Stop"

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    # For ByResourceId, extract subscription ID from the resource ID (format already validated by attribute)
    if ($PSCmdlet.ParameterSetName -eq 'ByResourceId') {
        $null = $PolicyResourceId -match "/subscriptions/([^/]+)/"
        $SubscriptionId = $Matches[1]
    }

    # Connect to Azure
    if (-not(Connect-Azure -AzureEnvironment $AzureEnvironment -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    # Set subscription context
    Write-Verbose "Setting subscription context to $SubscriptionId"
    $null = Set-AzContext -Subscription $SubscriptionId

    # Get the policies based on parameter set
    switch ($PSCmdlet.ParameterSetName) {
        'ByResourceId' {
            Write-Verbose "Retrieving enterprise policy: $PolicyResourceId"
            $policies = @(Get-EnterprisePolicy -PolicyArmId $PolicyResourceId)
        }
        'BySubscription' {
            Write-Verbose "Retrieving all Subnet Injection enterprise policies in subscription: $SubscriptionId"
            $policies = @(Get-EnterprisePolicy -Kind ([PolicyType]::NetworkInjection))
        }
        'ByResourceGroup' {
            Write-Verbose "Retrieving all Subnet Injection enterprise policies in resource group: $ResourceGroupName"
            $policies = @(Get-EnterprisePolicy -ResourceGroupName $ResourceGroupName -Kind ([PolicyType]::NetworkInjection))
        }
    }

    if ($null -eq $policies -or $policies.Count -eq 0 -or ($policies.Count -eq 1 -and $null -eq $policies[0])) {
        throw "No enterprise policies found."
    }

    # If multiple policies found, output their IDs and return
    if ($policies.Count -gt 1) {
        Write-Host "Multiple enterprise policies found. Please specify which policy to remove using -PolicyResourceId:"
        foreach ($policy in $policies) {
            Write-Host "  $($policy.ResourceId)"
        }
        return
    }

    # Single policy found - proceed with removal
    $resourceId = $policies[0].ResourceId
    Write-Verbose "Found enterprise policy: $resourceId"

    if ($PSCmdlet.ShouldProcess($resourceId, "Remove Subnet Injection Enterprise Policy")) {
        Write-Verbose "Removing enterprise policy: $resourceId"
        $null = Remove-AzResource -ResourceId $resourceId -Force
        Write-Verbose "Successfully removed enterprise policy: $resourceId"
    }
}
