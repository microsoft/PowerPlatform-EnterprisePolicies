<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Configures the service principal that the module uses to authenticate to Azure.

.DESCRIPTION
The Set-PPServicePrincipalAuth cmdlet stores a service principal authentication configuration in the
module's local cache. Once configured, Connect-Azure uses the service principal instead of the default
interactive login (unless re-authentication is forced).

The parameters available depend on the authentication method, expressed by the ServicePrincipalAuthMethod
enum:

- ManagedIdentity: authenticates with a managed identity with the specified client ID and tenant ID.
- Certificate: authenticates with a certificate-based service principal identified by -ClientId and
  -TenantId, using either -CertificateThumbprint or -CertificateSubjectName to locate the certificate.

Use -Clear to remove any stored configuration so Connect-Azure reverts to the default interactive flow.

.OUTPUTS
None.

.EXAMPLE
Set-PPServicePrincipalAuth -ClientId "11111111-1111-1111-1111-111111111111" -TenantId "33333333-3333-3333-3333-333333333333"

Configures Connect-Azure to authenticate using a managed identity with the specified client ID and tenant ID.

.EXAMPLE
Set-PPServicePrincipalAuth -ClientId "22222222-2222-2222-2222-222222222222" -TenantId "33333333-3333-3333-3333-333333333333" -CertificateThumbprint "A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4E5F6A1B2"

Configures Connect-Azure to authenticate using a certificate-based service principal located by thumbprint.

.EXAMPLE
Set-PPServicePrincipalAuth -ClientId "22222222-2222-2222-2222-222222222222" -TenantId "33333333-3333-3333-3333-333333333333" -CertificateSubjectName "CN=MyServicePrincipalCert"

Configures Connect-Azure to authenticate using a certificate-based service principal located by subject name.

.EXAMPLE
Set-PPServicePrincipalAuth -Clear

Removes the stored service principal configuration so Connect-Azure reverts to the default interactive flow.
#>
function Set-PPServicePrincipalAuth {
    [CmdletBinding(DefaultParameterSetName = 'ManagedIdentity')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ManagedIdentity', HelpMessage = "The client ID of the user-assigned managed identity.")]
        [Parameter(Mandatory, ParameterSetName = 'CertificateThumbprint', HelpMessage = "The application (client) ID of the service principal.")]
        [Parameter(Mandatory, ParameterSetName = 'CertificateSubjectName', HelpMessage = "The application (client) ID of the service principal.")]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,

        [Parameter(Mandatory, ParameterSetName = 'ManagedIdentity', HelpMessage = "The Azure AD tenant ID the service principal belongs to.")]
        [Parameter(Mandatory, ParameterSetName = 'CertificateThumbprint', HelpMessage = "The Azure AD tenant ID the service principal belongs to.")]
        [Parameter(Mandatory, ParameterSetName = 'CertificateSubjectName', HelpMessage = "The Azure AD tenant ID the service principal belongs to.")]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory, ParameterSetName = 'CertificateThumbprint', HelpMessage = "The thumbprint of the certificate to authenticate with.")]
        [ValidateNotNullOrEmpty()]
        [string]$CertificateThumbprint,

        [Parameter(Mandatory, ParameterSetName = 'CertificateSubjectName', HelpMessage = "The subject name of the certificate to authenticate with.")]
        [ValidateNotNullOrEmpty()]
        [string]$CertificateSubjectName,

        [Parameter(Mandatory, ParameterSetName = 'Clear', HelpMessage = "Removes any stored service principal authentication configuration.")]
        [switch]$Clear
    )

    $ErrorActionPreference = "Stop"

    if ($PSCmdlet.ParameterSetName -eq 'Clear') {
        Set-ServicePrincipalAuth -Configuration $null
        Write-Verbose "Cleared service principal authentication configuration."
        return
    }

    switch ($PSCmdlet.ParameterSetName) {
        'ManagedIdentity' {
            $method = [ServicePrincipalAuthMethod]::ManagedIdentity
            $configuration = @{
                Method   = $method.ToString()
                ClientId = $ClientId
                TenantId = $TenantId
            }
        }
        'CertificateThumbprint' {
            $method = [ServicePrincipalAuthMethod]::Certificate
            $configuration = @{
                Method                = $method.ToString()
                ClientId              = $ClientId
                TenantId              = $TenantId
                CertificateThumbprint = $CertificateThumbprint
            }
        }
        'CertificateSubjectName' {
            $method = [ServicePrincipalAuthMethod]::Certificate
            $configuration = @{
                Method                 = $method.ToString()
                ClientId               = $ClientId
                TenantId               = $TenantId
                CertificateSubjectName = $CertificateSubjectName
            }
        }
    }

    Set-CachedConfiguration -Name "ServicePrincipalAuth" -Value $Configuration
    Write-Verbose "Stored service principal authentication configuration using method '$method'."
}
