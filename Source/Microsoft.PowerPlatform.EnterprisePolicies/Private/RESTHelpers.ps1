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
        [string] $Uri,
        [Parameter(Mandatory=$true)]
        [System.Security.SecureString] $AccessToken,
        [Parameter(Mandatory=$false)]
        [string] $Content,
        [Parameter(Mandatory=$false)]
        [System.Net.Http.HttpMethod] $HttpMethod = [System.Net.Http.HttpMethod]::Post
    )

    Write-Verbose "Creating request for URI: $Uri"
    $request = New-Object -TypeName System.Net.Http.HttpRequestMessage -ArgumentList @($HttpMethod, $Uri)
    if ($Content)
    {
        $request.Content = New-Object -TypeName System.Net.Http.StringContent -ArgumentList @($Content, [System.Text.Encoding]::UTF8, "application/json")
    }
    $request.Headers.Authorization = "Bearer $(ConvertFrom-SecureStringInternal $AccessToken)"

    return $request
}

function New-EnvironmentRouteRequest
{
    param(
        [Parameter(Mandatory)]
        [string] $EnvironmentId,
        [Parameter(Mandatory)]
        [string] $Path,
        [Parameter(Mandatory)]
        [string] $Query,
        [Parameter(Mandatory)]
        [BAPEndpoint] $Endpoint,
        [Parameter(Mandatory=$true)]
        [System.Security.SecureString] $AccessToken,
        [Parameter(Mandatory=$false)]
        [string] $Content,
        [Parameter(Mandatory=$false)]
        [System.Net.Http.HttpMethod] $HttpMethod = [System.Net.Http.HttpMethod]::Post
    )

    $hostName = Get-EnvironmentRouteHostName -Endpoint $Endpoint -EnvironmentId $EnvironmentId
    $uriBuilder = [System.UriBuilder]::new()
    $uriBuilder.Scheme = "https"
    $uriBuilder.Host = "primary-$hostName"
    $uriBuilder.Path = $Path
    $uriBuilder.Query = $Query

    $request = New-JsonRequestMessage -Uri $uriBuilder.Uri.ToString() -AccessToken $AccessToken -Content $Content -HttpMethod $HttpMethod
    $request.Headers.Host = $hostName
    return $request
}

<#
.SYNOPSIS
    Gets a singleton HttpClient object or creates a new one and clears Default Request Headers
#>
function Get-HttpClient
{
    if($null -eq $script:httpClient)
    {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls13 -bor [System.Net.SecurityProtocolType]::Tls12
    
        $script:httpClient = New-Object -TypeName System.Net.Http.HttpClient
        $script:httpClient.DefaultRequestHeaders.Clear()
    }

    return $script:httpClient
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

function Get-EnvironmentRouteHostName {
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
    return "$remainingEnvId.$shortEnvId.environment.$baseUri"
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

function Send-RequestWithRetries {
    param (
        [Parameter(Mandatory)]
        [int] $MaxRetries,
        [Parameter(Mandatory)]
        [int] $DelaySeconds,
        [Parameter(Mandatory)]
        [scriptblock] $RequestFactory
    )

    $client = Get-HttpClient
    $attempt = 0
    while ($attempt -lt $MaxRetries) {
        try {
            $result = Get-AsyncResult -Task $client.SendAsync((& $RequestFactory))

            if(Test-Result -Result $result) {
                return $result
            }
            $attempt++
        }
        catch {
            $attempt++
            Write-Verbose "Exception on attempt $attempt : $($_.Exception.Message)"
            if($attempt -ge $MaxRetries) {
                throw "Request failed after $MaxRetries attempts. Last error: $($_.Exception.Message)"
            }
        }

        if ($attempt -ge $MaxRetries) {
            Write-Host "Request failed after $MaxRetries attempts." -ForegroundColor Red
            Assert-Result -Result $result
        }
        Write-Verbose "Request failed on attempt $attempt. Retrying in $DelaySeconds seconds..."
        Start-Sleep -Seconds $DelaySeconds
    }
}

function Test-Result {
    param (
        [Parameter(Mandatory)]
        $Result
    )

    if (-not($Result.IsSuccessStatusCode))
    {
        $contentString = Get-AsyncResult -Task $Result.Content.ReadAsStringAsync()
        if ($contentString)
        {
            $errorMessage = $contentString.Trim('.')
            Write-Verbose "API Call returned $($Result.StatusCode): $($errorMessage). Correlation ID: $($($Result.Headers.GetValues("x-ms-correlation-id") | Select-Object -First 1))"
            return $false
        }
        else
        {
            Write-Verbose "API Call returned $($Result.StatusCode): $($Result.ReasonPhrase). Correlation ID: $($($Result.Headers.GetValues("x-ms-correlation-id") | Select-Object -First 1))"
            return $false
        }
    }
    return $true
}

function Assert-Result {
    param (
        [Parameter(Mandatory)]
        $Result
    )

    if (-not($Result.IsSuccessStatusCode))
    {
        $contentString = Get-AsyncResult -Task $Result.Content.ReadAsStringAsync()
        if ($contentString)
        {
            $errorMessage = $contentString.Trim('.')
            Write-Verbose "API Call returned $($Result.StatusCode): $($errorMessage). Correlation ID: $($($Result.Headers.GetValues("x-ms-correlation-id") | Select-Object -First 1))"
            throw "API Call returned $($Result.StatusCode): $($errorMessage). Correlation ID: $($($Result.Headers.GetValues("x-ms-correlation-id") | Select-Object -First 1))"
        }
        else
        {
            Write-Verbose "API Call returned $($Result.StatusCode): $($Result.ReasonPhrase). Correlation ID: $($($Result.Headers.GetValues("x-ms-correlation-id") | Select-Object -First 1))"
            throw "API Call returned $($Result.StatusCode): $($Result.ReasonPhrase). Correlation ID: $($($Result.Headers.GetValues("x-ms-correlation-id") | Select-Object -First 1))"
        }
    }
}

function ConvertFrom-JsonToClass {
    param (
        [string]$Json,
        [Type]$ClassType
    )

    $data = $Json | ConvertFrom-Json
    $instance = [Activator]::CreateInstance($ClassType)

    foreach ($property in $ClassType.GetProperties()) {
        $name = $property.Name
        if ($data.PSObject.Properties[$name]) {
            $instance.$name = $data.$name
        }
    }

    return $instance
}