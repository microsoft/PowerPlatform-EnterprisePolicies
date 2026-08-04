<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

function Connect-Azure {
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByEndpoint')]
        [ValidateNotNullOrEmpty()]
        [PPEndpoint]$Endpoint,
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
            ([PPEndpoint]::china) { "AzureChinaCloud" }
            ([PPEndpoint]::dod) { "AzureUSGovernment" }
            ([PPEndpoint]::usgovhigh) { "AzureUSGovernment" }
            Default { "AzureCloud" }
        }
    }

    # When re-authentication is not forced, honor a cached service principal auth
    # configuration and prioritize that flow over the default interactive login.
    if(-not($Force)) {
        $servicePrincipalConfig = Get-CachedServicePrincipalAuth
        if($null -ne $servicePrincipalConfig) {
            return Connect-AzureWithServicePrincipal -Config $servicePrincipalConfig -AzureEnvironment $AzureEnvironment -TenantId $TenantId
        }
    }

    $context = Get-AzContext -ListAvailable
    $foundContext = $false

    if(-not($Force) -and [string]::IsNullOrWhiteSpace($AuthScope) -and $null -ne $context) {
        if([string]::IsNullOrWhiteSpace($TenantId)) {
            $matchedContext = $context | Where-Object { $_.Environment.Name -eq $AzureEnvironment } | Select-Object -First 1
            if($matchedContext) {
                Set-AzContext -Context $matchedContext
                Write-Host "Already connected to Azure environment: $AzureEnvironment with account $($matchedContext.Account.Id) with tenants [$($matchedContext.Account.Tenants -join ",")]" -ForegroundColor Yellow
                $foundContext = $true
            }
        }
        else {
            # Prioritize the home tenant if it exists
            $homeTenantContext = $context | Where-Object { $_.Environment.Name -eq $AzureEnvironment -and $_.Tenant.TenantCategory -eq "Home" -and $_.Tenant.Id -eq $TenantId } | Select-Object -First 1
            if($homeTenantContext) {
                Set-AzContext -Context $homeTenantContext
                Write-Host "Already connected to Azure environment: $AzureEnvironment with account $($homeTenantContext.Account.Id) with home tenant Id $TenantId" -ForegroundColor Yellow
                $foundContext = $true
            }
            else {
                $tenantContext = $context | Where-Object { $_.Environment.Name -eq $AzureEnvironment -and $_.Account.Tenants -contains $TenantId } | Select-Object -First 1
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

function Resolve-CertificateThumbprint {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SubjectName
    )

    $stores = @("Cert:\CurrentUser\My", "Cert:\LocalMachine\My")
    foreach ($store in $stores) {
        $cert = Get-ChildItem -Path $store -ErrorAction SilentlyContinue |
            Where-Object { $_.Subject -eq $SubjectName -or $_.Subject -like "*CN=$SubjectName*" } |
            Sort-Object -Property NotAfter -Descending |
            Select-Object -First 1
        if ($null -ne $cert) {
            return $cert.Thumbprint
        }
    }

    throw "Could not find a certificate with subject name '$SubjectName' in the CurrentUser or LocalMachine 'My' store."
}

function Connect-AzureWithServicePrincipal {
    param(
        [Parameter(Mandatory)]
        [object]$Config,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AzureEnvironment,

        [Parameter(Mandatory=$false)]
        [string]$TenantId = $null
    )

    $method = $Config.Method
    if ([string]::IsNullOrWhiteSpace($method)) {
        throw "Service principal auth configuration is missing the 'Method' property. Expected 'ManagedIdentity' or 'Certificate'."
    }

    $clientId = $Config.ClientId
    $effectiveTenantId = if (-not [string]::IsNullOrWhiteSpace($TenantId)) { $TenantId } else { $Config.TenantId }

    # Reuse an existing matching context when one is already available.
    $existingContexts = Get-AzContext -ListAvailable | Where-Object {
        $_.Environment.Name -eq $AzureEnvironment -and $_.Account.Id -eq $clientId
    }
    if (-not [string]::IsNullOrWhiteSpace($effectiveTenantId)) {
        $existingContexts = $existingContexts | Where-Object {
            $_.Tenant.Id -eq $effectiveTenantId -or $_.Account.Tenants -contains $effectiveTenantId
        }
    }
    $existingContext = $existingContexts | Select-Object -First 1
    if ($existingContext) {
        Set-AzContext -Context $existingContext
        Write-Host "Already connected to Azure environment: $AzureEnvironment with service principal $($existingContext.Account.Id)" -ForegroundColor Yellow
        return $true
    }

    $connectParameters = @{
        Environment = $AzureEnvironment
    }

    switch ($method) {
        "ManagedIdentity" {
            $connectParameters['Identity'] = $true
            if (-not [string]::IsNullOrWhiteSpace($clientId)) {
                $connectParameters['AccountId'] = $clientId
            }
            if (-not [string]::IsNullOrWhiteSpace($effectiveTenantId)) {
                $connectParameters['Tenant'] = $effectiveTenantId
            }
            Write-Host "Logging in with managed identity..." -ForegroundColor Green
        }
        "Certificate" {
            if ([string]::IsNullOrWhiteSpace($clientId)) {
                throw "Service principal auth configuration for 'Certificate' requires a 'ClientId'."
            }
            if ([string]::IsNullOrWhiteSpace($effectiveTenantId)) {
                throw "Service principal auth configuration for 'Certificate' requires a 'TenantId'."
            }

            $thumbprint = $Config.CertificateThumbprint
            if ([string]::IsNullOrWhiteSpace($thumbprint) -and -not [string]::IsNullOrWhiteSpace($Config.CertificateSubjectName)) {
                $thumbprint = Resolve-CertificateThumbprint -SubjectName $Config.CertificateSubjectName
            }
            if ([string]::IsNullOrWhiteSpace($thumbprint)) {
                throw "Service principal auth configuration for 'Certificate' requires either 'CertificateThumbprint' or 'CertificateSubjectName'."
            }

            $connectParameters['ServicePrincipal'] = $true
            $connectParameters['ApplicationId'] = $clientId
            $connectParameters['Tenant'] = $effectiveTenantId
            $connectParameters['CertificateThumbprint'] = $thumbprint
            Write-Host "Logging in with certificate-based service principal..." -ForegroundColor Green
        }
        default {
            throw "Unknown service principal auth method '$method'. Expected 'ManagedIdentity' or 'Certificate'."
        }
    }

    $connect = Connect-AzAccount @connectParameters

    if ($null -eq $connect) {
        Write-Host "Error connecting to Azure with service principal" -ForegroundColor Red
        return $false
    }

    Write-Host "Logged In..." -ForegroundColor Green
    return $true
}

function Get-PPAccessToken {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PPEndpoint]$Endpoint,

        [Parameter(Mandatory=$false)]
        [string]$TenantId = $null
    )

    $resourceUrl = Get-PPResourceUrl -Endpoint $Endpoint
    return Get-AccessToken -Endpoint $Endpoint -ResourceUrl $resourceUrl -TenantId $TenantId
}

