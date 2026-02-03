<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Tests that an Azure AD application is correctly configured for Power Platform Authorization.

.DESCRIPTION
This cmdlet validates that an Azure AD application registration exists and is properly configured
for Power Platform Authorization operations. It checks:
- The application exists in Azure AD
- The application has the required API permissions configured (Authorization.RoleAssignments.Read and Write)
- The application is configured as a public client
- The application has http://localhost configured as a redirect URI

.OUTPUTS
System.Boolean

Returns $true if the application is correctly configured, $false otherwise.

.EXAMPLE
Test-AuthorizationApplication -ApplicationId "00000000-0000-0000-0000-000000000001" -TenantId "12345678-1234-1234-1234-123456789012"

Tests that the application is correctly configured for the prod endpoint.

.EXAMPLE
Test-AuthorizationApplication -ApplicationId "00000000-0000-0000-0000-000000000001" -TenantId "12345678-1234-1234-1234-123456789012" -Endpoint tip1

Tests that the application is correctly configured for the TIP1 endpoint.
#>

function Test-AuthorizationApplication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage="The Application (client) ID of the Azure AD application")]
        [ValidateNotNullOrEmpty()]
        [string]$ApplicationId,

        [Parameter(Mandatory, HelpMessage="The Azure AD tenant ID")]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The BAP endpoint to validate against")]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication instead of reusing existing session")]
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    # Connect to Azure
    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId -Force:$ForceAuth)) {
        Write-Warning "Failed to connect to Azure. Cannot validate application."
        return $false
    }

    # Determine the expected API ID based on endpoint
    $expectedApiId = switch ($Endpoint) {
        { $_ -in [BAPEndpoint]::tip1, [BAPEndpoint]::tip2 } {
            "0ddb742a-e7dc-4899-a31e-80e797ec7144"
        }
        default {
            "8578e004-a5c6-46e7-913e-12f58912df43"
        }
    }

    Write-Verbose "Validating application $ApplicationId against API $expectedApiId"

    # Check if the application exists
    $application = Get-AzADApplication -Filter "appId eq '$ApplicationId'" -ErrorAction SilentlyContinue

    if ($null -eq $application) {
        Write-Warning "Application with ID '$ApplicationId' not found in tenant '$TenantId'."
        return $false
    }

    Write-Verbose "Found application: $($application.DisplayName) (Object ID: $($application.Id))"

    # Check if it's configured as a public client
    if (-not $application.IsFallbackPublicClient) {
        Write-Warning "Application is not configured as a public client. Run New-AuthorizationApplication with -Update to fix this."
        return $false
    }

    # Check for localhost redirect URI (required for interactive MSAL authentication)
    $redirectUris = $application.PublicClient.RedirectUri
    if ($null -eq $redirectUris -or $redirectUris.Count -eq 0 -or $redirectUris -notcontains "http://localhost") {
        Write-Warning "Application does not have 'http://localhost' configured as a redirect URI. Run New-AuthorizationApplication with -Update to fix this."
        return $false
    }

    # Check required resource access (API permissions)
    $requiredResourceAccess = $application.RequiredResourceAccess

    if ($null -eq $requiredResourceAccess -or $requiredResourceAccess.Count -eq 0) {
        Write-Warning "Application has no API permissions configured."
        return $false
    }

    # Find the Power Platform Authorization API in the required resources
    $authApiAccess = $requiredResourceAccess | Where-Object { $_.ResourceAppId -eq $expectedApiId }

    if ($null -eq $authApiAccess) {
        Write-Warning "Application does not have permissions configured for the Power Platform Authorization API ($expectedApiId)."
        return $false
    }

    # Get the API's service principal to validate permission names
    $apiServicePrincipal = Get-AzADServicePrincipal -Filter "appId eq '$expectedApiId'" -ErrorAction SilentlyContinue

    if ($null -eq $apiServicePrincipal) {
        Write-Warning "Could not find the Power Platform Authorization API service principal. Ensure the API is available in your tenant."
        return $false
    }

    # Check for required permissions
    $oauth2Permissions = $apiServicePrincipal.Oauth2PermissionScope
    $readPermission = $oauth2Permissions | Where-Object { $_.Value -eq "Authorization.RoleAssignments.Read" }
    $writePermission = $oauth2Permissions | Where-Object { $_.Value -eq "Authorization.RoleAssignments.Write" }

    $configuredPermissionIds = $authApiAccess.ResourceAccess | Select-Object -ExpandProperty Id

    $hasReadPermission = $configuredPermissionIds -contains $readPermission.Id
    $hasWritePermission = $configuredPermissionIds -contains $writePermission.Id

    if (-not $hasReadPermission) {
        Write-Warning "Application is missing the 'Authorization.RoleAssignments.Read' permission."
        return $false
    }

    if (-not $hasWritePermission) {
        Write-Warning "Application is missing the 'Authorization.RoleAssignments.Write' permission."
        return $false
    }

    Write-Verbose "Application is correctly configured with all required permissions."
    Write-Host "Application '$($application.DisplayName)' is correctly configured for Power Platform Authorization." -ForegroundColor Green

    return $true
}
