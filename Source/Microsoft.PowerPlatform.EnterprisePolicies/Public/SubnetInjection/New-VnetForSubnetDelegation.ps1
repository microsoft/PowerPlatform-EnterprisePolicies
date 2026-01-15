<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Creates a new virtual network and subnet with Microsoft.PowerPlatform/enterprisePolicies delegation, or configures an existing VNet/subnet.

.DESCRIPTION
This script creates or configures a virtual network and subnet for use with Power Platform Enterprise Policies.
It can create a new virtual network and subnet, or work with existing resources.
The subnet will be configured with delegation for Microsoft.PowerPlatform/enterprisePolicies.

.OUTPUTS
Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork

The virtual network object that was created or modified.

.EXAMPLE
New-VnetForSubnetDelegation -SubscriptionId "12345678-1234-1234-1234-123456789012" -VirtualNetworkName "existing-vnet" -SubnetName "existing-subnet" -ResourceGroupName "myResourceGroup"

Configures an existing virtual network and subnet with the required delegation.

.EXAMPLE
New-VnetForSubnetDelegation -SubscriptionId "12345678-1234-1234-1234-123456789012" -VirtualNetworkName "wus-vnet" -SubnetName "default" -CreateVirtualNetwork -AddressPrefix "10.0.0.0/16" -SubnetPrefix "10.0.1.0/24" -ResourceGroupName "myResourceGroup" -Region "westus" -TenantId "00000000-0000-0000-0000-000000000000"

Creates a new virtual network named "wus-vnet" with address space 10.0.0.0/16 and a subnet named "default" with address prefix 10.0.1.0/24, then adds delegation. If the Vnet or subnet already exist, it will just add the delegation to the existing subnet. If the vnet exists but the subnet does not, it will create the subnet with the delegation.
#>