function Get-PPAPIAccessToken {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PPEndpoint]$Endpoint,

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
        [PPEndpoint]$Endpoint,

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
        }
        elseif($null -ne $tokenError.Exception.AuthenticationErrorCode)
        {
            Write-Host "Failed to acquire access token: $($tokenError.Exception.AuthenticationErrorCode)" -ForegroundColor Red
            Connect-Azure -AuthScope $resourceUrl -Endpoint $Endpoint -TenantId $TenantId -Force
        }
        else {
            Write-Host "Failed to acquire access token: $($tokenError.Exception.Message)" -ForegroundColor Red
            Connect-Azure -AuthScope $resourceUrl -Endpoint $Endpoint -TenantId $TenantId -Force
        }

        $token = Get-AzAccessToken -ResourceUrl $resourceUrl -AsSecureString

        if($null -eq $token) {
            throw "Failed to acquire access token. Please check your Azure login and try again."
        }
    }
    return $token.Token
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
        [Parameter(Mandatory = $false)]
        [string]$ClientId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory = $false)]
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Resolve ClientId from cache if not provided; cache it if provided
    if ([string]::IsNullOrWhiteSpace($ClientId)) {
        $ClientId = Get-CachedAuthorizationServiceClientId
        if ([string]::IsNullOrWhiteSpace($ClientId)) {
            throw "ClientId was not provided and no cached ClientId was found. Run New-PPAuthorizationApplication or specify -ClientId."
        }
    }
    else {
        Set-CachedAuthorizationServiceClientId -AuthorizationServiceClientId $ClientId
    }

    $cacheKey = "$Endpoint|$TenantId|$ClientId"

    # Check if we have a cached client for this configuration
    if (-not $Force -and $script:AuthorizationServiceCache.ContainsKey($cacheKey)) {
        Write-Verbose "Reusing cached Authorization Service MSAL client for: $cacheKey"
        $script:AuthorizationServiceCurrentKey = $cacheKey
        return $true
    }

    # Determine the authority based on endpoint
    $authority = switch ($Endpoint) {
        ([PPEndpoint]::china) { "https://login.chinacloudapi.cn/$TenantId" }
        { $_ -in [PPEndpoint]::dod, [PPEndpoint]::usgovhigh } { "https://login.microsoftonline.us/$TenantId" }
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
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod,

        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 60
    )

    # Returns the access token as a SecureString so callers can use it directly without converting.
    if ($null -eq $script:AuthorizationServiceCurrentKey -or -not $script:AuthorizationServiceCache.ContainsKey($script:AuthorizationServiceCurrentKey)) {
        throw "Authorization Service MSAL client application not created. Call New-AuthorizationServiceMsalClient first."
    }

    $resourceUrl = (Get-APIResourceUrl -Endpoint $Endpoint).TrimEnd('/')
    [string[]]$Scopes = @("$resourceUrl/.default")

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
                    return (ConvertTo-SecureString -String $result.AccessToken -AsPlainText -Force)
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
        return (ConvertTo-SecureString -String $result.AccessToken -AsPlainText -Force)
    }
    finally {
        $cts.Dispose()
    }
}
