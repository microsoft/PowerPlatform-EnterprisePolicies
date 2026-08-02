<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

$script:CachePath = Join-Path $([Environment]::GetFolderPath('LocalApplicationData')) 'Microsoft.PowerPlatform.EnterprisePolicies\config.json'
$script:CacheData = $null
$script:CurrentCacheVersion = "1.1"

function Get-EmptyCache{
    return [PSCustomObject]@{
        Version = $script:CurrentCacheVersion
        SubscriptionsValidated = @()
        RegionCache = [PSCustomObject]@{}
        RoleDefinitions = @{}
        ClientId = ""
        Configuration = [PSCustomObject]@{}
    }
}

function Update-CacheVersion{
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Cache
    )

    while($Cache.Version -ne $script:CurrentCacheVersion){
        switch($Cache.Version){
            "1.0" {
                $Cache | Add-Member -NotePropertyName "RegionCache" -NotePropertyValue ([PSCustomObject]@{})
                $Cache.Version = "1.1"
                Write-Verbose "Upgraded cache from 1.0 to 1.1"
            }
            default {
                Write-Warning "Unknown cache version '$($Cache.Version)'. Resetting to empty cache."
                return Get-EmptyCache
            }
        }
    }

    return $Cache
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
            $script:CacheData = Update-CacheVersion -Cache $script:CacheData
            foreach($key in $script:CacheData.RegionCache.PSObject.Properties.Name){
                $entry = $script:CacheData.RegionCache.$key
                if($entry.Expiry -is [string]){
                    $entry.Expiry = [DateTime]::Parse($entry.Expiry).ToUniversalTime()
                }
            }
        }
    }
}

function Save-Cache{
    if(-not(Test-Path -Path (Split-Path -Path $script:CachePath))){
        New-Item -ItemType Directory -Path (Split-Path -Path $script:CachePath) -Force | Out-Null
    }
    $script:CacheData | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:CachePath -Force
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

function Get-CachedRoleDefinitions{
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Endpoint
    )

    # Ensure RoleDefinitions key exists (for caches created before this feature)
    if($null -eq $script:CacheData.RoleDefinitions){
        $script:CacheData | Add-Member -NotePropertyName "RoleDefinitions" -NotePropertyValue @{} -Force
    }

    $entry = $script:CacheData.RoleDefinitions.$Endpoint
    if($null -eq $entry){
        return $null
    }

    $fetchedAt = [DateTime]::Parse($entry.fetchedAt).ToUniversalTime()
    $age = [DateTime]::UtcNow - $fetchedAt

    if($age.TotalHours -ge 1){
        return $null
    }

    return $entry.value
}

function Set-CachedRoleDefinitions{
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Endpoint,

        [Parameter(Mandatory)]
        $RoleDefinitions
    )

    # Ensure RoleDefinitions key exists
    if($null -eq $script:CacheData.RoleDefinitions){
        $script:CacheData | Add-Member -NotePropertyName "RoleDefinitions" -NotePropertyValue @{} -Force
    }

    $entry = @{
        fetchedAt = [DateTime]::UtcNow.ToString("o")
        value = $RoleDefinitions
    }

    # CacheData.RoleDefinitions may be a PSCustomObject (from JSON) or a hashtable
    if($script:CacheData.RoleDefinitions -is [hashtable]){
        $script:CacheData.RoleDefinitions[$Endpoint] = $entry
    }
    else{
        $script:CacheData.RoleDefinitions | Add-Member -NotePropertyName $Endpoint -NotePropertyValue $entry -Force
    }

    Save-Cache
}

function Get-CachedClientId{
    # Ensure ClientId key exists (for caches created before this feature)
    if($null -eq $script:CacheData.ClientId){
        return $null
    }

    if([string]::IsNullOrWhiteSpace($script:CacheData.ClientId)){
        return $null
    }

    return $script:CacheData.ClientId
}

function Set-CachedClientId{
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId
    )

    # CacheData may be a hashtable (from Get-EmptyCache) or PSCustomObject (from JSON)
    if($script:CacheData -is [hashtable]){
        $script:CacheData["ClientId"] = $ClientId
    }
    else{
        $script:CacheData | Add-Member -NotePropertyName "ClientId" -NotePropertyValue $ClientId -Force
    }

    Save-Cache
}

function Get-CachedConfiguration{
    param(
        [Parameter(Mandatory=$false)]
        [string]$Name
    )

    # Reads from the generic configuration container in the cache. With no name, returns the
    # entire container; with a name, returns that entry's value (or $null when it is not set).
    if($null -eq $script:CacheData.Configuration){
        if([string]::IsNullOrWhiteSpace($Name)){
            return [PSCustomObject]@{}
        }
        return $null
    }

    if([string]::IsNullOrWhiteSpace($Name)){
        return $script:CacheData.Configuration
    }

    # Configuration may be a PSCustomObject (from JSON) or a hashtable (in-memory)
    if($script:CacheData.Configuration -is [hashtable]){
        if($script:CacheData.Configuration.ContainsKey($Name)){
            return $script:CacheData.Configuration[$Name]
        }
        return $null
    }

    $property = $script:CacheData.Configuration.PSObject.Properties[$Name]
    if($null -eq $property){
        return $null
    }

    return $property.Value
}

function Set-CachedConfiguration{
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Value
    )

    # Ensure the configuration container exists (for caches created before this feature)
    if($null -eq $script:CacheData.Configuration){
        if($script:CacheData -is [hashtable]){
            $script:CacheData["Configuration"] = [PSCustomObject]@{}
        }
        else{
            $script:CacheData | Add-Member -NotePropertyName "Configuration" -NotePropertyValue ([PSCustomObject]@{}) -Force
        }
    }

    if($script:CacheData.Configuration -is [hashtable]){
        if($null -eq $Value){
            $script:CacheData.Configuration.Remove($Name)
        }
        else{
            $script:CacheData.Configuration[$Name] = $Value
        }
    }
    else{
        if($null -eq $Value){
            if($null -ne $script:CacheData.Configuration.PSObject.Properties[$Name]){
                $script:CacheData.Configuration.PSObject.Properties.Remove($Name)
            }
        }
        else{
            $script:CacheData.Configuration | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
        }
    }

    Save-Cache
}

function Get-CachedServicePrincipalAuth{
    # Reads the service principal auth configuration from the generic configuration
    # container in the cache. Returns $null when it has not been configured.
    return Get-CachedConfiguration -Name "ServicePrincipalAuth"
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
        $now = [DateTime]::UtcNow
        $entry = $script:CacheData.RegionCache.$cacheKey
        $expiry = if($entry.Expiry -is [DateTime]){
                $entry.Expiry.ToUniversalTime()
            }
            else{
                $entry.Expiry = $now
            }
        if($expiry -gt $now){
            $remainingMinutes = [math]::Round(($expiry - $now).TotalMinutes, 1)
            Write-Verbose "Region cache hit for $cacheKey. Region: $($entry.Region). Cache valid for $remainingMinutes more minutes."
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
    Write-Verbose "Region resolved for $cacheKey. Region: $region. Caching for 1 hour."

    # Store in cache with 1-hour expiry
    $cacheEntry = [PSCustomObject]@{
        Region = $region
        Expiry = [DateTime]::UtcNow.AddHours(1)
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
