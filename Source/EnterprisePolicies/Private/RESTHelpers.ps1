<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
    Import this module to get functions to help handling REST calls.
    
.DESCRIPTION
    This script can be imported to enable cmdlets to deal with HTTP connection and JSON messages.

.NOTES
    Copyright © 2025 Microsoft. All rights reserved.
#>

<#
.SYNOPSIS
    Create new HttpRequestMessage object and set Json content and authorization header
#>

function New-JsonRequestMessage
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$Uri,
        [Parameter(Mandatory=$true)]
        [string]$AccessToken,
        [Parameter(Mandatory=$false)]
        [string]$Content,
        [Parameter(Mandatory=$false)]
        [System.Net.Http.HttpMethod]$HttpMethod = [System.Net.Http.HttpMethod]::Post
    )

    Write-Host "Creating request for URI: $Uri" -ForegroundColor Cyan
    $request = New-Object -TypeName System.Net.Http.HttpRequestMessage -ArgumentList @($HttpMethod, $Uri)
    if ($Content)
    {
        $request.Content = New-Object -TypeName System.Net.Http.StringContent -ArgumentList @($Content, [System.Text.Encoding]::UTF8, "application/json")
    }
    $request.Headers.Authorization = "Bearer $AccessToken"

    return $request
}

<#
.SYNOPSIS
    Create new HttpClient object and clear Default Request Headers
#>
function New-HttpClient
{
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls13 -bor [System.Net.SecurityProtocolType]::Tls12
    
    $client = New-Object -TypeName System.Net.Http.HttpClient
    $client.DefaultRequestHeaders.Clear()

    return $client
}

<#
.SYNOPSIS
    Given an async Task, await and return its result
#>
function Get-AsyncResult
{
    param(
        [Parameter(Mandatory=$true)]
        $task
    )

    try
    {
        $result = $task.GetAwaiter().GetResult()
    }
    catch
    {
        if ($_.Exception.InnerException)
        {
            # Two levels into inner exceptions have network connection problem messages
            if ($_.Exception.InnerException.InnerException)
            {
                throw $_.Exception.InnerException.InnerException.Message
            }
            else
            {
                throw $_.Exception.InnerException.Message   
            }
        }
        else
        {
            throw $_.Exception.Message
        }
    }

    return $result
}

function Get-EnvironmentRoute {
    param (
        [Parameter(Mandatory)]
        [string] $EnvironmentId,
        [Parameter(Mandatory)]
        [BAPEndpoint] $Endpoint
    )

    $baseUri = Get-APIResourceUrl -Endpoint $Endpoint
    # Separate the scheme from the base URI
    $baseUri = $baseUri.Replace("https://", "").Trim('/')
    $EnvironmentId = $EnvironmentId.Replace("-", "")
    if($Endpoint -eq [BAPEndpoint]::tip1 -or $Endpoint -eq [BAPEndpoint]::tip2) {
        $shortEnvId = $EnvironmentId.Substring($EnvironmentId.Length - 1, 1)
        $remainingEnvId = $EnvironmentId.Substring(0, $EnvironmentId.Length - 1)
    }
    else {
        $shortEnvId = $EnvironmentId.Substring($EnvironmentId.Length - 2, 2)
        $remainingEnvId = $EnvironmentId.Substring(0, $EnvironmentId.Length - 2)
    }
    return "https://$remainingEnvId.$shortEnvId.environment.$baseUri"
}

function Get-APIResourceUrl {
    param (
        [Parameter(Mandatory)]
        [BAPEndpoint] $Endpoint
    )

    switch ($Endpoint) {
        ([BAPEndpoint]::tip1) { return "https://api.preprod.powerplatform.com/" }
        ([BAPEndpoint]::tip2) { return "https://api.test.powerplatform.com/" }
        ([BAPEndpoint]::prod) { return "https://api.powerplatform.com/" }
        ([BAPEndpoint]::usgovhigh) { return "https://api.high.powerplatform.microsoft.us/" }
        ([BAPEndpoint]::dod) { return "https://api.appsplatform.us/" }
        ([BAPEndpoint]::china) { return "https://api.powerplatform.partner.microsoftonline.cn/" }
        Default { throw "Unsupported BAP endpoint: $Endpoint" }
    }
}

function Test-Result {
    param (
        [Parameter(Mandatory)]
        $Result
    )

    if ($result.StatusCode -ne [System.Net.HttpStatusCode]::OK)
    {
        throw "API Call returned $($result.StatusCode): $($result.ReasonPhrase). Correlation ID: $($result.Headers.GetValues("x-ms-correlation-id") | Select-Object -First 1)"
    }
}