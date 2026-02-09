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

    $response = Read-Host "The $($Module.Name) module is not installed or the required version [$($Module.RequiredVersion)] is not installed. The exact version is required. Do you want to install it now? (Y/N)"
    if ($response -eq 'Y' -or $response -eq 'y') {
        if(-not(Test-AdminRights)) {
            throw "You must run this script as an Administrator to install the required module."
        }
        try {
            Install-Module -Name $Module.Name -RequiredVersion $Module.RequiredVersion -AllowClobber -Force
            Write-Host "$($Module.Name) module installed successfully." -ForegroundColor Green
        } catch {
            throw "Failed to install $($Module.Name) module. Please install it manually."
        }
    } else {
        throw "This module can't be run without previously installing version [$($Module.RequiredVersion)] of the [$($Module.Name)] module. The exact version is required."
    }
}


function Test-AdminRights {
    if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    else {
        # On Linux/macOS, check if running as root (UID 0)
        return (id -u) -eq 0
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
    Name = "Az.Accounts"
    RequiredVersion = "5.3.0"
}, [PSCustomObject]@{
    Name = "Az.Resources"
    RequiredVersion = "8.1.1"
}, [PSCustomObject]@{
    Name = "Az.KeyVault"
    RequiredVersion = "6.4.0"
}, [PSCustomObject]@{
    Name = "Az.Network"
    RequiredVersion = "7.22.0"
}

foreach ($module in $modules) {
    if($PSVersionTable.PSEdition -eq "Core") {
        $availableModule = Get-Module -Name $module.Name -ListAvailable | Where-Object { [version]$_.Version -eq [version]$module.RequiredVersion }
        if(-Not ($availableModule)) {
            Read-InstallMissingPrerequisite -Module $module
        }
    }
    else {
        $availableModule = Get-InstalledModule -Name $module.Name -AllVersions -ErrorAction SilentlyContinue | Where-Object { [version]$_.Version -eq [version]$module.RequiredVersion }
        if(-Not ($availableModule)) {
            Read-InstallMissingPrerequisite -Module $module
        }
    }
}

Import-Module @("Az.Accounts", "Az.Resources", "Az.KeyVault", "Az.Network")

$Global:PrereqsChecked = $true

