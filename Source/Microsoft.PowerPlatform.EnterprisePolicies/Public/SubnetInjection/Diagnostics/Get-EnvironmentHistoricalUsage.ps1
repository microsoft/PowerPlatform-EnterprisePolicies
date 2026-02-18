<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Retrieves the historical network usage of the specified environment.

.DESCRIPTION
The Get-EnvironmentHistoricalUsage cmdlet retrieves the historical usage of the specified environment. This is only the historical usage that the specified environment has. It doesn't include usage from other environments and it doesn't include any IP addresses that might be reserved by Azure.

.OUTPUTS
EnvironmentNetworkUsageDocument
A class representing the historical network usage of the environment. [EnvironmentNetworkUsageDocument](EnvironmentNetworkUsageDocument.md)

.EXAMPLE
Get-EnvironmentHistoricalUsage -EnvironmentId "00000000-0000-0000-0000-000000000000" -Region "westus"

Retrieves the historical network usage for the specified environment in the westus region.

.EXAMPLE
Get-EnvironmentHistoricalUsage -EnvironmentId "00000000-0000-0000-0000-000000000000" -Region "usgovvirginia" -Endpoint usgovhigh -ShowDetails

Retrieves the historical network usage with detailed breakdown for an environment in the US Government High cloud.
#>
function Get-EnvironmentHistoricalUsage{
    param(
        [Parameter(Mandatory, HelpMessage="The Id of the environment to get usage for.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory=$false, HelpMessage="The id of the tenant that the environment belongs to.")]
        [string]$TenantId,

        [Parameter(Mandatory, HelpMessage="The region that the environment belongs to.")]
        [string]$Region,

        [Parameter(Mandatory=$false, HelpMessage="The Power Platform endpoint to connect to. Defaults to 'prod'.")]
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="Switch to show detailed usage information.")]
        [switch]$ShowDetails,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication to Azure.")]
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    $path = "/plex/networkUsage/environmentHistoricalUsage"
    $query = "api-version=2024-10-01&region=$Region"
    if($ShowDetails){
        $query += "&showDetails=true"
    }
    $result = Send-RequestWithRetries -MaxRetries 3 -DelaySeconds 2 -RequestFactory {
        return New-EnvironmentRouteRequest -EnvironmentId $EnvironmentId -Path $path -Query $query -AccessToken (Get-PPAPIAccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Get) -Endpoint $Endpoint
    }

    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()

    if($contentString) {
        try {
            return ConvertFrom-JsonToClass -Json $contentString -ClassType ([EnvironmentNetworkUsageDocument])
        }
        catch {
            Write-Verbose "Failed to convert response to EnvironmentNetworkUsageDocument: $($_.Exception.Message)"
            # If JSON conversion fails, return the raw string
            return $contentString
        }
    } else {
        throw "Failed to retrieve the environment network usage data from response."
    }
}