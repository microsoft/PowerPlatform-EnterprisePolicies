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
Retrieves the current usage of the specified environment.
Note, this is only the usage that this environment has. It does not include usage from other environments and it does not include any ips that might be reserved by azure.

.OUTPUTS
NetworkUsage
A class representing the network usage of the environment. [NetworkUsage](NetworkUsage.md)

.EXAMPLE
Get-EnvironmentUsage -EnvironmentId "00000000-0000-0000-0000-000000000000"

.EXAMPLE
Get-EnvironmentUsage -EnvironmentId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint [BAPEndpoint]::Prod

.EXAMPLE
Get-EnvironmentUsage -EnvironmentId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint [BAPEndpoint]::Prod -Region "westus"
#>
function Get-EnvironmentUsage{
    param(
        [Parameter(Mandatory, HelpMessage="The Id of the environment to get usage for.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory=$false, HelpMessage="The id of the tenant that the environment belongs to.")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The BAP endpoint to connect to. Default is 'prod'.")]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="The Azure region to filter the usage by. Defaults to the region the environment is in.")]
        [string]$Region
    )

    $ErrorActionPreference = "Stop"

    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    $path = "/plex/networkUsage"

    $query = "api-version=2024-10-01"
    if($Region)
    {
        $query += "&region=$Region"
    }

    $result = Send-RequestWithRetries -MaxRetries 3 -DelaySeconds 2 -RequestFactory {
        return New-EnvironmentRouteRequest -EnvironmentId $EnvironmentId -Path $path -Query $query -AccessToken (Get-AccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Get) -Endpoint $Endpoint
    }

    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()

    if($contentString) {
        [NetworkUsage] $networkUsage = ConvertFrom-JsonToClass -Json $contentString -ClassType ([NetworkUsage])
        return $networkUsage
    } else {
        throw "Failed to retrieve the environment region."
    }}