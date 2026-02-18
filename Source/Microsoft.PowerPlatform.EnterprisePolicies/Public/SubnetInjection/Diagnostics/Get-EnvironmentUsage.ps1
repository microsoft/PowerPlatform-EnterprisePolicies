<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Retrieves the current usage of the specified environment.

.DESCRIPTION
The Get-EnvironmentUsage cmdlet retrieves the current usage of the specified environment. This is only the usage that this environment has. It doesn't include usage from other environments and it doesn't include any IP addresses that might be reserved by Azure.

.OUTPUTS
NetworkUsage
A class representing the network usage of the environment. [NetworkUsage](NetworkUsage.md)

.EXAMPLE
Get-EnvironmentUsage -EnvironmentId "00000000-0000-0000-0000-000000000000"

Retrieves the current network usage for the specified environment using default settings.

.EXAMPLE
Get-EnvironmentUsage -EnvironmentId "00000000-0000-0000-0000-000000000000" -Endpoint usgovhigh

Retrieves the current network usage for an environment in the US Government High cloud.

.EXAMPLE
Get-EnvironmentUsage -EnvironmentId "00000000-0000-0000-0000-000000000000" -Region "westus"

Retrieves the current network usage for the specified environment filtered to the westus region.
#>
function Get-EnvironmentUsage{
    param(
        [Parameter(Mandatory, HelpMessage="The Id of the environment to get usage for.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory=$false, HelpMessage="The id of the tenant that the environment belongs to.")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The Power Platform endpoint to connect to. Defaults to 'prod'.")]
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="The Azure region to filter the usage by. Defaults to the region the environment is in.")]
        [string]$Region,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication to Azure.")]
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    $path = "/plex/networkUsage"

    $query = "api-version=2024-10-01"
    if(-not([string]::IsNullOrWhiteSpace($Region)))
    {
        $query += "&region=$Region"
    }

    $result = Send-RequestWithRetries -MaxRetries 3 -DelaySeconds 2 -RequestFactory {
        return New-EnvironmentRouteRequest -EnvironmentId $EnvironmentId -Path $path -Query $query -AccessToken (Get-PPAPIAccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Get) -Endpoint $Endpoint
    }

    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()

    if($contentString) {
        [NetworkUsage] $networkUsage = ConvertFrom-JsonToClass -Json $contentString -ClassType ([NetworkUsage])
        return $networkUsage
    } else {
        throw "Failed to retrieve the environment usage."
    }
}