<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Creates a new subnet injection enterprise policy for Power Platform.

.DESCRIPTION
The New-SubnetInjectionEnterprisePolicy cmdlet creates a subnet injection enterprise policy that enables Power Platform environments to use delegated subnets from Azure Virtual Networks.
The policy allows Power Platform services to inject into your virtual network for secure connectivity.

Some Power Platform regions support two virtual networks in paired Azure regions.
Use the VirtualNetworkId2 and SubnetName2 parameters when you deploy to these regions.

If you want to deploy to a paired-region geo with only a single virtual network, pass the
IAcceptLimitationsOfSingleRegionVnet switch to acknowledge the reduced regional redundancy.

.OUTPUTS
Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource

Returns the PSResource object representing the created enterprise policy Azure resource.

.EXAMPLE
New-SubnetInjectionEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myPolicy" -PolicyLocation "unitedstates" -VirtualNetworkId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVnet" -SubnetName "default" -AzureEnvironment AzureCloud

Creates a subnet injection enterprise policy in the United States region using a single virtual network.

.EXAMPLE
New-SubnetInjectionEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myPolicy" -PolicyLocation "unitedstates" -VirtualNetworkId "/subscriptions/.../virtualNetworks/vnet1" -SubnetName "subnet1" -VirtualNetworkId2 "/subscriptions/.../virtualNetworks/vnet2" -SubnetName2 "subnet2" -TenantId "87654321-4321-4321-4321-210987654321" -AzureEnvironment AzureCloud

Creates a subnet injection enterprise policy using two virtual networks in paired regions, which is recommended for Power Platform regions that support paired VNets.

.EXAMPLE
New-SubnetInjectionEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myPolicy" -PolicyLocation "unitedstates" -VirtualNetworkId "/subscriptions/.../virtualNetworks/vnet1" -SubnetName "subnet1" -TenantId "87654321-4321-4321-4321-210987654321" -IAcceptLimitationsOfSingleRegionVnet

Creates a subnet injection enterprise policy with a single virtual network in a region that supports paired VNets. The IAcceptLimitationsOfSingleRegionVnet switch acknowledges that this configuration does not provide paired-region redundancy.
#>

function New-SubnetInjectionEnterprisePolicy{
    [CmdletBinding(DefaultParameterSetName = "SingleVnet")]
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
        [ValidateAzureResourceId("Microsoft.Network/virtualNetworks")]
        [string]$VirtualNetworkId,

        [Parameter(Mandatory, HelpMessage="The name of the subnet within the virtual network")]
        [string]$SubnetName,

        [Parameter(Mandatory, ParameterSetName="PairedVnet", HelpMessage="The full Azure resource ID of the second virtual network in the paired Azure region")]
        [ValidateAzureResourceId("Microsoft.Network/virtualNetworks")]
        [string]$VirtualNetworkId2,

        [Parameter(Mandatory, ParameterSetName="PairedVnet", HelpMessage="The name of the subnet within the second virtual network")]
        [string]$SubnetName2,

        [Parameter(Mandatory, ParameterSetName="AcknowledgedSingleVnet", HelpMessage="Acknowledge creating a policy with a single virtual network in a Power Platform region that supports paired virtual networks. This configuration does not provide paired-region redundancy.")]
        [switch]$IAcceptLimitationsOfSingleRegionVnet,

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

    $regionRequiresPair = Test-PowerPlatformRegionRequiresPair -PowerPlatformRegion $PolicyLocation

    switch ($PSCmdlet.ParameterSetName) {
        "PairedVnet" {
            if (-not $regionRequiresPair) {
                throw "Two virtual networks were provided but the region '$PolicyLocation' only supports a single virtual network. Remove VirtualNetworkId2 and SubnetName2, or choose a different PolicyLocation."
            }
            $vnets += [VnetInformation]::new((Get-VirtualNetwork -VirtualNetworkId $VirtualNetworkId2 -EnterprisePolicyLocation $PolicyLocation), $SubnetName2)
            Assert-RegionPairing -VnetInformation $vnets -PowerPlatformRegion $PolicyLocation
        }
        "AcknowledgedSingleVnet" {
            if (-not $regionRequiresPair) {
                Write-Warning "The -IAcceptLimitationsOfSingleRegionVnet switch is ignored because the region '$PolicyLocation' does not support paired virtual networks."
                break
            }
            Write-Warning "Creating a subnet injection enterprise policy with a single virtual network in region '$PolicyLocation', which supports paired virtual networks. This configuration does not provide paired-region redundancy."
        }
        "SingleVnet" {
            if ($regionRequiresPair) {
                throw "The enterprise policy region '$PolicyLocation' supports paired virtual networks in two Azure regions. Either provide VirtualNetworkId2 and SubnetName2 for a second virtual network, or pass -IAcceptLimitationsOfSingleRegionVnet to proceed with a single virtual network."
            }
        }
    }

    $body = New-EnterprisePolicyBody -PolicyType ([PolicyType]::NetworkInjection) -PolicyLocation $PolicyLocation -PolicyName $PolicyName -VnetInformation $vnets

    if(-not(Set-EnterprisePolicy -ResourceGroup $ResourceGroupName -Body $body)) {
        throw "Failed to create Subnet Injection Enterprise Policy."
    }

    Write-Verbose "Subnet Injection Enterprise Policy $PolicyName created successfully."

    $policyArmId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.PowerPlatform/enterprisePolicies/$PolicyName"
    return Get-EnterprisePolicy -PolicyArmId $policyArmId
}