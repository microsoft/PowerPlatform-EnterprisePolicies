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

function New-HomeTenantRouteRequest
{
    param(
        [Parameter(Mandatory)]
        [string] $TenantId,
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

    $hostName = Get-TenantRouteHostName -Endpoint $Endpoint -TenantId $TenantId
    $uriBuilder = [System.UriBuilder]::new()
    $uriBuilder.Scheme = "https"
    $uriBuilder.Host = $hostName
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
        $script:httpClient.DefaultRequestHeaders.UserAgent.Add([System.Net.Http.Headers.ProductInfoHeaderValue]::new("Microsoft.PowerPlatform.EnterprisePolicies", (Get-ModuleVersion)))
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
    if($Endpoint -eq [BAPEndpoint]::tip1 -or $Endpoint -eq [BAPEndpoint]::tip2 -or $Endpoint -eq [BAPEndpoint]::usgovhigh) {
        $shortEnvId = $EnvironmentId.Substring($EnvironmentId.Length - 1, 1)
        $remainingEnvId = $EnvironmentId.Substring(0, $EnvironmentId.Length - 1)
    }
    else {
        $shortEnvId = $EnvironmentId.Substring($EnvironmentId.Length - 2, 2)
        $remainingEnvId = $EnvironmentId.Substring(0, $EnvironmentId.Length - 2)
    }
    return "$remainingEnvId.$shortEnvId.environment.$baseUri"
}

function Get-TenantRouteHostName {
    param (
        [Parameter(Mandatory)]
        [string] $TenantId,
        [Parameter(Mandatory)]
        [BAPEndpoint] $Endpoint
    )

    $baseUri = Get-APIResourceUrl -Endpoint $Endpoint
    # Separate the scheme from the base URI
    $baseUri = $baseUri.Replace("https://", "").Trim('/')
    $TenantId = $TenantId.Replace("-", "")
    if($Endpoint -eq [BAPEndpoint]::tip1 -or $Endpoint -eq [BAPEndpoint]::tip2 -or $Endpoint -eq [BAPEndpoint]::usgovhigh) {
        $shortTenantId = $TenantId.Substring($TenantId.Length - 1, 1)
        $remainingTenantId = $TenantId.Substring(0, $TenantId.Length - 1)
    }
    else {
        $shortTenantId = $TenantId.Substring($TenantId.Length - 2, 2)
        $remainingTenantId = $TenantId.Substring(0, $TenantId.Length - 2)
    }
    return "il-$remainingTenantId.$shortTenantId.tenant.$baseUri"
}

function Get-BAPResourceUrl {
    param (
        [Parameter(Mandatory)]
        [BAPEndpoint] $Endpoint
    )

    switch ($Endpoint) {
        ([BAPEndpoint]::tip1) { return "https://preprod.powerplatform.com/" }
        ([BAPEndpoint]::tip2) { return "https://test.powerplatform.com/" }
        ([BAPEndpoint]::prod) { return "https://powerplatform.com/" }
        ([BAPEndpoint]::usgovhigh) { return "https://high.powerplatform.microsoft.us/" }
        ([BAPEndpoint]::dod) { return "https://appsplatform.us/" }
        ([BAPEndpoint]::china) { return "https://powerplatform.partner.microsoftonline.cn/" }
        Default { throw "Unsupported BAP endpoint: $Endpoint" }
    }
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
            $sleepSeconds = $DelaySeconds
            $result = Get-AsyncResult -Task $client.SendAsync((& $RequestFactory))

            if(Test-Result -Result $result) {
                return $result
            }
            
            # Check for 503 Service Unavailable or 429 Too Many Requests with Retry-After header
            if ($result.StatusCode -eq 503 -or $result.StatusCode -eq 429) {
                if ($result.Headers.Contains("Retry-After")) {
                    $retryAfterValue = $result.Headers.GetValues("Retry-After") | Select-Object -First 1
                    # Retry-After can be either seconds (integer) or HTTP date
                    if ($retryAfterValue -match '^\d+$') {
                        $sleepSeconds = [int]$retryAfterValue
                    } else {
                        try {
                            $retryAfterDate = [DateTime]::Parse($retryAfterValue)
                            if ($retryAfterDate.Kind -ne [System.DateTimeKind]::Utc) {
                                $retryAfterDate = $retryAfterDate.ToUniversalTime()
                            }
                            $sleepSeconds = [Math]::Max(1, [int]($retryAfterDate - [DateTime]::UtcNow).TotalSeconds)
                        } catch {
                            Write-Verbose "Could not parse Retry-After header value: $retryAfterValue. Using default delay."
                            $sleepSeconds = $DelaySeconds
                        }
                    }
                    Write-Host "The service is working on the request and has requested a retry. Waiting for $sleepSeconds seconds as indicated by the Retry-After header..." -ForegroundColor Yellow
                }
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
        Write-Verbose "Request failed on attempt $attempt. Retrying in $sleepSeconds seconds..."
        Start-Sleep -Seconds $sleepSeconds
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
            Write-Verbose "$(Get-LogDate): API Call returned $($Result.StatusCode): $($errorMessage). Correlation ID: $($($Result.Headers.GetValues("x-ms-correlation-id") | Select-Object -First 1))"
            return $false
        }
        else
        {
            Write-Verbose "$(Get-LogDate): API Call returned $($Result.StatusCode): $($Result.ReasonPhrase). Correlation ID: $($($Result.Headers.GetValues("x-ms-correlation-id") | Select-Object -First 1))"
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
            Write-Verbose "$(Get-LogDate): API Call returned $($Result.StatusCode): $($errorMessage). Correlation ID: $($($Result.Headers.GetValues("x-ms-correlation-id") | Select-Object -First 1))"
            throw "$(Get-LogDate): API Call returned $($Result.StatusCode): $($errorMessage). Correlation ID: $($($Result.Headers.GetValues("x-ms-correlation-id") | Select-Object -First 1))"
        }
        else
        {
            Write-Verbose "$(Get-LogDate): API Call returned $($Result.StatusCode): $($Result.ReasonPhrase). Correlation ID: $($($Result.Headers.GetValues("x-ms-correlation-id") | Select-Object -First 1))"
            throw "$(Get-LogDate): API Call returned $($Result.StatusCode): $($Result.ReasonPhrase). Correlation ID: $($($Result.Headers.GetValues("x-ms-correlation-id") | Select-Object -First 1))"
        }
    }
}

