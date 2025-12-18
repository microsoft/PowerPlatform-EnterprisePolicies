<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

$supportedVnetLocations = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$supportedVnetLocations.Add("centraluseuap", "eastus|westus")
$supportedVnetLocations.Add("eastus2euap", "eastus|westus")
$supportedVnetLocations.Add("unitedstateseuap", "eastus|westus")
$supportedVnetLocations.Add("unitedstates", "eastus|westus;centralus|eastus2")
$supportedVnetLocations.Add("southafrica", "southafricanorth|southafricawest")
$supportedVnetLocations.Add("uk", "uksouth|ukwest")
$supportedVnetLocations.Add("japan", "japaneast|japanwest")
$supportedVnetLocations.Add("india", "centralindia|southindia")
$supportedVnetLocations.Add("france", "francecentral|francesouth")
$supportedVnetLocations.Add("europe", "westeurope|northeurope")
$supportedVnetLocations.Add("germany", "germanynorth|germanywestcentral")
$supportedVnetLocations.Add("switzerland", "switzerlandnorth|switzerlandwest")
$supportedVnetLocations.Add("canada", "canadacentral|canadaeast")
$supportedVnetLocations.Add("brazil", "brazilsouth")
$supportedVnetLocations.Add("australia", "australiasoutheast|australiaeast")
$supportedVnetLocations.Add("asia", "eastasia|southeastasia")
$supportedVnetLocations.Add("uae", "uaenorth")
$supportedVnetLocations.Add("korea", "koreasouth|koreacentral")
$supportedVnetLocations.Add("norway", "norwaywest|norwayeast")
$supportedVnetLocations.Add("singapore", "southeastasia")
$supportedVnetLocations.Add("sweden", "swedencentral")
$supportedVnetLocations.Add("italy", "italynorth")
$supportedVnetLocations.Add("usgov", "usgovtexas|usgovvirginia")

function Test-PowerPlatformRegionRequiresPair
{
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $PowerPlatformRegion
    )

    Assert-PowerPlatformRegionIsSupported -PowerPlatformRegion $PowerPlatformRegion
    $vnetLocationsAllowed = $SupportedVnetLocations[$PowerPlatformRegion].Split(";") | ForEach-Object { $_.Split("|") }
    return $vnetLocationsAllowed.Count -gt 1
}

function Assert-AzureRegionIsSupported
{
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $PowerPlatformRegion,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $AzureRegion
    )

    Assert-PowerPlatformRegionIsSupported -PowerPlatformRegion $PowerPlatformRegion
    $vnetLocationsAllowed = $SupportedVnetLocations[$PowerPlatformRegion].Split(";") | ForEach-Object { $_.Split("|") }
    if (-not($vnetLocationsAllowed.Contains($AzureRegion)))
    {
        throw "The location $AzureRegion is not supported for enterprise policy location $PowerPlatformRegion. The supported vnet location for the enterprise policy location are $($vnetLocationsAllowed -join ",")"
    }
}
function Assert-PowerPlatformRegionIsSupported
{
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $PowerPlatformRegion
    )

    if(-not($SupportedVnetLocations.ContainsKey($PowerPlatformRegion)))
    {
        throw "The PowerPlatform region [$PowerPlatformRegion] is not supported. The supported enterprise policy locations are $($SupportedVnetLocations.Keys -join ",")`n"
    }
}

function Get-SupportedVnetRegionsForPowerPlatformRegion
{
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $PowerPlatformRegion
    )

    Assert-PowerPlatformRegionIsSupported -PowerPlatformRegion $PowerPlatformRegion
    return $SupportedVnetLocations[$PowerPlatformRegion].Split(";") | ForEach-Object { $_.Split("|") }
}

function Get-VirtualNetwork{
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $VirtualNetworkId,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $EnterprisePolicyLocation
    )

    $vnetResource = Get-AzResource -ResourceId $VirtualNetworkId
    if ($null -eq $vnetResource.ResourceId)
    {
        throw "Error getting virtual network for $VirtualNetworkId `n"
    }

    Assert-AzureRegionIsSupported -PowerPlatformRegion $EnterprisePolicyLocation -AzureRegion $vnetResource.Location

    return $vnetResource
}

function Assert-RegionPairing {
    param(
        [Parameter(Mandatory)]
        [VnetInformation[]]$VnetInformation,

        [Parameter(Mandatory)]
        $PowerPlatformRegion
    )

    if ($Vnets.Count -ne 2) {
        throw "Region pairing validation requires exactly 2 vnets."
    }
    $vnetRegion1 = $Vnets[0].VnetResource.Location
    $vnetRegion2 = $Vnets[1].VnetResource.Location

    $vnetPairsAllowed = $supportedVnetLocations[$PowerPlatformRegion].Split(";")

    foreach ($pair in $vnetPairsAllowed) {
        $regions = $pair.Split("|")
        if($regions -contains $vnetRegion1 -and $regions -contains $vnetRegion2 -and $vnetRegion1 -ne $vnetRegion2) {
            return
        }
    }
    throw "The regions $vnetRegion1 and $vnetRegion2 of the provided vnets are not a supported pair for enterprise policy location $policyLocation. The supported region pairs are: $($vnetPairsAllowed -join ", ")"
}