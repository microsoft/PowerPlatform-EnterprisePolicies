param
(
    [string[]] $Tasks = 'Build'
)

$packagesDir = $env:NUGET_PACKAGES
if (-not $packagesDir) {
    # Fallback: query dotnet for the actual path
    $packagesDir = (& dotnet nuget locals global-packages --list) -replace '^global-packages:\s*', ''
}

if (-not (Test-Path $packagesDir)) {
    throw "NuGet global packages folder not found: $packagesDir"
}

$loadModules = @('psake', 'Pester', 'Microsoft.PowerShell.PlatyPS')
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
        throw "Unable to find module $loadModule psd1 file under: $($modulePkg.FullName)"
    }

    Write-Host "Loading module: $($psd1.FullName)"
    Import-Module $psd1.FullName
}

# Builds the module by invoking psake on the build.psake.ps1 script.
Invoke-PSake $PSScriptRoot\build.psake.ps1 -taskList $Tasks
