<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

$script:ModuleVersion

function Get-LogDate {
    return ([DateTime]::UtcNow).ToString("dd/MM/yyyy:HH:mm:ss:K")
}

function Get-ModuleVersion{
    if($script:ModuleVersion){
        return $script:ModuleVersion
    }
    $script:ModuleVersion = (Import-PowerShellDataFile -Path "$PSScriptRoot\..\Microsoft.PowerPlatform.EnterprisePolicies.psd1")["ModuleVersion"]
    return $script:ModuleVersion
}

function Test-LatestModuleVersion{
    try {
        $currentVersion = [version](Get-ModuleVersion)
        $latestVersion = [version](Find-Module -Name "Microsoft.PowerPlatform.EnterprisePolicies" -Repository "PSGallery" | Select-Object -ExpandProperty Version)
        if ($latestVersion -gt $currentVersion) {
            Write-Warning "You're using Microsoft.PowerPlatform.EnterprisePolicies version $currentVersion. The latest version is $latestVersion. Upgrade your module module using the following commands:`n  Update-Module Microsoft.PowerPlatform.EnterprisePolicies -WhatIf    -- Simulate updating your module.`n  Update-Module Microsoft.PowerPlatform.EnterprisePolicies -WhatIf            -- Simulate updating your module.`n  Update-Module Microsoft.PowerPlatform.EnterprisePolicies            -- Update your module."
        }
    }
    catch {
        Write-Verbose "Could not check for the latest module version: $_"
    }
}