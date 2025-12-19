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