<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Configures the Power Platform URLs for an air-gapped cloud.

.DESCRIPTION
The Set-PPCustomEndpoint cmdlet adds or replaces a named entry in the module's cached CustomEndpoints
configuration. Other endpoint entries are preserved. All URLs must be absolute HTTPS URLs without
credentials, query strings, or fragments.

Name identifies the Power Platform endpoint (ussec or usnat). Authority is the login base URL without
a tenant ID; authorization service authentication appends the requested tenant ID. PPEndpoint is the
BAP endpoint URL, PPResource is the Power Apps authentication resource URL, and PPAPI is the Power
Platform API base and authentication resource URL.

Updating an endpoint clears its cached authorization service clients so subsequent authentication
uses the new settings. Register the matching Azure environment separately using Add-AzEnvironment.
Use Get-PPModuleConfiguration -Name CustomEndpoints to read the stored entries.

.OUTPUTS
None.

.EXAMPLE
Set-PPCustomEndpoint -Name ussec -Authority "https://login.sec.example" -PPEndpoint "https://bap.sec.example" -PPResource "https://apps.sec.example" -PPAPI "https://api.sec.example"

Adds or replaces the ussec entry. Replace the example URLs with the cloud's actual URLs.
#>
function Set-PPCustomEndpoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage = "The name of the custom Power Platform endpoint.")]
        [ValidateSet("ussec", "usnat")]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory, HelpMessage = "The HTTPS login base URL without a tenant ID.")]
        [ValidateNotNullOrEmpty()]
        [string]$Authority,

        [Parameter(Mandatory, HelpMessage = "The HTTPS BAP endpoint URL.")]
        [ValidateNotNullOrEmpty()]
        [string]$PPEndpoint,

        [Parameter(Mandatory, HelpMessage = "The HTTPS Power Apps authentication resource URL.")]
        [ValidateNotNullOrEmpty()]
        [string]$PPResource,

        [Parameter(Mandatory, HelpMessage = "The HTTPS Power Platform API base and authentication resource URL.")]
        [ValidateNotNullOrEmpty()]
        [string]$PPAPI
    )

    $ErrorActionPreference = "Stop"

    $configuration = [PSCustomObject]@{
        Name = $Name
        Authority = $Authority
        PPEndpoint = $PPEndpoint
        PPResource = $PPResource
        PPAPI = $PPAPI
    }

    foreach ($propertyName in @("Authority", "PPEndpoint", "PPResource", "PPAPI")) {
        $uri = $null
        if (-not [uri]::TryCreate($configuration.$propertyName, [UriKind]::Absolute, [ref]$uri) -or
            $uri.Scheme -ne "https" -or [string]::IsNullOrWhiteSpace($uri.Host) -or
            $uri.UserInfo -or $uri.Query -or $uri.Fragment) {
            throw "$propertyName must be an absolute HTTPS URL without credentials, a query string, or a fragment."
        }
    }

    $endpoints = @(Get-CachedConfiguration -Name "CustomEndpoints" | Where-Object { $null -ne $_ -and $_.Name -ne $Name })
    $endpoints += $configuration
    Set-CachedConfiguration -Name "CustomEndpoints" -Value $endpoints

    foreach ($cacheKey in @($script:AuthorizationServiceCache.Keys)) {
        if ($cacheKey -like "$Name|*") {
            $script:AuthorizationServiceCache.Remove($cacheKey)
        }
    }
    if ($script:AuthorizationServiceCurrentKey -like "$Name|*") {
        $script:AuthorizationServiceCurrentKey = $null
    }

    Write-Verbose "Stored custom endpoint '$Name'."
}
