<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

$script:CachePath = Join-Path $([Environment]::GetFolderPath('LocalApplicationData')) 'Microsoft.PowerPlatform.EnterprisePolicies\config.json'
$script:CacheData = $null

function Get-EmptyCache{
    return [PSCustomObject]@{
        Version = "1.0"
        SubscriptionsValidated = @()
        RegionCache = [PSCustomObject]@{}
    }
}

function Initialize-Cache{
    if(-not(Test-Path -Path $script:CachePath)){
        Write-Verbose "Cache file not found. Initializing new cache."
        $script:CacheData = Get-EmptyCache
    }
    else{
        Write-Verbose "Loading cache from $script:CachePath"
        $content = Get-Content -Path $script:CachePath
        if([string]::IsNullOrWhiteSpace($content)){
            Write-Verbose "Cache file is empty. Initializing new cache."
            $script:CacheData = Get-EmptyCache
        }
        else{
            $script:CacheData = $content | ConvertFrom-Json
            if(-not($script:CacheData.PSObject.Properties.Name -contains 'RegionCache')){
                $script:CacheData | Add-Member -NotePropertyName "RegionCache" -NotePropertyValue ([PSCustomObject]@{})
            }
        }
    }
}

function Save-Cache{
    if(-not(Test-Path -Path (Split-Path -Path $script:CachePath))){
        New-Item -ItemType Directory -Path (Split-Path -Path $script:CachePath) -Force | Out-Null
    }
    $script:CacheData | ConvertTo-Json | Out-File -FilePath $script:CachePath -Force
}

function Test-SubscriptionValidated{
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SubscriptionId
    )

    return $script:CacheData.SubscriptionsValidated -contains $SubscriptionId
}

function Add-ValidatedSubscriptionToCache{
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SubscriptionId
    )

    if(-not($script:CacheData.SubscriptionsValidated -contains $SubscriptionId)){
        $script:CacheData.SubscriptionsValidated += $SubscriptionId
        Save-Cache
    }
}

function Get-EnvironmentRegionFromCache{
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory)]
        [PPEndpoint]$Endpoint,

        [Parameter(Mandatory=$false)]
        [string]$TenantId
    )

    $cacheKey = "$EnvironmentId|$Endpoint"

    # Check for cached entry
    if($script:CacheData.RegionCache.PSObject.Properties.Name -contains $cacheKey){
        $entry = $script:CacheData.RegionCache.$cacheKey
        $expiry = [DateTime]::Parse($entry.Expiry).ToUniversalTime()
        if($expiry -gt [DateTime]::UtcNow){
            Write-Verbose "Region cache hit for $cacheKey"
            return $entry.Region
        }
    }

    # Cache miss or expired - call Get-EnvironmentRegion
    Write-Verbose "Region cache miss for $cacheKey. Calling Get-EnvironmentRegion."
    $params = @{
        EnvironmentId = $EnvironmentId
        Endpoint = $Endpoint
    }
    if(-not([string]::IsNullOrWhiteSpace($TenantId))){
        $params["TenantId"] = $TenantId
    }

    $region = Get-EnvironmentRegion @params

    # Store in cache with 1-hour expiry
    $cacheEntry = [PSCustomObject]@{
        Region = $region
        Expiry = [DateTime]::UtcNow.AddHours(1).ToString("o")
    }
    if($script:CacheData.RegionCache.PSObject.Properties.Name -contains $cacheKey){
        $script:CacheData.RegionCache.$cacheKey = $cacheEntry
    }
    else{
        $script:CacheData.RegionCache | Add-Member -NotePropertyName $cacheKey -NotePropertyValue $cacheEntry
    }

    Save-Cache
    return $region
}