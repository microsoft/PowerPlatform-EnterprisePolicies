param
(
    [string[]] $Tasks = 'Build'
)

$packagesDir = Resolve-Path -Path "$HOME\.nuget\packages"
$loadModules = @('psake', 'Pester')
foreach($loadModule in $loadModules) {
    $modulePath = Join-Path -Path $packagesDir -ChildPath "$loadModule"
    $modulePkg = Get-ChildItem -Path $modulePath | Sort-Object -Property Name -Descending | Select-Object -First 1
    if(!$modulePkg) {
        throw "Unable to load $loadModule from $packagesDir"
    }

    $psd1 = Get-ChildItem -Path $modulePkg.FullName -Filter '*.psd1' | Select-Object -First 1
    $toolsDir = "$($modulePkg.FullName)\tools"
    if(!$psd1 -and (Test-Path -Path $toolsDir)) {
        $psd1 = Get-ChildItem -Path $toolsDir -Filter '*.psd1' | Select-Object -First 1
    }

    if(!$psd1) {
        throw "Unable to find module $loadModule psd1 file under: $modulePkg.FullName"
    }

    Write-Host "Loading module: $($psd1.FullName)"
    Import-Module $psd1.FullName
}

Install-PSResource -Name Microsoft.PowerShell.PlatyPS -TrustRepository -Quiet
Import-Module -Name Microsoft.PowerShell.PlatyPS

# Builds the module by invoking psake on the build.psake.ps1 script.
Invoke-PSake $PSScriptRoot\build.psake.ps1 -taskList $Tasks