function New-VnetForSubnetDelegation {
    [CmdletBinding(DefaultParameterSetName='ExistingVNet')]
    param(
        [Parameter(Mandatory, ParameterSetName='ExistingVNet', HelpMessage="The Azure subscription ID")]
        [Parameter(Mandatory, ParameterSetName='CreateVNet', HelpMessage="The Azure subscription ID")]
        [ValidateNotNullOrEmpty()]
        [string]$SubscriptionId,

        [Parameter(Mandatory, ParameterSetName='ExistingVNet', HelpMessage="The name of the virtual network")]
        [Parameter(Mandatory, ParameterSetName='CreateVNet', HelpMessage="The name of the virtual network")]
        [ValidateNotNullOrEmpty()]
        [string]$VirtualNetworkName,

        [Parameter(Mandatory, ParameterSetName='ExistingVNet', HelpMessage="The name of the subnet")]
        [Parameter(Mandatory, ParameterSetName='CreateVNet', HelpMessage="The name of the subnet")]
        [ValidateNotNullOrEmpty()]
        [string]$SubnetName,

        [Parameter(Mandatory, ParameterSetName='ExistingVNet', HelpMessage="The name of the resource group")]
        [Parameter(Mandatory, ParameterSetName='CreateVNet', HelpMessage="The name of the resource group")]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,

        [Parameter(Mandatory, ParameterSetName='CreateVNet', HelpMessage="The Azure region")]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        [Parameter(Mandatory, ParameterSetName='CreateVNet', HelpMessage="Create a new virtual network")]
        [switch]$CreateVirtualNetwork,

        [Parameter(Mandatory, ParameterSetName='CreateVNet', HelpMessage="The address prefix for the virtual network (e.g., '10.0.0.0/16')")]
        [ValidatePattern('^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$')]
        [string]$AddressPrefix,

        [Parameter(Mandatory, ParameterSetName='CreateVNet', HelpMessage="The address prefix for the subnet (e.g., '10.0.1.0/24')")]
        [ValidatePattern('^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$')]
        [string]$SubnetPrefix,

        [Parameter(Mandatory=$false, ParameterSetName='ExistingVNet', HelpMessage="The Azure environment")]
        [Parameter(Mandatory=$false, ParameterSetName='CreateVNet', HelpMessage="The Azure environment")]
        [AzureEnvironment]$AzureEnvironment = [AzureEnvironment]::AzureCloud,

        [Parameter(Mandatory=$false, ParameterSetName='ExistingVNet', HelpMessage="The Azure AD tenant ID")]
        [Parameter(Mandatory=$false, ParameterSetName='CreateVNet', HelpMessage="The Azure AD tenant ID")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, ParameterSetName='ExistingVNet', HelpMessage="Force re-authentication to Azure")]
        [Parameter(Mandatory=$false, ParameterSetName='CreateVNet', HelpMessage="Force re-authentication to Azure")]
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

    if ($CreateVirtualNetwork) {
        Write-Verbose "Checking if resource group '$ResourceGroupName' exists..."
        $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue

        if ($null -eq $resourceGroup) {
            Write-Verbose "Creating resource group '$ResourceGroupName' in region '$Region'..."
            $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Region
            Write-Verbose "Resource group created successfully"
        }
        else {
            Write-Verbose "Resource group '$ResourceGroupName' already exists"
        }

        Write-Verbose "Checking if virtual network '$VirtualNetworkName' exists..."
        $virtualNetwork = Get-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

        if ($null -eq $virtualNetwork) {
            Write-Verbose "Creating virtual network '$VirtualNetworkName' with address prefix '$AddressPrefix'..."
            
            $subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetPrefix -Delegation (New-AzDelegation -Name "Microsoft.PowerPlatform/enterprisePolicies" -ServiceName "Microsoft.PowerPlatform/enterprisePolicies")

            $virtualNetwork = New-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $ResourceGroupName -Location $Region -AddressPrefix $AddressPrefix -Subnet $subnetConfig 
            Write-Host "Virtual network created successfully with delegation." -ForegroundColor Green
            return $virtualNetwork
        }
        else {
            Write-Verbose "Virtual network '$VirtualNetworkName' already exists"
        }
    }

    Write-Verbose "Getting existing virtual network '$VirtualNetworkName'..."
    $virtualNetwork = Get-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $ResourceGroupName
    
    if ($null -eq $virtualNetwork) {
        throw "Virtual network '$VirtualNetworkName' not found in resource group '$ResourceGroupName'"
    }
    Write-Verbose "Virtual network retrieved successfully"

    Write-Verbose "Getting subnet '$SubnetName' from virtual network..."
    $subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $virtualNetwork -ErrorAction SilentlyContinue

    if ($null -eq $subnet) {
        if ($CreateVirtualNetwork -and $SubnetPrefix) {
            Write-Verbose "Creating subnet '$SubnetName' with prefix '$SubnetPrefix'..."
            $virtualNetwork = Add-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $virtualNetwork -AddressPrefix $SubnetPrefix -Delegation (New-AzDelegation -Name "Microsoft.PowerPlatform/enterprisePolicies" -ServiceName "Microsoft.PowerPlatform/enterprisePolicies")
            
            $virtualNetwork = Set-AzVirtualNetwork -VirtualNetwork $virtualNetwork
            Write-Host "Subnet created successfully with delegation." -ForegroundColor Green
            return $virtualNetwork
        }
        else {
            throw "Subnet '$SubnetName' not found in virtual network '$VirtualNetworkName'"
        }
    }
    else {
        Write-Verbose "Subnet retrieved successfully"
    }
    
    $existingDelegation = $subnet.Delegations | Where-Object { $_.ServiceName -eq "Microsoft.PowerPlatform/enterprisePolicies" }
    
    if ($existingDelegation) {
        Write-Host "Delegation already exists on subnet '$SubnetName'" -ForegroundColor Yellow
    }
    else {
        Write-Verbose "Adding delegation for Microsoft.PowerPlatform/enterprisePolicies to subnet '$SubnetName'..."
        $subnet = Add-AzDelegation -Name "Microsoft.PowerPlatform/enterprisePolicies" -ServiceName "Microsoft.PowerPlatform/enterprisePolicies" -Subnet $subnet
        $virtualNetwork = Set-AzVirtualNetwork -VirtualNetwork $virtualNetwork
        Write-Host "Successfully added delegation for Microsoft.PowerPlatform/enterprisePolicies to subnet '$SubnetName'" -ForegroundColor Green
        return $virtualNetwork
    }
}
