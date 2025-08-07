<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
    Gets the network usage for a specified environment.
.DESCRIPTION
    This function retrieves the network usage for a specified environment, including details such as data transfer and connectivity issues.
.PARAMETER EnvironmentId
    The Id of the environment to get usage for.
#>
function Get-EnvironmentUsage{
    param(
        [Parameter(Mandatory, HelpMessage="The Id of the environment to get usage for.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory=$false, HelpMessage="The id of the tenant that the environment belongs to.")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The region for which usage is requested. Defaults to the region the environment is in.")]
        [string]$Region = $null,

        [Parameter(Mandatory=$false, HelpMessage="The BAP endpoint to connect to. Default is 'prod'.")]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod
    )

    $ErrorActionPreference = "Stop"

    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    $client = New-HttpClient

    $uri = "$(Get-EnvironmentRoute -Endpoint $Endpoint -EnvironmentId $EnvironmentId)/plex/networkUsage?api-version=2024-10-01"

    if($Region)
    {
        $uri += "&region=$Region"
    }

    $request = New-JsonRequestMessage -Uri $uri -AccessToken (Get-AccessToken -Endpoint $Endpoint) -HttpMethod ([System.Net.Http.HttpMethod]::Get)

    $result = Get-AsyncResult -Task $client.SendAsync($request)

    Test-Result -Result $result

    Get-AsyncResult -Task $result.Content.ReadAsStringAsync()
}