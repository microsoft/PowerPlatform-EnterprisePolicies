<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

$Public = Get-ChildItem -Path "$PSScriptRoot\Public\**\*.ps1" -Recurse
foreach ($script in $Public) {
    . $script.FullName
    Write-Verbose "Loaded script: $($script.FullName)"
}

$Private = Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -Exclude "Assert-PrereqsAreInstalledAndLoaded.ps1"
foreach ($script in $Private) {
    . $script.FullName
    Write-Verbose "Loaded script: $($script.FullName)"
}

# Load MSAL wrapper only when not running in Pester tests (to avoid type resolution issues)
if (-not $Global:InPesterExecution) {
    $msalWrapper = Join-Path $PSScriptRoot "Private\RuntimeLoaded\MSALWrapper.ps1"
    if (Test-Path $msalWrapper) {
        . $msalWrapper
        Write-Verbose "Loaded MSAL wrapper: $msalWrapper"
    }
}

Initialize-Cache

Test-LatestModuleVersion

Export-ModuleMember -Function $Public.BaseName
