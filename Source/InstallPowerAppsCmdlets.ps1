param(
    [string]$PSRepositoryName
)

function InstallPowerAppsCmdlets() {
    param(
        [string]$PSRepositoryName
    )

    Set-ExecutionPolicy unrestricted -Scope Process
    # Install - only needs to be run once per machine
    # Note - to install PowerShell needs to be run as admin
    $modulesPowerApps = Get-Module -ListAvailable -Name Microsoft.PowerApps.Administration.PowerShell
    $moduleAzure = Get-Module -ListAvailable -Name Az*

    $installPowerApps = $true
    $installAzure = $true

    if ($null -ne $modulesPowerApps) {
        foreach ($item in $modulesPowerApps) {

            if ([version]::Parse($item.Version) -ge [version]::Parse('2.0.81')) {
                $installPowerApps = $false;
                break;
            } 
        }
    }

    $installParams = @{
        AllowClobber = $true
        Force = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($PSRepositoryName)) {
        $installParams['Repository'] = $PSRepositoryName
    }

    if ($installPowerApps) {
        Install-Module -Name Microsoft.PowerApps.Administration.PowerShell @installParams
        Install-Module -Name Microsoft.PowerApps.PowerShell @installParams
    }

    if ($null -eq $moduleAzure) {
        Install-Module -Name Az @installParams
    }

}

InstallPowerAppsCmdlets -PSRepositoryName $PSRepositoryName