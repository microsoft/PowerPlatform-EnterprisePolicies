<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Tests the DNS resolution for a given hostname in a specified environment.

.DESCRIPTION
Tests the DNS resolution for a given hostname in a specified environment.
This function is executed in the context of your delegated subnet in the region that you have specified.
If the region is not specified, it defaults to the region of the environment.

.OUTPUTS
System.String

A string representing the result of the DNS resolution. Whether it is successful or not, the result will return the DNS server that was used for the resolution.
If the resolution succeeds, it will return the IP address of the hostname.

.EXAMPLE
Test-DnsResolution -EnvironmentId "00000000-0000-0000-0000-000000000000" -HostName "microsoft.com"

.EXAMPLE
Test-DnsResolution -EnvironmentId "00000000-0000-0000-0000-000000000000" -HostName "microsoft.com" -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint [BAPEndpoint]::Prod
#>
function Test-DnsResolution {
    param(
        [Parameter(Mandatory, HelpMessage="The Id of the environment to get usage for.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,
    
        [Parameter(Mandatory, HelpMessage="The hostname that DNS should attempt to resolve. IP addresses are not supported.")]
        [ValidateNotNullOrEmpty()]
        [string]$HostName,
    
        [Parameter(Mandatory=$false, HelpMessage="The id of the tenant that the environment belongs to.")]
        [string]$TenantId,
    
        [Parameter(Mandatory=$false, HelpMessage="The BAP endpoint to connect to. Default is 'prod'.")]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod
    )
    
    $ErrorActionPreference = "Stop"
    
    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }
    
    $client = New-HttpClient
    
    $path = "/plex/resolveDns"
    $query = "api-version=2024-10-01"
    
    $Body = @{
        HostName = $HostName
    }
    
    $request = New-EnvironmentRouteRequest -EnvironmentId $EnvironmentId -Path $path -Query $query -AccessToken (Get-AccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Post) -Content ($Body | ConvertTo-Json) -Endpoint $Endpoint
    
    $result = Get-AsyncResult -Task $client.SendAsync($request)
    
    Test-Result -Result $result
    
    Get-AsyncResult -Task $result.Content.ReadAsStringAsync()
}