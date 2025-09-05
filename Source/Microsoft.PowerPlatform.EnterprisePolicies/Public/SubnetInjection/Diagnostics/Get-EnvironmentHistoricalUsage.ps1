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
Retrieves the historical usage of the specified environment.
Note, this is only the historical usage that this environment has. It does not include usage from other environments and it does not include any ips that might be reserved by azure.

.OUTPUTS
EnvironmentNetworkUsageDocument
A class representing the historical network usage of the environment. [EnvironmentNetworkUsageDocument](EnvironmentNetworkUsageDocument.md)

.EXAMPLE
Get-EnvironmentHistoricalUsage -EnvironmentId "00000000-0000-0000-0000-000000000000" -Region "WestUs"

.EXAMPLE
Get-EnvironmentHistoricalUsage -EnvironmentId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000" -Region "WestUs" -Endpoint [BAPEndpoint]::Prod
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

        [Parameter(Mandatory=$false, HelpMessage="The BAP endpoint to connect to. Default is 'prod'.")]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod
    )

    $ErrorActionPreference = "Stop"

    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    $client = New-HttpClient

    $uri = "$(Get-EnvironmentRoute -Endpoint $Endpoint -EnvironmentId $EnvironmentId)/plex/networkUsage/environmentHistoricalUsage?api-version=2024-10-01&region=$Region"

    $request = New-JsonRequestMessage -Uri $uri -AccessToken (Get-AccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Get)

    $result = Get-AsyncResult -Task $client.SendAsync($request)

    Test-Result -Result $result

    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()

    if($contentString) {
        return ConvertFrom-JsonToClass -Json $contentString -ClassType ([EnvironmentNetworkUsageDocument])
    } else {
        throw "Failed to retrieve the environment network usage data from response."
    }}