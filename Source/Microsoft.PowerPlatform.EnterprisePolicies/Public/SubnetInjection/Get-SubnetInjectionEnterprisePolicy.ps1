<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Retrieves subnet injection enterprise policies for Power Platform.

.DESCRIPTION
The Get-SubnetInjectionEnterprisePolicy cmdlet retrieves subnet injection enterprise policies using one of four methods:
- By Resource ID: Retrieves a specific policy using its Azure Resource Manager (ARM) resource ID
- By Environment: Retrieves the policy linked to a specific Power Platform environment
- By Subscription: Retrieves all Subnet Injection policies in the current subscription
- By Resource Group: Retrieves all Subnet Injection policies in a specific resource group

.OUTPUTS
Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource

Returns PSResource object(s) representing the enterprise policy Azure resources. Throws an error if no policy is found.

.EXAMPLE
Get-SubnetInjectionEnterprisePolicy -PolicyResourceId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy"

Retrieves a subnet injection enterprise policy by its ARM resource ID.

.EXAMPLE
Get-SubnetInjectionEnterprisePolicy -EnvironmentId "00000000-0000-0000-0000-000000000000" -Endpoint Prod

Retrieves the subnet injection enterprise policy linked to the specified Power Platform environment.

.EXAMPLE
Get-SubnetInjectionEnterprisePolicy -EnvironmentId "00000000-0000-0000-0000-000000000000" -Endpoint usgovhigh

Retrieves the subnet injection enterprise policy linked to an environment in the US Government High cloud.

.EXAMPLE
Get-SubnetInjectionEnterprisePolicy -SubscriptionId "aaaabbbb-0000-cccc-1111-dddd2222eeee"

Retrieves all subnet injection enterprise policies in the specified subscription.

.EXAMPLE
Get-SubnetInjectionEnterprisePolicy -SubscriptionId "aaaabbbb-0000-cccc-1111-dddd2222eeee" -ResourceGroupName "myResourceGroup"

Retrieves all subnet injection enterprise policies in the specified resource group.
#>

function Get-SubnetInjectionEnterprisePolicy{
    [CmdletBinding(DefaultParameterSetName = 'BySubscription')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByResourceId', HelpMessage="The full Azure ARM resource ID of the enterprise policy")]
        [ValidateAzureResourceId("Microsoft.PowerPlatform/enterprisePolicies")]
        [string]$PolicyResourceId,

        [Parameter(Mandatory, ParameterSetName = 'ByEnvironment', HelpMessage="The Power Platform environment ID to retrieve the linked policy for")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory, ParameterSetName = 'BySubscription', HelpMessage="The Azure subscription ID to search for policies")]
        [Parameter(Mandatory, ParameterSetName = 'ByResourceGroup', HelpMessage="The Azure subscription ID containing the resource group")]
        [ValidateNotNullOrEmpty()]
        [string]$SubscriptionId,

        [Parameter(Mandatory, ParameterSetName = 'ByResourceGroup', HelpMessage="The Azure resource group name to search for policies")]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,

        [Parameter(Mandatory=$false, HelpMessage="The Azure AD tenant ID")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The Power Platform endpoint to connect to. Defaults to 'prod'.")]
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication instead of reusing existing session")]
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    # For ByResourceId, extract subscription ID from the resource ID (format already validated by attribute)
    if ($PSCmdlet.ParameterSetName -eq 'ByResourceId') {
        $null = $PolicyResourceId -match "/subscriptions/([^/]+)/"
        $SubscriptionId = $Matches[1]
    }

    # Connect to Azure
    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    # Set subscription context for non-ByEnvironment parameter sets
    if ($PSCmdlet.ParameterSetName -ne 'ByEnvironment') {
        Write-Verbose "Setting subscription context to $SubscriptionId"
        $null = Set-AzContext -Subscription $SubscriptionId
    }

    # Retrieve policies based on parameter set
    switch ($PSCmdlet.ParameterSetName) {
        'BySubscription' {
            Write-Verbose "Retrieving all Subnet Injection enterprise policies in subscription: $SubscriptionId"
            $policies = Get-EnterprisePolicy -Kind ([PolicyType]::NetworkInjection)
            if ($null -eq $policies -or @($policies).Count -eq 0) {
                throw "No Subnet Injection Enterprise Policies found in subscription: $SubscriptionId"
            }
            return $policies
        }
        'ByResourceGroup' {
            Write-Verbose "Retrieving all Subnet Injection enterprise policies in resource group: $ResourceGroupName"
            $policies = Get-EnterprisePolicy -ResourceGroupName $ResourceGroupName -Kind ([PolicyType]::NetworkInjection)
            if ($null -eq $policies -or @($policies).Count -eq 0) {
                throw "No Subnet Injection Enterprise Policies found in resource group: $ResourceGroupName"
            }
            return $policies
        }
        'ByResourceId' {
            Write-Verbose "Retrieving enterprise policy: $PolicyResourceId"
            $policy = Get-EnterprisePolicy -PolicyArmId $PolicyResourceId
            if ($null -eq $policy) {
                throw "No enterprise policy found with resource ID: $PolicyResourceId"
            }
            return $policy
        }
        'ByEnvironment' {
            Write-Verbose "Retrieving environment information for: $EnvironmentId"
            $environment = Get-PPEnvironment -EnvironmentId $EnvironmentId -Endpoint $Endpoint -TenantId $TenantId

            if ($null -eq $environment) {
                throw "Failed to retrieve environment with ID: $EnvironmentId"
            }

            Write-Verbose "Environment retrieved successfully"

            if ($null -eq $environment.properties.enterprisePolicies -or $null -eq $environment.properties.enterprisePolicies.VNets) {
                throw "No Subnet Injection Enterprise Policy is linked to environment: $EnvironmentId"
            }

            $policyArmId = $environment.properties.enterprisePolicies.VNets.id
            Write-Verbose "Found linked Subnet Injection Enterprise Policy: $policyArmId"

            # Set subscription context from the policy ARM ID
            if ($policyArmId -match "/subscriptions/([^/]+)/") {
                Write-Verbose "Setting subscription context to $($Matches[1])"
                $null = Set-AzContext -Subscription $Matches[1]
            }

            $policy = Get-EnterprisePolicy -PolicyArmId $policyArmId
            if ($null -eq $policy) {
                throw "Could not retrieve enterprise policy details for: $policyArmId"
            }
            return $policy
        }
    }
}
