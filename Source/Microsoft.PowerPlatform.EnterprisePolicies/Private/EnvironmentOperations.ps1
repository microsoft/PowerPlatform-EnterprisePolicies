<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

function Get-BAPEnvironment {
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentId,
        [Parameter(Mandatory)]
        [BAPEndpoint]$Endpoint,
        [Parameter(Mandatory=$false)]
        [string]$TenantId
    )

    $apiVersion = "2016-11-01"
    $baseUri = Get-BAPEndpointUrl -Endpoint $Endpoint
    $uri = "${baseUri}providers/Microsoft.BusinessAppPlatform/environments/${EnvironmentId}?api-version=${apiVersion}"

    $result = Send-RequestWithRetries -RequestFactory {
        return New-JsonRequestMessage -Uri $uri -AccessToken (Get-BAPAccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Get)
     } -MaxRetries 3 -DelaySeconds 5

    if (-not $result.IsSuccessStatusCode) {
        $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()
        throw "Failed to retrieve environment. Status code: $($result.StatusCode). $contentString"
    }

    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()
    $contentString
    $environment = $contentString | ConvertFrom-Json

    return $environment
}
