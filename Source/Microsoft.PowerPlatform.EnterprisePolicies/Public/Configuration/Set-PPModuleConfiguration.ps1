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
configuration file so it is available across sessions. Each supported configuration name is validated
and routed to a dedicated handler before it is stored.

Currently the supported configuration name is 'ServicePrincipalAuth'. When set, Connect-Azure uses it to
authenticate with a service principal instead of the default interactive flow (unless re-authentication
is forced). The value is an object describing the authentication method and is validated before it is
saved:

- Managed identity (user-assigned):
    @{ Method = 'ManagedIdentity'; ClientId = '<managed-identity-client-id>' }

- Certificate-based service principal:
    @{ Method = 'Certificate'; ClientId = '<app-id>'; TenantId = '<tenant-id>'; CertificateThumbprint = '<thumbprint>' }
    @{ Method = 'Certificate'; ClientId = '<app-id>'; TenantId = '<tenant-id>'; CertificateSubjectName = '<subject-name>' }

Passing $null for the value removes the named configuration entry.

.OUTPUTS
None.

.EXAMPLE
Set-PPModuleConfiguration -Name "ServicePrincipalAuth" -Value @{ Method = "ManagedIdentity"; ClientId = "11111111-1111-1111-1111-111111111111" }

Configures Connect-Azure to authenticate using a user-assigned managed identity.

.EXAMPLE
Set-PPModuleConfiguration -Name "ServicePrincipalAuth" -Value @{ Method = "Certificate"; ClientId = "22222222-2222-2222-2222-222222222222"; TenantId = "33333333-3333-3333-3333-333333333333"; CertificateThumbprint = "A1B2C3D4E5F6..." }

Configures Connect-Azure to authenticate using a certificate-based service principal identified by thumbprint.

.EXAMPLE
Set-PPModuleConfiguration -Name "ServicePrincipalAuth" -Value $null

Removes the ServicePrincipalAuth configuration so Connect-Azure reverts to the default interactive flow.
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

    if ($Name -eq $script:ServicePrincipalAuthConfigName) {
        Set-ServicePrincipalAuth -Configuration $Value
    }
    else {
        throw "Unsupported configuration name '$Name'. Supported configuration names: '$($script:ServicePrincipalAuthConfigName)'."
    }

    if ($null -eq $Value) {
        Write-Verbose "Removed module configuration '$Name'."
    }
    else {
        Write-Verbose "Stored module configuration '$Name'."
    }
}
