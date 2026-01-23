<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Retrieves the historical network usage of the specified subnet based on enterprise policy id and region.

.DESCRIPTION
Retrieves the historical usage of the specified subnet.
This includes usage from all environments with the specified enterprise policy id and the ips reserved by azure.

.OUTPUTS
SubnetUsageDocument
A class representing the network usage of the subnet. [SubnetUsageDocument](SubnetUsageDocument.md)

.EXAMPLE
Get-SubnetHistoricalUsage -EnterprisePolicyId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000" -Region "westus" -Endpoint [BAPEndpoint]::Prod
#>
function Get-SubnetHistoricalUsage{
    param(
        [Parameter(Mandatory, HelpMessage="The Id of the enterprise policy to get usage for.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnterprisePolicyId,

        [Parameter(Mandatory, HelpMessage="The id of the tenant.")]
        [string]$TenantId,

        [Parameter(Mandatory, HelpMessage="The region that the tenant belongs to.")]
        [string]$Region,

        [Parameter(Mandatory=$false, HelpMessage="The BAP endpoint to connect to. Default is 'prod'.")]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication to Azure.")]
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    $path = "/plex/networkUsage/subnetHistoricalUsage"
    $query = "api-version=2024-10-01&enterprisePolicyId=$EnterprisePolicyId&region=$Region"

    $result = Send-RequestWithRetries -MaxRetries 3 -DelaySeconds 2 -RequestFactory {
        return New-HomeTenantRouteRequest -TenantId $TenantId -Path $path -Query $query -AccessToken (Get-PPAPIAccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Get) -Endpoint $Endpoint
    }

    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()

    if($contentString) {
        return ConvertFrom-JsonToClass -Json $contentString -ClassType ([SubnetUsageDocument])
    } else {
        throw "Failed to retrieve the subnet usage data from response."
    }}