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

function ValidateAndGetVnet($vnetId, $enterprisePolicylocation) {

    $vnetResource = Get-AzResource -ResourceId $vnetId
    if ($vnetResource.ResourceId -eq $null)
    {
        Write-Host "Error getting virtual network for $vnetId `n" -ForegroundColor Red
        return $null
    }

    $vnetLocation = $vnetResource.Location
    if ($supportedVnetLocations.ContainsKey($enterprisePolicylocation) -eq $false)
    {
        Write-Host "The location $enterprisePolicylocation of enterprise policy is not supported`n" -ForegroundColor Red
        $supportedEnterprisePolicyLocationsString = $supportedVnetLocations.Keys -join ","
        Write-Host "The supported enterprise policy locations are $supportedEnterprisePolicyLocationsString`n" -ForegroundColor Red
        return $null
    }

    $vnetLocationsAllowed = $supportedVnetLocations[$enterprisePolicylocation].Split(";") | ForEach-Object { $_.Split("|") }
    if ($vnetLocationsAllowed.Contains($vnetLocation))
    {
        return $vnetResource
    }

    Write-Host "The location $vnetLocation of vnet $vnetId is not supported for enterprise policy location $enterprisePolicylocation`n" -ForegroundColor Red
    $vnetLocationsAllowedString = $vnetLocationsAllowed -join ","
    Write-Host "The supported vnet location for enterprise policy location $enterprisePolicylocation are $vnetLocationsAllowedString`n" -ForegroundColor Red
    return $null
}

function Assert-RegionPairing {
    param(
        [Parameter(Mandatory)]
        $primaryVnet,

        [Parameter(Mandatory)]
        $secondaryVnet,

        [Parameter(Mandatory)]
        $policyLocation
    )

    $primaryRegion = $primaryVnet.Location
    $secondaryRegion = $secondaryVnet.Location

    $vnetPairsAllowed = $supportedVnetLocations[$policyLocation].Split(";")

    foreach ($pair in $vnetPairsAllowed) {
        $regions = $pair.Split("|")
        if($regions -contains $primaryRegion -and $regions -contains $secondaryRegion -and $primaryRegion -ne $secondaryRegion) {
            return
        }
    }
    throw "The regions $primaryRegion and $secondaryRegion of the provided vnets are not a supported pair for enterprise policy location $policyLocation. The supported region pairs are: $($vnetPairsAllowed -join ", ")"
}