function ConvertFrom-JsonToClass {
    param (
        [string]$Json,
        [Type]$ClassType
    )

    $data = $Json | ConvertFrom-Json
    
    # Handle array types directly
    if ($ClassType.IsArray) {
        $elementType = $ClassType.GetElementType()
        $itemList = @()
        foreach ($item in $data) {
            $itemJson = $item | ConvertTo-Json -Depth 10
            $itemList += ConvertFrom-JsonToClass -Json $itemJson -ClassType $elementType
        }
        return ,$itemList  
    }
    
    # Handle primitive types and strings
    if ($ClassType.IsPrimitive -or $ClassType -eq [string]) {
        return ($data -as $ClassType)
    }
    # Handle common value types explicitly
    if ($ClassType -eq [DateTime]) {
        return [DateTime]::Parse($data)
    }
    if ($ClassType.FullName -eq 'System.Guid') {
        return [Guid]::Parse($data)
    }
    if ($ClassType.FullName -eq 'System.Decimal') {
        return [Decimal]::Parse($data)
    }
    
    # Handle complex types
    $instance = [Activator]::CreateInstance($ClassType)

    foreach ($property in $ClassType.GetProperties()) {
        $name = $property.Name
        $type = Get-UnderlyingType $property.PropertyType
        if ($data.PSObject.Properties[$name]) {
            if ($type -eq [hashtable] -or $type.FullName -eq 'System.Collections.Hashtable') {
                $instance.$name = ConvertTo-Hashtable $data.$name
            }
            elseif ($type.IsClass -and $type -ne [string]) {
                $nestedJson = $data.$name | ConvertTo-Json -Depth 10
                $instance.$name = ConvertFrom-JsonToClass -Json $nestedJson -ClassType $type
            }
            else {
                $instance.$name = $data.$name
            }
        }
    }

    return $instance
}


function Get-UnderlyingType([type]$t) {
    if ($t.IsGenericType -and $t.GetGenericTypeDefinition().FullName -eq 'System.Nullable`1') {
        return $t.GetGenericArguments()[0]
    }
    return $t
}

function ConvertTo-Hashtable($obj) {
    if ($obj -is [hashtable]) {
        return $obj
    }
    $hash = @{}
    foreach ($property in $obj.PSObject.Properties) {
        $hash[$property.Name] = $property.Value
    }
    return $hash
}
