<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Creates a PublicClientApplicationBuilder for MSAL authentication.

.DESCRIPTION
This function creates a Microsoft.Identity.Client.PublicClientApplicationBuilder instance
configured with the specified client ID. This script is intentionally NOT loaded at module
import time to avoid type resolution issues during testing.

.PARAMETER ClientId
The Application (client) ID of the Azure AD application.

.OUTPUTS
Microsoft.Identity.Client.PublicClientApplicationBuilder

Returns the builder instance which can be further configured with .WithAuthority(),
.WithDefaultRedirectUri(), etc.
#>
function Get-PublicClientApplicationBuilder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId
    )

    return [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($ClientId)
}
