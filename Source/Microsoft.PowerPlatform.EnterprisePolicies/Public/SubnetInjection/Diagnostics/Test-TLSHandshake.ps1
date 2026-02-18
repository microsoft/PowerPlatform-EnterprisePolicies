<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Attempts to establish a Transport Layer Security (TLS) handshake with the provided destination and port.

.DESCRIPTION
The Test-TLSHandshake cmdlet tests that a TLS handshake can be established against the provided destination and port.
The cmdlet is executed in the context of your delegated subnet in the region that you specify.
If the region isn't specified, it defaults to the region of the environment.

.OUTPUTS
TLSConnectivityInformation
A class representing the result of the TLS handshake. [TLSConnectivityInformation](TLSConnectivityInformation.md)

.EXAMPLE
Test-TLSHandshake -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "microsoft.com"

Tests TLS handshake with microsoft.com on the default port (443) from the environment's delegated subnet.

.EXAMPLE
Test-TLSHandshake -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "unknowndb.database.windows.net" -Port 1433

Tests TLS handshake with a SQL database on port 1433 from the environment's delegated subnet.

.EXAMPLE
Test-TLSHandshake -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "unknowndb.database.windows.net" -Port 1433 -Endpoint usgovhigh

Tests TLS handshake with a SQL database for an environment in the US Government High cloud.

.EXAMPLE
Test-TLSHandshake -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "unknowndb.database.windows.net" -Port 1433 -Endpoint [PPEndpoint]::Prod -Region "westus"

Tests TLS handshake with a SQL database in the westus region instead of the environment's default region.
#>
function Test-TLSHandshake{
    param(
        [Parameter(Mandatory, HelpMessage="The Id of the environment to test the handshake for.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory, HelpMessage="The destination that should be used to attempt the handshake for. This should only be a hostname.")]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,

        [Parameter(Mandatory=$false, HelpMessage="The port that should be used to attempt the handshake for. Defaults to 443")]
        [string]$Port = 443,

        [Parameter(Mandatory=$false, HelpMessage="The id of the tenant that the environment belongs to.")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The Power Platform endpoint to connect to. Defaults to 'prod'.")]
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="The Azure region in which to test the handshake. Defaults to the region the environment is in.")]
        [string]$Region,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication to Azure.")]
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    $path = "/plex/testTLSConnection"
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
        return New-EnvironmentRouteRequest -EnvironmentId $EnvironmentId -Path $path -Query $query -AccessToken (Get-PPAPIAccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Post) -Content ($Body | ConvertTo-Json) -Endpoint $Endpoint
    }

    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()
    if ($result.Content.Headers.GetValues("Content-Type") -eq "application/json") {
        try{
            return ConvertFrom-JsonToClass -Json $contentString -ClassType ([TLSConnectivityInformation])
        } catch {
            Write-Verbose "Failed to convert response to TLSConnectivityInformation: $($_.Exception.Message)"
            # If JSON conversion fails, return the raw string
            return $contentString
        }
    }
    else {
        return $contentString
    }
}