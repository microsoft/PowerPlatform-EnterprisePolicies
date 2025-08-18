<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

function Read-InstallMissingPrerequisite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Module
    )

    $response = Read-Host "The $($Module.Name) module is not installed or the required minimum version [$($Module.MinimumVersion)] is not installed. Do you want to install it now? (Y/N)"
    if ($response -eq 'Y' -or $response -eq 'y') {
        try {
            Install-Module -Name $Module.Name -MinimumVersion $Module.MinimumVersion -AllowClobber -Force
            Write-Host "$($Module.Name) module installed successfully." -ForegroundColor Green
        } catch {
            throw "Failed to install $($Module.Name) module. Please install it manually."
        }
    } else {
        throw "This module can't be run without previously installing the $($Module.Name) module."
    }
}

if($Global:InPesterExecution){
    Write-Verbose "Skipped prereqs for Pester execution"
    return
}

if ($Global:PrereqsChecked) {
    return
}

$modules = [PSCustomObject]@{
    Name = "Az"
    MinimumVersion = "12.3.0"
}, [PSCustomObject]@{
    Name = "Microsoft.PowerApps.Administration.PowerShell"
    MinimumVersion = "2.0.212"
}, [PSCustomObject]@{
    Name = "Microsoft.PowerApps.PowerShell"
    MinimumVersion = "1.0.40"
}
foreach ($module in $modules) {
    if($PSVersionTable.PSEdition -eq "Core") {
        $availableModule = Get-Module -Name $module.Name -ListAvailable | Where-Object { [version]$_.Version -ge [version]$module.MinimumVersion }
        if(-Not ($availableModule)) {
            Read-InstallMissingPrerequisite -Module $module
        }
    }
    else {
        $availableModule = Get-InstalledModule -Name $module.Name -ErrorAction SilentlyContinue | Where-Object { [version]$_.Version -ge [version]$module.MinimumVersion }
        if(-Not ($availableModule)) {
            Read-InstallMissingPrerequisite -Module $module
        }
    }
}

Import-Module @("Az.Accounts", "Az.Resources", "Az.KeyVault", "Az.Network")

$Global:PrereqsChecked = $true

