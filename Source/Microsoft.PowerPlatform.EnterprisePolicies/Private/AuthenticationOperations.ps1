<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

function Select-PreferredContext {
    param(
        $Contexts
    )
    if ($null -eq $Contexts) {
        return $null
    }
    # Prefer ServicePrincipal over User accounts
    $spContext = $Contexts | Where-Object { $_.Account.Type -eq "ServicePrincipal" } | Select-Object -First 1
    if ($spContext) {
        return $spContext
    }
    return $Contexts | Select-Object -First 1
}

function Connect-Azure {
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByEndpoint')]
        [ValidateNotNullOrEmpty()]
        [BAPEndpoint]$Endpoint,
        [Parameter(Mandatory, ParameterSetName = 'ByEnvironment')]
        [ValidateNotNullOrEmpty()]
        [AzureEnvironment] $AzureEnvironment,
        [Parameter(Mandatory=$false, ParameterSetName = 'ByEndpoint')]
        [Parameter(Mandatory=$false, ParameterSetName = 'ByEnvironment')]
        [string]$TenantId = $null,
        [Parameter(Mandatory=$false, ParameterSetName = 'ByEndpoint')]
        [Parameter(Mandatory=$false, ParameterSetName = 'ByEnvironment')]
        [string]$AuthScope = $null,
        [Parameter(Mandatory=$false, ParameterSetName = 'ByEndpoint')]
        [Parameter(Mandatory=$false, ParameterSetName = 'ByEnvironment')]
        [switch]$Force
    )

    if($PSCmdlet.ParameterSetName -eq 'ByEndpoint') {
        $AzureEnvironment = switch ($Endpoint) {
            ([BAPEndpoint]::china) { "AzureChinaCloud" }
            ([BAPEndpoint]::dod) { "AzureUSGovernment" }
            ([BAPEndpoint]::usgovhigh) { "AzureUSGovernment" }
            Default { "AzureCloud" }
        }
    }

    $context = Get-AzContext -ListAvailable
    $foundContext = $false

    if(-not($Force) -and [string]::IsNullOrWhiteSpace($AuthScope) -and $null -ne $context) {
        if([string]::IsNullOrWhiteSpace($TenantId)) {
            $matchedContexts = $context | Where-Object { $_.Environment.Name -eq $AzureEnvironment }
            $matchedContext = Select-PreferredContext -Contexts $matchedContexts
            if($matchedContext) {
                Set-AzContext -Context $matchedContext
                Write-Host "Already connected to Azure environment: $AzureEnvironment with account $($matchedContext.Account.Id) with tenants [$($matchedContext.Account.Tenants -join ",")]" -ForegroundColor Yellow
                $foundContext = $true
            }
        }
        else {
            # Prioritize the home tenant if it exists
            $homeTenantContexts = $context | Where-Object { $_.Environment.Name -eq $AzureEnvironment -and $_.Tenant.TenantCategory -eq "Home" -and $_.Tenant.Id -eq $TenantId }
            $homeTenantContext = Select-PreferredContext -Contexts $homeTenantContexts
            if($homeTenantContext) {
                Set-AzContext -Context $homeTenantContext
                Write-Host "Already connected to Azure environment: $AzureEnvironment with account $($homeTenantContext.Account.Id) with home tenant Id $TenantId" -ForegroundColor Yellow
                $foundContext = $true
            }
            else {
                $tenantContexts = $context | Where-Object { $_.Environment.Name -eq $AzureEnvironment -and $_.Account.Tenants -contains $TenantId }
                $tenantContext = Select-PreferredContext -Contexts $tenantContexts
                if ($tenantContext) {
                    Set-AzContext -Context $tenantContext
                    Write-Host "Already connected to Azure environment: $AzureEnvironment with account $($tenantContext.Account.Id) with tenant Id $TenantId" -ForegroundColor Yellow
                    $foundContext = $true
                }
            }
        }
    }

    if ($foundContext) {
        return $true
    }

    Write-Host "Logging In..." -ForegroundColor Green
    $connectParameters = @{
        Environment = $AzureEnvironment        
    }
    if(-not([string]::IsNullOrWhiteSpace($TenantId))) {
        $connectParameters['Tenant'] = $TenantId
    }
    if(-not([string]::IsNullOrWhiteSpace($AuthScope))) {
        $connectParameters['AuthScope'] = $AuthScope
    }

    $connect = Connect-AzAccount @connectParameters

    if ($null -eq $connect)
    {
        Write-Host "Error connecting to Azure Account" -ForegroundColor Red
        return $false
    }

    Write-Host "Logged In..." -ForegroundColor Green
    return $true
}

function Get-BAPAccessToken {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [BAPEndpoint]$Endpoint,

        [Parameter(Mandatory=$false)]
        [string]$TenantId = $null
    )

    $resourceUrl = Get-BAPResourceUrl -Endpoint $Endpoint
    return Get-AccessToken -Endpoint $Endpoint -ResourceUrl $resourceUrl -TenantId $TenantId
}

function Get-PPAPIAccessToken {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [BAPEndpoint]$Endpoint,

        [Parameter(Mandatory=$false)]
        [string]$TenantId = $null
    )

    $resourceUrl = Get-APIResourceUrl -Endpoint $Endpoint

    return Get-AccessToken -Endpoint $Endpoint -ResourceUrl $resourceUrl -TenantId $TenantId
}

