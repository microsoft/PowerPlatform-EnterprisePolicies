<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Creates or updates an Azure AD application registration and service principal for Power Platform Authorization.

.DESCRIPTION
This cmdlet creates a public client application (app registration) and its associated service principal
in Azure AD with the required API permissions for Power Platform Authorization operations. The application
is configured as a single-tenant app with delegated permissions for Authorization.RoleAssignments.Read
and Authorization.RoleAssignments.Write.

If an application with the specified display name already exists, the cmdlet will prompt you to use
Test-AuthorizationApplication to verify the configuration, or use the -Update switch to update the
existing application with the required settings.

Admin consent is NOT granted automatically. A tenant administrator must grant consent before
the application can be used.

.OUTPUTS
System.String

Returns the Application (client) ID of the created or updated application.

.EXAMPLE
New-AuthorizationApplication -DisplayName "MyAuthorizationApp" -TenantId "12345678-1234-1234-1234-123456789012"

Creates a new app registration and service principal named "MyAuthorizationApp".

.EXAMPLE
New-AuthorizationApplication -DisplayName "MyAuthorizationApp" -TenantId "12345678-1234-1234-1234-123456789012" -Update

Updates an existing app registration named "MyAuthorizationApp" with the required permissions.

.EXAMPLE
New-AuthorizationApplication -DisplayName "MyAuthorizationApp" -TenantId "12345678-1234-1234-1234-123456789012" -Endpoint usgovhigh

Creates a new app registration and service principal for the US Government High cloud.
#>

function New-AuthorizationApplication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage="The display name for the application registration")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [Parameter(Mandatory, HelpMessage="The Azure AD tenant ID")]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The BAP endpoint to connect to")]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="Update an existing application with the required configuration")]
        [switch]$Update,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication instead of reusing existing session")]
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    # Connect to Azure
    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    # Check if an application with this display name already exists
    Write-Verbose "Checking if application '$DisplayName' already exists..."
    $existingApp = Get-AzADApplication -Filter "displayName eq '$DisplayName'" -ErrorAction SilentlyContinue

    if ($null -ne $existingApp -and -not $Update) {
        Write-Host ""
        Write-Host "An application with the display name '$DisplayName' already exists." -ForegroundColor Yellow
        Write-Host "  Application (client) ID: $($existingApp.AppId)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To verify if this application is correctly configured, run:" -ForegroundColor Cyan
        Write-Host "  Test-AuthorizationApplication -ClientId '$($existingApp.AppId)' -TenantId '$TenantId' -Endpoint $Endpoint" -ForegroundColor White
        Write-Host ""
        Write-Host "If the test fails, run this command with the -Update switch to update the application:" -ForegroundColor Cyan
        Write-Host "  New-AuthorizationApplication -DisplayName '$DisplayName' -TenantId '$TenantId' -Endpoint $Endpoint -Update" -ForegroundColor White
        Write-Host ""
        return
    }

    # Determine the API ID based on endpoint
    # TIP1 and TIP2 use a different API ID than prod and sovereign clouds
    $apiId = switch ($Endpoint) {
        { $_ -in [BAPEndpoint]::tip1, [BAPEndpoint]::tip2 } {
            "0ddb742a-e7dc-4899-a31e-80e797ec7144"
        }
        default {
            # Prod, usgovhigh, dod, china
            "8578e004-a5c6-46e7-913e-12f58912df43"
        }
    }

    Write-Verbose "Using API ID: $apiId for endpoint: $Endpoint"

    # Define the delegated permission IDs
    # These need to be looked up from the API's service principal
    Write-Verbose "Looking up service principal for API: $apiId"
    $servicePrincipal = Get-AzADServicePrincipal -Filter "appId eq '$apiId'"

    if ($null -eq $servicePrincipal) {
        throw "Could not find service principal for API ID: $apiId. Ensure the API is available in your tenant."
    }

    # Find the permission IDs for Authorization.RoleAssignments.Read and Authorization.RoleAssignments.Write
    $oauth2Permissions = $servicePrincipal.Oauth2PermissionScope

    $readPermission = $oauth2Permissions | Where-Object { $_.Value -eq "Authorization.RoleAssignments.Read" }
    $writePermission = $oauth2Permissions | Where-Object { $_.Value -eq "Authorization.RoleAssignments.Write" }

    if ($null -eq $readPermission) {
        throw "Could not find 'Authorization.RoleAssignments.Read' permission on the API."
    }

    if ($null -eq $writePermission) {
        throw "Could not find 'Authorization.RoleAssignments.Write' permission on the API."
    }

    Write-Verbose "Found permissions - Read: $($readPermission.Id), Write: $($writePermission.Id)"

    # Build the required resource access for the API permissions
    $requiredResourceAccess = @{
        ResourceAppId = $apiId
        ResourceAccess = @(
            @{
                Id = $readPermission.Id
                Type = "Scope"
            },
            @{
                Id = $writePermission.Id
                Type = "Scope"
            }
        )
    }

    # Define redirect URI for public client (required for interactive MSAL authentication)
    $redirectUri = "http://localhost"

    # Either update existing or create new application
    if ($Update -and $null -ne $existingApp) {
        Write-Verbose "Updating existing application: $DisplayName"
        Update-AzADApplication -ObjectId $existingApp.Id -RequiredResourceAccess $requiredResourceAccess -IsFallbackPublicClient -PublicClientRedirectUri $redirectUri
        $application = $existingApp
        $isUpdate = $true
    }
    else {
        Write-Verbose "Creating application registration: $DisplayName"
        $application = New-AzADApplication -DisplayName $DisplayName -SignInAudience "AzureADMyOrg" -RequiredResourceAccess $requiredResourceAccess -IsFallbackPublicClient -PublicClientRedirectUri $redirectUri

        if ($null -eq $application) {
            throw "Failed to create the application registration."
        }
        $isUpdate = $false
    }

    # Set the Application ID URI
    $identifierUri = "api://$($application.AppId)"
    Write-Verbose "Setting Application ID URI: $identifierUri"
    Update-AzADApplication -ObjectId $application.Id -IdentifierUri $identifierUri

    # Ensure service principal exists
    $appServicePrincipal = Get-AzADServicePrincipal -Filter "appId eq '$($application.AppId)'" -ErrorAction SilentlyContinue
    if ($null -eq $appServicePrincipal) {
        Write-Verbose "Creating service principal for application: $($application.AppId)"
        $appServicePrincipal = New-AzADServicePrincipal -ApplicationId $application.AppId

        if ($null -eq $appServicePrincipal) {
            throw "Failed to create the service principal for the application."
        }
    }

    # Output results
    $action = if ($isUpdate) { "updated" } else { "created" }
    Write-Host "Application $action successfully." -ForegroundColor Green
    Write-Host "  Display Name: $($application.DisplayName)" -ForegroundColor Green
    Write-Host "  Application (client) ID: $($application.AppId)" -ForegroundColor Green
    Write-Host "  Application ID URI: $identifierUri" -ForegroundColor Green
    Write-Host "  Application Object ID: $($application.Id)" -ForegroundColor Green
    Write-Host "  Service Principal Object ID: $($appServicePrincipal.Id)" -ForegroundColor Green

    Set-CachedClientId -ClientId $application.AppId

    return $application.AppId
}
