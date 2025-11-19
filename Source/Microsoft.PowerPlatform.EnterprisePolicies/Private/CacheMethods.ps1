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
    return @{
        "Version" = "1.0"
        "SubscriptionsValidated" = @()
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