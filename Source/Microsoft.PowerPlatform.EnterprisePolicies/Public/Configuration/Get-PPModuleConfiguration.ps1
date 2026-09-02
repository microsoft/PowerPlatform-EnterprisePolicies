<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Reads configuration values stored in the module's local cache.

.DESCRIPTION
The Get-PPModuleConfiguration cmdlet returns configuration values persisted in the module's cached
configuration file. When called without a name, it returns the entire configuration container. When a
name is provided, it returns the value stored under that name, or $null when the name isn't set.

.OUTPUTS
System.Object

Returns the configuration container when no name is provided, or the value stored under the requested
name.

.EXAMPLE
Get-PPModuleConfiguration

Returns every stored module configuration value.

.EXAMPLE
Get-PPModuleConfiguration -Name "ServicePrincipalAuth"

Returns the stored service principal authentication configuration, or $null when it hasn't been set.
#>
function Get-PPModuleConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage="The name of the configuration entry to return. Omit to return all configuration.")]
        [string]$Name
    )

    $ErrorActionPreference = "Stop"

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return Get-CachedConfiguration
    }

    return Get-CachedConfiguration -Name $Name
}
