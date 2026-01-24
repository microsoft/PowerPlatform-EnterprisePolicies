<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Creates a new Subnet Injection Enterprise Policy for Power Platform.

.DESCRIPTION
This cmdlet creates a Subnet Injection Enterprise Policy that enables Power Platform environments to use delegated subnets from Azure Virtual Networks. The policy allows Power Platform services to inject into your virtual network for secure connectivity.

Some Power Platform regions require two virtual networks in paired Azure regions. Use the VirtualNetworkId2 and SubnetName2 parameters when deploying to these regions.

.OUTPUTS
System.String

A JSON string representation of the created enterprise policy resource.

.EXAMPLE
New-SubnetInjectionEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myPolicy" -PolicyLocation "unitedstates" -VirtualNetworkId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVnet" -SubnetName "default" -AzureEnvironment AzureCloud

Creates a Subnet Injection Enterprise Policy in the United States region using a single virtual network.

.EXAMPLE
New-SubnetInjectionEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myPolicy" -PolicyLocation "unitedstates" -VirtualNetworkId "/subscriptions/.../virtualNetworks/vnet1" -SubnetName "subnet1" -VirtualNetworkId2 "/subscriptions/.../virtualNetworks/vnet2" -SubnetName2 "subnet2" -TenantId "87654321-4321-4321-4321-210987654321" -AzureEnvironment AzureCloud

Creates a Subnet Injection Enterprise Policy using two virtual networks in paired regions, required for certain Power Platform regions.
#>

function New-SubnetInjectionEnterprisePolicy{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage="The Azure subscription ID where the enterprise policy will be created")]
        [string]$SubscriptionId,

        [Parameter(Mandatory, HelpMessage="The name of the resource group where the enterprise policy will be created")]
        [string]$ResourceGroupName,

        [Parameter(Mandatory, HelpMessage="The name for the enterprise policy")]
        [string]$PolicyName,

        [Parameter(Mandatory, HelpMessage="The Power Platform region for the enterprise policy (e.g., 'unitedstates', 'europe')")]
        [string]$PolicyLocation,

        [Parameter(Mandatory, HelpMessage="The full Azure resource ID of the virtual network")]
        [string]$VirtualNetworkId,

        [Parameter(Mandatory, HelpMessage="The name of the subnet within the virtual network")]
        [string]$SubnetName,

        [Parameter(HelpMessage="The full Azure resource ID of a second virtual network (required for regions needing paired VNets)")]
        [string]$VirtualNetworkId2,

        [Parameter(HelpMessage="The name of the subnet within the second virtual network")]
        [string]$SubnetName2,

        [Parameter(Mandatory, HelpMessage="The Azure AD tenant ID")]
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

    if(-not(Initialize-SubscriptionForPowerPlatform -SubscriptionId $SubscriptionId)) {
        throw "Failed to initialize subscription for Power Platform. Please ensure the subscription is registered for Microsoft.PowerPlatform, Microsoft.Network and the enterprisePoliciesPreview feature is enabled."
    }

    $vnets = @()
    $vnets += [VnetInformation]::new((Get-VirtualNetwork -VirtualNetworkId $VirtualNetworkId -EnterprisePolicyLocation $PolicyLocation), $SubnetName)

    if(Test-PowerPlatformRegionRequiresPair -PowerPlatformRegion $PolicyLocation) {
        if ([string]::IsNullOrWhiteSpace($VirtualNetworkId2) -or [string]::IsNullOrWhiteSpace($SubnetName2)) {
	            throw "A second virtual network ID and subnet name must be provided when the selected Power Platform region requires 2 delegated subnets."
	    }
        $vnets += [VnetInformation]::new((Get-VirtualNetwork -VirtualNetworkId $VirtualNetworkId2 -EnterprisePolicyLocation $PolicyLocation), $SubnetName2)
        Assert-RegionPairing -VnetInformation $vnets -PowerPlatformRegion $PolicyLocation
    }
    elseif (-not [string]::IsNullOrWhiteSpace($VirtualNetworkId2) -or -not [string]::IsNullOrWhiteSpace($SubnetName2)) {
        Write-Warning "VirtualNetworkId2 and SubnetName2 parameters are ignored because the region '$PolicyLocation' does not require paired virtual networks."
    }

    $body = New-EnterprisePolicyBody -PolicyType ([PolicyType]::NetworkInjection) -PolicyLocation $PolicyLocation -PolicyName $PolicyName -VnetInformation $vnets

    if(-not(Set-EnterprisePolicy -ResourceGroup $ResourceGroupName -Body $body)) {
        throw "Failed to create Subnet Injection Enterprise Policy."
    }

    Write-Verbose "Subnet Injection Enterprise Policy $PolicyName created successfully."

    $policyArmId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.PowerPlatform/enterprisePolicies/$PolicyName"
    $policy = Get-EnterprisePolicy $policyArmId
    $policyString = $policy | ConvertTo-Json -Depth 7
    return $policyString
}