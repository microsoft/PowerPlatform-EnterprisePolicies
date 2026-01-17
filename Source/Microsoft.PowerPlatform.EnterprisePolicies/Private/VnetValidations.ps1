<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

$SupportedVnetLocations = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$SupportedVnetLocations.Add("centraluseuap", "eastus|westus")
$SupportedVnetLocations.Add("eastus2euap", "eastus|westus")
$SupportedVnetLocations.Add("unitedstateseuap", "eastus|westus")
$SupportedVnetLocations.Add("unitedstates", "eastus|westus;centralus|eastus2")
$SupportedVnetLocations.Add("southafrica", "southafricanorth|southafricawest")
$SupportedVnetLocations.Add("uk", "uksouth|ukwest")
$SupportedVnetLocations.Add("japan", "japaneast|japanwest")
$SupportedVnetLocations.Add("india", "centralindia|southindia")
$SupportedVnetLocations.Add("france", "francecentral|francesouth")
$SupportedVnetLocations.Add("europe", "westeurope|northeurope")
$SupportedVnetLocations.Add("germany", "germanynorth|germanywestcentral")
$SupportedVnetLocations.Add("switzerland", "switzerlandnorth|switzerlandwest")
$SupportedVnetLocations.Add("canada", "canadacentral|canadaeast")
$SupportedVnetLocations.Add("brazil", "brazilsouth")
$SupportedVnetLocations.Add("australia", "australiasoutheast|australiaeast")
$SupportedVnetLocations.Add("asia", "eastasia|southeastasia")
$SupportedVnetLocations.Add("uae", "uaenorth")
$SupportedVnetLocations.Add("korea", "koreasouth|koreacentral")
$SupportedVnetLocations.Add("norway", "norwaywest|norwayeast")
$SupportedVnetLocations.Add("singapore", "southeastasia")
$SupportedVnetLocations.Add("sweden", "swedencentral")
$SupportedVnetLocations.Add("italy", "italynorth")
$SupportedVnetLocations.Add("usgov", "usgovtexas|usgovvirginia")

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

    if ($VnetInformation.Count -ne 2) {
        throw "Region pairing validation requires exactly 2 vnets."
    }
    $vnetRegion1 = $VnetInformation[0].VnetResource.Location
    $vnetRegion2 = $VnetInformation[1].VnetResource.Location
    $vnetPairsAllowed = $SupportedVnetLocations[$PowerPlatformRegion].Split(";")

    foreach ($pair in $vnetPairsAllowed) {
        $regions = $pair.Split("|")
        if($regions -contains $vnetRegion1 -and $regions -contains $vnetRegion2 -and $vnetRegion1 -ne $vnetRegion2) {
            return
        }
    }
    throw "The regions $vnetRegion1 and $vnetRegion2 of the provided vnets are not a supported pair for enterprise policy location $PowerPlatformRegion. The supported region pairs are: $($vnetPairsAllowed -join ", ")"
}