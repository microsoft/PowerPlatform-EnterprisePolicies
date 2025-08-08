# If you want to test a parameter in a filter, make sure you define it in the function signature.
function Connect-AzAccount {
    param(
        [string] $Tenant,
        [string] $Environment
    )
}
function Get-AzContext {}
function Set-AzContext {}
function Get-AzADAppCredential {}
function New-AzADAppCredential {}
function Get-AzADApplication {}
function New-AzADApplication {}
function New-AzADServicePrincipal {}
function Get-AzADServicePrincipal {}
