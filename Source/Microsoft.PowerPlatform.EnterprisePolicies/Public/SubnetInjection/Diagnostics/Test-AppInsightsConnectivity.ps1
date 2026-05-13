<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Tests network connectivity to the Application Insights ingestion endpoint described by a connection string.

.DESCRIPTION
The Test-AppInsightsConnectivity cmdlet validates that the Application Insights ingestion endpoint described by the supplied connection string is reachable from the delegated subnet of the specified environment. Optionally, a test telemetry event can be sent along with the connectivity check by supplying a message.
The test is executed in the context of your delegated subnet in the region that you specify.
If the region isn't specified, it defaults to the region of the environment.

.OUTPUTS
ApplicationInsightsInformation
A class representing the result of the Application Insights connectivity test. [ApplicationInsightsInformation](ApplicationInsightsInformation.md)

.EXAMPLE
Test-AppInsightsConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -ConnectionString "InstrumentationKey=00000000-0000-0000-0000-000000000000;IngestionEndpoint=https://westus-0.in.applicationinsights.azure.com/"

Tests connectivity to the Application Insights ingestion endpoint from the environment's delegated subnet.

.EXAMPLE
Test-AppInsightsConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -ConnectionString "InstrumentationKey=...;IngestionEndpoint=https://westus-0.in.applicationinsights.azure.com/" -Message "Hello from Power Platform"

Tests connectivity and additionally sends a test telemetry event with the supplied message.

.EXAMPLE
Test-AppInsightsConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -ConnectionString "InstrumentationKey=...;IngestionEndpoint=https://usgovvirginia-0.in.applicationinsights.azure.us/" -Endpoint usgovhigh

Tests connectivity from an environment in the US Government High cloud.

.EXAMPLE
Test-AppInsightsConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -ConnectionString "..." -Region "westus"

Tests connectivity from the westus region instead of the environment's default region.
#>
function Test-AppInsightsConnectivity{
    param(
        [Parameter(Mandatory, HelpMessage="The Id of the environment to test the Application Insights connectivity from.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory, HelpMessage="The Application Insights connection string whose ingestion endpoint should be tested.")]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectionString,

        [Parameter(Mandatory=$false, HelpMessage="Optional message body to send as a test telemetry event alongside the connectivity check.")]
        [string]$Message,

        [Parameter(Mandatory=$false, HelpMessage="The id of the tenant that the environment belongs to.")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The Power Platform endpoint to connect to. Defaults to 'prod'.")]
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="The Azure region in which to test the connectivity. Defaults to the region the environment is in.")]
        [string]$Region,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication to Azure.")]
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    $path = "/plex/testAppInsightsConnection"
    if ([string]::IsNullOrWhiteSpace($Region)) {
        $Region = Get-EnvironmentRegionFromCache -EnvironmentId $EnvironmentId -Endpoint $Endpoint -TenantId $TenantId
    }
    $query = "api-version=2026-02-01&region=$Region"

    $Body = @{
        ConnectionString = $ConnectionString
        Message = if ([string]::IsNullOrWhiteSpace($Message)) { "" } else { $Message }
    }

    $result = Send-RequestWithRetries -MaxRetries 3 -DelaySeconds 2 -RequestFactory {
        return New-EnvironmentRouteRequest -EnvironmentId $EnvironmentId -Path $path -Query $query -AccessToken (Get-PPAPIAccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Post) -Content ($Body | ConvertTo-Json) -Endpoint $Endpoint
    }

    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()

    try{
        $information = ConvertFrom-JsonToClass -Json $contentString -ClassType ([ApplicationInsightsInformation])
        if (-not $information.ConnectionStringValid) {
            Write-Warning "Application Insights connection string is invalid: $($information.ErrorMessage)"
        }
        elseif ($PSBoundParameters.ContainsKey('Message')) {
            if ($information.TestMessageSent) {
                Write-Host "Application Insights connectivity succeeded and test event sent from [$($information.ContainerIpAddress)]. Verify that the message arrived in your Application Insights resource - ingestion can take several minutes."
            }
            else {
                Write-Warning "Application Insights connectivity test from [$($information.ContainerIpAddress)] failed to send the test event: $($information.ErrorMessage)"
            }
        }
        else {
            Write-Host "Application Insights connectivity succeeded from [$($information.ContainerIpAddress)]."
        }
        return $information
    } catch {
        Write-Verbose "Failed to convert response to JSON: $($_.Exception.Message)"
        return $contentString
    }
}
