<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Stores a named configuration value in the module's local cache.

.DESCRIPTION
The Set-PPModuleConfiguration cmdlet persists a named configuration value in the module's cached
configuration file so it is available across sessions. The value can be any object and is stored under
the provided name.

The reserved 'ServicePrincipalAuth' name cannot be set through this cmdlet because it requires a
validated, strongly-typed configuration. Use the dedicated Set-PPServicePrincipalAuth cmdlet to
configure service principal authentication.

Passing $null for the value removes the named configuration entry. Use Get-PPModuleConfiguration to read
stored configuration values back.

.OUTPUTS
None.

.EXAMPLE
Set-PPModuleConfiguration -Name "MySetting" -Value "SomeValue"

Stores the value "SomeValue" under the name "MySetting".

.EXAMPLE
Set-PPModuleConfiguration -Name "MySetting" -Value $null

Removes the "MySetting" configuration entry.
#>
function Set-PPModuleConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage="The name of the configuration entry to store.")]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory, HelpMessage="The value to store for the configuration entry. Pass `$null to remove it.")]
        [AllowNull()]
        [object]$Value
    )

    $ErrorActionPreference = "Stop"

    if ($Name -eq "ServicePrincipalAuth") {
        throw "The '$Name' configuration cannot be set with Set-PPModuleConfiguration. Use the dedicated Set-PPServicePrincipalAuth cmdlet to configure service principal authentication."
    }

    Set-CachedConfiguration -Name $Name -Value $Value

    if ($null -eq $Value) {
        Write-Verbose "Removed module configuration '$Name'."
    }
    else {
        Write-Verbose "Stored module configuration '$Name'."
    }
}
