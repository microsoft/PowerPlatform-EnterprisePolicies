<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Creates a new Azure AD application registration and service principal for Power Platform Authorization.

.DESCRIPTION
This cmdlet creates a public client application (app registration) and its associated service principal
in Azure AD with the required API permissions for Power Platform Authorization operations. The application
is configured as a single-tenant app with delegated permissions for Authorization.RoleAssignments.Read
and Authorization.RoleAssignments.Write.

Admin consent is NOT granted automatically. A tenant administrator must grant consent before
the application can be used.

.OUTPUTS
System.String

Returns the Application (client) ID of the created application.

.EXAMPLE
New-AuthorizationApplication -DisplayName "MyAuthorizationApp" -TenantId "12345678-1234-1234-1234-123456789012"

Creates a new app registration and service principal named "MyAuthorizationApp".

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

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication instead of reusing existing session")]
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    # Connect to Azure
    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
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

    # Create the application as a public client (for native/mobile apps, no client secret)
    Write-Verbose "Creating application registration: $DisplayName"

    $appParams = @{
        DisplayName = $DisplayName
        SignInAudience = "AzureADMyOrg"  # Single tenant
        RequiredResourceAccess = $requiredResourceAccess
        IsFallbackPublicClient = $true  # Public client application
    }

    $application = New-AzADApplication @appParams

    if ($null -eq $application) {
        throw "Failed to create the application registration."
    }

    Write-Verbose "Application registration created: $($application.AppId)"

    # Set the Application ID URI in the format api://{appId}
    $identifierUri = "api://$($application.AppId)"
    Write-Verbose "Setting Application ID URI: $identifierUri"
    Update-AzADApplication -ObjectId $application.Id -IdentifierUri $identifierUri

    # Create the service principal for the application
    Write-Verbose "Creating service principal for application: $($application.AppId)"
    $appServicePrincipal = New-AzADServicePrincipal -ApplicationId $application.AppId

    if ($null -eq $appServicePrincipal) {
        throw "Failed to create the service principal for the application."
    }

    Write-Host "Application and service principal created successfully." -ForegroundColor Green
    Write-Host "  Display Name: $($application.DisplayName)" -ForegroundColor Green
    Write-Host "  Application (client) ID: $($application.AppId)" -ForegroundColor Green
    Write-Host "  Application ID URI: $identifierUri" -ForegroundColor Green
    Write-Host "  Application Object ID: $($application.Id)" -ForegroundColor Green
    Write-Host "  Service Principal Object ID: $($appServicePrincipal.Id)" -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANT: Admin consent is required before this application can be used." -ForegroundColor Yellow
    Write-Host "A tenant administrator must grant consent for the following permissions:" -ForegroundColor Yellow
    Write-Host "  - Authorization.RoleAssignments.Read" -ForegroundColor Yellow
    Write-Host "  - Authorization.RoleAssignments.Write" -ForegroundColor Yellow

    return $application.AppId
}
