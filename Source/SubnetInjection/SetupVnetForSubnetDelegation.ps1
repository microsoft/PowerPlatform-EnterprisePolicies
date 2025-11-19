<#
SAMPLE CODE NOTICE
THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

# Load thescript
. "$PSScriptRoot\..\Common\EnterprisePolicyOperations.ps1"

param(
    [Parameter(
        Mandatory,
        HelpMessage="The Policy subscription"
    )]
    [string]$virtualNetworkSubscriptionId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroupName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$virtualNetworkName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$subnetName
)

Write-Warning "This script is deprecated. Please use New-VnetForSubnetDelegation.ps1 from the Microsoft.PowerPlatform.EnterprisePolicies module instead."

Write-Host "Logging In..." -ForegroundColor Green
AzureLogin
Write-Host "Logged In" -ForegroundColor Green

$null = Set-AzContext -Subscription $virtualNetworkSubscriptionId

Write-Host "Getting virtual network $virtualNetworkName" -ForegroundColor Green
$virtualNetwork = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName
if ($null -eq  $virtualNetwork.Name)
{
        Write-Host "Virtual network not retrieved" -ForegroundColor Red
        return
}
Write-Host "Virtual network retrieved" -ForegroundColor Green

Write-Host "Getting virtual network subnet $subnetName" -ForegroundColor Green
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $virtualNetwork
if ($null -eq  $subnet.Name)
{
        Write-Host "Virtual network subnet not retrieved" -ForegroundColor Red
        return
}
Write-Host "Virtual network subnet retrieved" -ForegroundColor Green

Write-Host "Adding delegation for Microsoft.PowerPlatform/enterprisePolicies to subnet $subnet.Name in vnet $virtualNetworkName" -ForegroundColor Green
$subnet = Add-AzDelegation -Name "Microsoft.PowerPlatform/enterprisePolicies" -ServiceName "Microsoft.PowerPlatform/enterprisePolicies" -Subnet $subnet
Set-AzVirtualNetwork -VirtualNetwork $virtualNetwork

Write-Host "Added delegation for Microsoft.PowerPlatform/enterprisePolicies to subnet $subnet in vnet $virtualNetworkName" -ForegroundColor Green