function Get-AccessToken {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [BAPEndpoint]$Endpoint,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceUrl,

        [Parameter(Mandatory=$false)]
        [string]$TenantId = $null
    )

    $token = Get-AzAccessToken -ResourceUrl $resourceUrl -AsSecureString -ErrorAction SilentlyContinue
    if ($null -eq $token) {
        $tokenError = $global:Error[0]
        if($tokenError.Exception.AuthenticationErrorCode -eq "failed_to_acquire_token_silently_from_broker")
        {
            Write-Host "Failed to acquire token silently. Please log in interactively." -ForegroundColor Red
            Connect-Azure -AuthScope $resourceUrl -Endpoint $Endpoint -TenantId $TenantId
            $token = Get-AzAccessToken -ResourceUrl $resourceUrl -AsSecureString
        }
        else
        {
            Write-Host "Failed to acquire access token: $($tokenError.Exception.AuthenticationErrorCode)" -ForegroundColor Red
            Connect-Azure -AuthScope $resourceUrl -Endpoint $Endpoint -TenantId $TenantId -Force
        }

        if($null -eq $token) {
            throw "Failed to acquire access token. Please check your Azure login and try again."
        }
    }
    return ConvertFrom-SecureStringInternal -SecureString $token.Token
}

function ConvertFrom-SecureStringInternal {
    param (
        [Parameter(Mandatory)]
        [System.Security.SecureString]$SecureString
    )

    try{
        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
        return $plainText
    }
    catch {
        throw "Failed to convert SecureString to plain text: $_"
    }
    finally {
        if ($ptr) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
        }
    }
}

# Module-scoped cache for Authorization Service MSAL applications
# Key: "Endpoint|TenantId|ClientId", Value: @{ App = <MSAL app>; Account = <cached account> }
$script:AuthorizationServiceCache = @{}
$script:AuthorizationServiceCurrentKey = $null

function New-AuthorizationServiceMsalClient {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory = $false)]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $cacheKey = "$Endpoint|$TenantId|$ClientId"

    # Check if we have a cached client for this configuration
    if (-not $Force -and $script:AuthorizationServiceCache.ContainsKey($cacheKey)) {
        Write-Verbose "Reusing cached Authorization Service MSAL client for: $cacheKey"
        $script:AuthorizationServiceCurrentKey = $cacheKey
        return $true
    }

    # Determine the authority based on endpoint
    $authority = switch ($Endpoint) {
        ([BAPEndpoint]::china) { "https://login.chinacloudapi.cn/$TenantId" }
        { $_ -in [BAPEndpoint]::dod, [BAPEndpoint]::usgovhigh } { "https://login.microsoftonline.us/$TenantId" }
        default { "https://login.microsoftonline.com/$TenantId" }
    }

    Write-Verbose "Creating Authorization Service MSAL client with authority: $authority"

    # Build the public client application with localhost redirect for interactive auth
    $builder = Get-PublicClientApplicationBuilder -ClientId $ClientId
    $app = $builder.WithAuthority($authority).WithRedirectUri("http://localhost").Build()

    if ($null -eq $app) {
        throw "Failed to create Authorization Service application."
    }

    # Store in cache
    $script:AuthorizationServiceCache[$cacheKey] = @{
        App = $app
        Account = $null
    }
    $script:AuthorizationServiceCurrentKey = $cacheKey

    Write-Verbose "Successfully created Authorization Service MSAL client application."
    return $true
}

function Get-AuthorizationServiceToken {
    param(
        [Parameter(Mandatory=$false)]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod,

        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 60
    )

    if ($null -eq $script:AuthorizationServiceCurrentKey -or -not $script:AuthorizationServiceCache.ContainsKey($script:AuthorizationServiceCurrentKey)) {
        throw "Authorization Service MSAL client application not created. Call New-AuthorizationServiceMsalClient first."
    }

    $resourceUrl = Get-APIResourceUrl -Endpoint $Endpoint
    $Scopes = @("$resourceUrl.default")

    $cached = $script:AuthorizationServiceCache[$script:AuthorizationServiceCurrentKey]
    $app = $cached.App
    $account = $cached.Account

    # Create cancellation token with timeout
    $cts = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($TimeoutSeconds))

    try {
        # Try to acquire token silently first if we have a cached account
        if ($null -ne $account) {
            Write-Verbose "Attempting silent token acquisition for scopes: $($Scopes -join ', ')"
            try {
                $result = $app.AcquireTokenSilent($Scopes, $account).ExecuteAsync($cts.Token).GetAwaiter().GetResult()
                if ($null -ne $result -and -not [string]::IsNullOrEmpty($result.AccessToken)) {
                    Write-Verbose "Successfully acquired token silently for account: $($result.Account.Username)"
                    return $result.AccessToken
                }
            }
            catch [System.OperationCanceledException] {
                throw "Token acquisition timed out after $TimeoutSeconds seconds."
            }
            catch {
                Write-Verbose "Silent token acquisition failed: $($_.Exception.Message). Falling back to interactive."
            }
        }

        # Fall back to interactive authentication
        Write-Verbose "Acquiring token interactively for scopes: $($Scopes -join ', ')"
        try {
            $result = $app.AcquireTokenInteractive($Scopes).ExecuteAsync($cts.Token).GetAwaiter().GetResult()
        }
        catch [System.OperationCanceledException] {
            throw "Interactive authentication timed out after $TimeoutSeconds seconds. Please try again."
        }

        if ($null -eq $result -or [string]::IsNullOrEmpty($result.AccessToken)) {
            throw "Failed to acquire access token interactively."
        }

        # Cache the account for future silent acquisitions
        $script:AuthorizationServiceCache[$script:AuthorizationServiceCurrentKey].Account = $result.Account
        Write-Verbose "Successfully acquired token for account: $($result.Account.Username)"
        return $result.AccessToken
    }
    finally {
        $cts.Dispose()
    }
}