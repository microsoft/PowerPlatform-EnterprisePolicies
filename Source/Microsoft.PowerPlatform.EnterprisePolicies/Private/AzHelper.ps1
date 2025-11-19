function Register-ResourceProvider {
    <#
    .SYNOPSIS
    Registers an Azure resource provider if it is not already registered.

    .DESCRIPTION
    Checks if the specified Azure resource provider is registered in the current subscription.
    If not registered, initiates registration and waits for completion.

    .PARAMETER ProviderNamespace
    The namespace of the resource provider to register (e.g., "Microsoft.PowerPlatform", "Microsoft.Network")

    .PARAMETER MaxWaitTimeSeconds
    Maximum time to wait for registration to complete in seconds. Default is 300 (5 minutes).

    .PARAMETER PollIntervalSeconds
    Interval between registration status checks in seconds. Default is 10 seconds.

    .EXAMPLE
    Register-ResourceProvider -ProviderNamespace "Microsoft.PowerPlatform"

    .EXAMPLE
    Register-ResourceProvider -ProviderNamespace "Microsoft.Network" -MaxWaitTimeSeconds 600
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderNamespace,

        [Parameter(Mandatory=$false)]
        [int]$MaxWaitTimeSeconds = 300,

        [Parameter(Mandatory=$false)]
        [int]$PollIntervalSeconds = 10
    )

    Write-Verbose "Checking $ProviderNamespace resource provider registration status..."
    
    try {
        $provider = Get-AzResourceProvider -ProviderNamespace $ProviderNamespace -ErrorAction Stop
        
        if ($provider.RegistrationState -eq "Registered") {
            Write-Verbose "$ProviderNamespace resource provider is already registered"
            return $true
        }

        Write-Verbose "$ProviderNamespace resource provider is not registered. Registration state: $($provider.RegistrationState)"
        Write-Host "Registering the subscription for $ProviderNamespace" -ForegroundColor Yellow
        
        $register = Register-AzResourceProvider -ProviderNamespace $ProviderNamespace -ErrorAction Stop
        
        if ($null -eq $register -or $null -eq $register.RegistrationState) {
            $registerString = $register | ConvertTo-Json
            Write-Host "Registration failed for $ProviderNamespace. $registerString" -ForegroundColor Red
            return $false
        }

        if ($register.RegistrationState -eq "Registered") {
            Write-Host "Subscription registered for $ProviderNamespace" -ForegroundColor Green
            return $true
        }

        Write-Host "Registration of the subscription for $ProviderNamespace started" -ForegroundColor Yellow
        $registrationState = $register.RegistrationState
        $elapsedTime = 0

        while ($registrationState -ne "Registered" -and $elapsedTime -lt $MaxWaitTimeSeconds) {
            Write-Verbose "Polling for registration after $PollIntervalSeconds seconds. Elapsed time: $elapsedTime seconds"
            Start-Sleep -Seconds $PollIntervalSeconds
            $elapsedTime += $PollIntervalSeconds
            
            Write-Verbose "Getting the registration state for $ProviderNamespace"
            $resourceProvider = Get-AzResourceProvider -ProviderNamespace $ProviderNamespace -ErrorAction Stop
            $registrationState = $resourceProvider.RegistrationState
            
            if ($registrationState -is [array]) {
                $registrationState = $registrationState[0]
            }
        }

        if ($registrationState -eq "Registered") {
            Write-Host "Subscription registered for $ProviderNamespace" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "Timeout waiting for $ProviderNamespace resource provider registration. Current state: $registrationState" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error registering resource provider $ProviderNamespace : $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Register-ProviderFeature {
    <#
    .SYNOPSIS
    Registers an Azure provider feature if it is not already registered.

    .DESCRIPTION
    Checks if the specified Azure provider feature is registered.
    If not registered, initiates feature registration.

    .PARAMETER FeatureName
    The name of the feature to register (e.g., "enterprisePoliciesPreview")

    .PARAMETER ProviderNamespace
    The namespace of the provider that owns the feature (e.g., "Microsoft.PowerPlatform")

    .EXAMPLE
    Register-ProviderFeature -FeatureName "enterprisePoliciesPreview" -ProviderNamespace "Microsoft.PowerPlatform"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FeatureName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderNamespace
    )

    Write-Verbose "Checking $FeatureName feature registration status for $ProviderNamespace..."
    
    try {
        $feature = Get-AzProviderFeature -FeatureName $FeatureName -ProviderNamespace $ProviderNamespace -ErrorAction SilentlyContinue
        
        if ($feature -and $feature.RegistrationState -eq "Registered") {
            Write-Verbose "Feature $FeatureName for $ProviderNamespace is already registered"
            return $true
        }

        Write-Host "Registering the subscription for feature $FeatureName for $ProviderNamespace" -ForegroundColor Yellow
        
        $register = Register-AzProviderFeature -FeatureName $FeatureName -ProviderNamespace $ProviderNamespace -ErrorAction Stop
        
        if ($null -eq $register -or $null -eq $register.RegistrationState) {
            $registerString = $register | ConvertTo-Json
            Write-Host "Registration failed for feature $FeatureName for $ProviderNamespace. $registerString" -ForegroundColor Red
            return $false
        }

        Write-Host "Subscription registered for feature $FeatureName for $ProviderNamespace" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error registering feature $FeatureName for $ProviderNamespace : $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Initialize-SubscriptionForPowerPlatform {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$SubscriptionId
    )
    if(Test-SubscriptionValidated -SubscriptionId $SubscriptionId) {
        Write-Verbose "Subscription $SubscriptionId is already initialized for Power Platform"
        return $true
    }
    if(-not(Register-ResourceProvider -ProviderNamespace "Microsoft.Network")) {
        Write-Host "Failed to register Microsoft.Network resource provider" -ForegroundColor Red
        return $false
    }
    if(-not(Register-ResourceProvider -ProviderNamespace "Microsoft.PowerPlatform")) {
        Write-Host "Failed to register Microsoft.PowerPlatform resource provider" -ForegroundColor Red
        return $false
    }
    if(-not(Register-ProviderFeature -FeatureName "enterprisePoliciesPreview" -ProviderNamespace "Microsoft.PowerPlatform")) {
        Write-Host "Failed to register enterprisePoliciesPreview feature for Microsoft.PowerPlatform" -ForegroundColor Red
        return $false
    }
    Add-ValidatedSubscriptionToCache -SubscriptionId $SubscriptionId
    return $true
}