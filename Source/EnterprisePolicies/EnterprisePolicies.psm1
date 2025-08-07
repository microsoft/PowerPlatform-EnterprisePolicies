$Public = Get-ChildItem -Path "$PSScriptRoot\Public\**\*.ps1" -Recurse
foreach ($script in $Public) {
    . $script.FullName
    Write-Host "Loaded script: $($script.FullName)"
}

$Private = Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1"
foreach ($script in $Private) {
    . $script.FullName
    Write-Host "Loaded script: $($script.FullName)"
}

Export-ModuleMember -Function $Public.BaseName
Export-ModuleMember -Function $Private.BaseName
