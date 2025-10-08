<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Tests the connectivity to a given service in a specified environment.

.DESCRIPTION
Tests the connectivity to a given service in a specified environment.
The connectivity test will attempt to establish a TCP connection to the specified destination on the specified port.
This function is executed in the context of your delegated subnet in the region that you have specified.
If the region is not specified, it defaults to the region of the environment.

.OUTPUTS
System.String

A string representing the result of the connectivity test.

.EXAMPLE
Test-NetworkConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "microsoft.com"

.EXAMPLE
Test-NetworkConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "unknowndb.database.windows.net" -Port 1433

.EXAMPLE
Test-NetworkConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "unknowndb.database.windows.net" -Port 1433 -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint [BAPEndpoint]::Prod

.EXAMPLE
Test-NetworkConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "unknowndb.database.windows.net" -Port 1433 -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint [BAPEndpoint]::Prod -Region "westus"
#>
function Test-NetworkConnectivity{
    param(
        [Parameter(Mandatory, HelpMessage="The Id of the environment to get usage for.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory, HelpMessage="The destination that should be used to attempt the connection. This can be a hostname or an IP address.")]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,

        [Parameter(Mandatory=$false, HelpMessage="The port that should be used to attempt the connection. Defaults to 443")]
        [string]$Port = 443,

        [Parameter(Mandatory=$false, HelpMessage="The id of the tenant that the environment belongs to.")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The BAP endpoint to connect to. Default is 'prod'.")]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="The Azure region in which to test the connectivity. Defaults to the region the environment is in.")]
        [string]$Region
    )

    $ErrorActionPreference = "Stop"

    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    $path = "/plex/testConnection"
    $query = "api-version=2024-10-01"
    if(-not([string]::IsNullOrWhiteSpace($Region)))
    {
        $query += "&region=$Region"
    }

    $Body = @{
        Destination = $Destination
        Port = $Port
    }

    $result = Send-RequestWithRetries -MaxRetries 3 -DelaySeconds 2 -RequestFactory {
        return New-EnvironmentRouteRequest -EnvironmentId $EnvironmentId -Path $path -Query $query -AccessToken (Get-AccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Post) -Content ($Body | ConvertTo-Json) -Endpoint $Endpoint
    }

    Get-AsyncResult -Task $result.Content.ReadAsStringAsync()
}