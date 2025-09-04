# Dot source this script in any Pester test script that requires the module to be imported.
[CmdletBinding()]
param (
    [Parameter()]
    [switch] $Module
)

$ModuleManifestName = 'Microsoft.PowerPlatform.EnterprisePolicies.psd1'
$Global:ModuleName = 'Microsoft.PowerPlatform.EnterprisePolicies'
$Global:ModuleManifestPath = "$PSScriptRoot\..\Microsoft.PowerPlatform.EnterprisePolicies\"
$Global:ModuleManifestFilePath = "$Global:ModuleManifestPath\$ModuleManifestName"
$Global:ModuleScriptsPaths = @("$PSScriptRoot\..\Microsoft.PowerPlatform.EnterprisePolicies\Public")
$Global:InPesterExecution = $true

# $packagesDir = Resolve-Path -Path "$HOME\.nuget\packages"
$loadNugetModules = @('Pester')
foreach($loadModule in $loadNugetModules) {
    # $modulePath = Join-Path -Path $packagesDir -ChildPath "$loadModule"
    # $modulePkg = Get-ChildItem -Path $modulePath | Sort-Object -Property Name -Descending | Select-Object -First 1
    # if(!$modulePkg) {
    #     throw "Unable to load $loadModule from $packagesDir"
    # }
    # $folderName = (Split-Path -Path $modulePkg -Leaf)
    # $version = $folderName

    # $loadedModules = Get-Module $loadModule
    # $correctVersionModule = $loadedModules | Where-Object {$_.Version -eq $version}
    # if(($loadedModules.Count -eq 0) -or ($correctVersionModule.Count -eq 0)){
    #     Remove-Module $loadModule -Force -ErrorAction SilentlyContinue
    #     $psd1 = Get-ChildItem -Path $modulePkg.FullName -Filter '*.psd1' | Select-Object -First 1
    #     $toolsDir = "$($modulePkg.FullName)\tools"
    #     if(!$psd1 -and (Test-Path -Path $toolsDir)) {
    #         $psd1 = Get-ChildItem -Path $toolsDir -Filter '*.psd1' | Select-Object -First 1
    #     }
    
    #     if(!$psd1) {
    #         throw "Unable to find module $loadModule psd1 file under: $modulePkg.FullName"
    #     }
    
    #     Write-Host "Loading module: $($psd1.FullName)"
    #     Import-Module $psd1.FullName
    # }

    # if getting issues with finding Pester in nuget packages, uncomment above and try this:
    Import-Module $loadModule
}

Get-Module -All | Where-Object {$_.Name -like "$Global:ModuleName*"} | Remove-Module -Force -ErrorAction SilentlyContinue | Out-Null

Import-Module $Global:ModuleManifestFilePath -Force -Global

Import-Module $PSScriptRoot\FakeAzModule\FakeAZ.psd1 -Force -Global

if($Module)
{
    (Get-ChildItem $MyInvocation.PSCommandPath | Select-Object -Expand Name) -replace '.Tests.ps1', '.ps1' | ForEach-Object {
        . "$Global:ModuleManifestPath\Private\$_"
    }
}