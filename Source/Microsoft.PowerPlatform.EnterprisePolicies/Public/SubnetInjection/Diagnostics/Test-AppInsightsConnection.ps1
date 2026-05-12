<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Tests connectivity to Application Insights by sending a test telemetry event from a specified environment.

.DESCRIPTION
The Test-AppInsightsConnection cmdlet validates an Application Insights connection string and sends a test telemetry event to the configured Application Insights resource.
The test is executed in the context of your delegated subnet in the region that you specify.
If the region isn't specified, it defaults to the region of the environment.

.OUTPUTS
ApplicationInsightsInformation
A class representing the result of the Application Insights connection test. [ApplicationInsightsInformation](ApplicationInsightsInformation.md)

.EXAMPLE
Test-AppInsightsConnection -EnvironmentId "00000000-0000-0000-0000-000000000000" -ConnectionString "InstrumentationKey=00000000-0000-0000-0000-000000000000;IngestionEndpoint=https://westus-0.in.applicationinsights.azure.com/" -Message "Hello from Power Platform"

Sends a test event with the supplied message to Application Insights from the environment's delegated subnet.

.EXAMPLE
Test-AppInsightsConnection -EnvironmentId "00000000-0000-0000-0000-000000000000" -ConnectionString "InstrumentationKey=...;IngestionEndpoint=https://usgovvirginia-0.in.applicationinsights.azure.us/" -Message "Test" -Endpoint usgovhigh

Sends a test event from an environment in the US Government High cloud.

.EXAMPLE
Test-AppInsightsConnection -EnvironmentId "00000000-0000-0000-0000-000000000000" -ConnectionString "..." -Message "Test" -Region "westus"

Sends a test event from the westus region instead of the environment's default region.
#>
function Test-AppInsightsConnection{
    param(
        [Parameter(Mandatory, HelpMessage="The Id of the environment to test the Application Insights connection from.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory, HelpMessage="The Application Insights connection string to validate and use for the test event.")]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectionString,

        [Parameter(Mandatory, HelpMessage="The message body to send as the test telemetry event.")]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory=$false, HelpMessage="The id of the tenant that the environment belongs to.")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The Power Platform endpoint to connect to. Defaults to 'prod'.")]
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="The Azure region in which to test the connection. Defaults to the region the environment is in.")]
        [string]$Region,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication to Azure.")]
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    $path = "/plex/TestAppInsightsConnection"
    if ([string]::IsNullOrWhiteSpace($Region)) {
        $Region = Get-EnvironmentRegionFromCache -EnvironmentId $EnvironmentId -Endpoint $Endpoint -TenantId $TenantId
    }
    $query = "api-version=2026-02-01&region=$Region"

    $Body = @{
        ConnectionString = $ConnectionString
        Message = $Message
    }

    $result = Send-RequestWithRetries -MaxRetries 3 -DelaySeconds 2 -RequestFactory {
        return New-EnvironmentRouteRequest -EnvironmentId $EnvironmentId -Path $path -Query $query -AccessToken (Get-PPAPIAccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Post) -Content ($Body | ConvertTo-Json) -Endpoint $Endpoint
    }

    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()

    try{
        $information = ConvertFrom-JsonToClass -Json $contentString -ClassType ([ApplicationInsightsInformation])
        if($information.TestMessageSent){
            Write-Host "Application Insights test event sent successfully from [$($information.ContainerIpAddress)]."
        }
        elseif (-not $information.ConnectionStringValid) {
            Write-Warning "Application Insights connection string is invalid: $($information.ErrorMessage)"
        }
        else {
            Write-Warning "Application Insights test event could not be sent from [$($information.ContainerIpAddress)] because: $($information.ErrorMessage)"
        }
        return $information
    } catch {
        Write-Verbose "Failed to convert response to JSON: $($_.Exception.Message)"
        # If JSON conversion fails, return the raw string
        return $contentString
    }
}
