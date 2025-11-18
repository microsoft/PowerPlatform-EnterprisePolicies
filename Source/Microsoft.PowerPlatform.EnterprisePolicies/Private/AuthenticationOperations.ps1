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

function Get-AccessToken {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [BAPEndpoint]$Endpoint,

        [Parameter(Mandatory=$false)]
        [string]$TenantId = $null
    )

    $resourceUrl = Get-APIResourceUrl -Endpoint $Endpoint

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