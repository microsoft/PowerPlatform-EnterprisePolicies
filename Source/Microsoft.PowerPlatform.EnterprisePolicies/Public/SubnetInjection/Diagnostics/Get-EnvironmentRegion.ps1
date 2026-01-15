<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Retrieves the region that the specified environment is deployed in.

.DESCRIPTION
Retrieves the region that the specified environment is deployed in. Note, the region is the Power Platform region, but it is aligned with an Azure region.

.OUTPUTS
System.String
A string representing the region of the environment.

.EXAMPLE
Get-EnvironmentRegion -EnvironmentId "00000000-0000-0000-0000-000000000000"

.EXAMPLE
Get-EnvironmentRegion -EnvironmentId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint [BAPEndpoint]::Prod
#>
function Get-EnvironmentRegion{
    param(
        [Parameter(Mandatory, HelpMessage="The Id of the environment to get the region for.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory=$false, HelpMessage="The id of the tenant that the environment belongs to.")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The BAP endpoint to connect to. Default is 'prod'.")]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication to Azure.")]
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    $path = "/plex/networkUsage"
    $query = "api-version=2024-10-01"
    $result = Send-RequestWithRetries -MaxRetries 3 -DelaySeconds 2 -RequestFactory {
        return New-EnvironmentRouteRequest -EnvironmentId $EnvironmentId -Path $path -Query $query -AccessToken (Get-AccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Get) -Endpoint $Endpoint
    }

    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()

    if($contentString) {
        [NetworkUsage] $networkUsage = ConvertFrom-JsonToClass -Json $contentString -ClassType ([NetworkUsage])
        Write-Verbose "Your environment is located in region: [$($networkUsage.AzureRegion)]"
        return $networkUsage.AzureRegion
    } else {
        throw "Failed to retrieve the environment region."
    }
}