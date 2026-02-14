<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Creates an RBAC role assignment.

.DESCRIPTION
This cmdlet creates a role assignment for a principal (user, group, or application) to grant
permissions via Power Platform RBAC. The role can be scoped at the tenant,
environment, or environment group level.

The Role parameter accepts the role definition name as returned by the Power Platform
Authorization API (e.g., "Power Platform Reader"). Use -RefreshRoles to update the
cached list of available roles.

.OUTPUTS
System.Management.Automation.PSCustomObject
Returns the created role assignment object from the API.

.EXAMPLE
New-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -PrincipalObjectId "00000000-0000-0000-0000-000000000001" -PrincipalType User -Role "Power Platform Reader" -TenantId "00000000-0000-0000-0000-000000000002"

Creates a tenant-scoped role assignment for a user with the "Power Platform Reader" role.

.EXAMPLE
New-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -PrincipalObjectId "00000000-0000-0000-0000-000000000001" -PrincipalType Group -Role "Power Platform Reader" -TenantId "00000000-0000-0000-0000-000000000002" -EnvironmentId "00000000-0000-0000-0000-000000000003"

Creates an environment-scoped role assignment for a group.

.EXAMPLE
New-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -PrincipalObjectId "00000000-0000-0000-0000-000000000001" -PrincipalType ApplicationUser -Role "Power Platform Reader" -TenantId "00000000-0000-0000-0000-000000000002" -EnvironmentGroupId "00000000-0000-0000-0000-000000000004"

Creates an environment group-scoped role assignment for an application.

.EXAMPLE
New-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -PrincipalObjectId "00000000-0000-0000-0000-000000000001" -PrincipalType User -Role "Power Platform Reader" -TenantId "00000000-0000-0000-0000-000000000002" -RefreshRoles

Creates a role assignment while forcing a refresh of the cached role definitions.
#>

function New-RBACRoleAssignment {
    [CmdletBinding(DefaultParameterSetName = 'TenantScope')]
    param(
        [Parameter(Mandatory, HelpMessage="The application (client) ID of the app registration")]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,

        [Parameter(Mandatory, HelpMessage="The object ID of the principal to assign the role to")]
        [ValidateNotNullOrEmpty()]
        [string]$PrincipalObjectId,

        [Parameter(Mandatory, HelpMessage="The type of principal")]
        [AuthorizationPrincipalType]$PrincipalType,

        [Parameter(Mandatory, HelpMessage="The role definition name to assign (e.g., 'Power Platform Reader')")]
        [ValidateNotNullOrEmpty()]
        [string]$Role,

        [Parameter(Mandatory, HelpMessage="The Azure AD tenant ID")]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory, ParameterSetName = 'EnvironmentScope', HelpMessage="The environment ID for environment-scoped assignments")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory, ParameterSetName = 'EnvironmentGroupScope', HelpMessage="The environment group ID for environment group-scoped assignments")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentGroupId,

        [Parameter(Mandatory=$false, HelpMessage="The BAP endpoint to connect to")]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication instead of reusing existing session")]
        [switch]$ForceAuth,

        [Parameter(Mandatory=$false, HelpMessage="Force re-fetch of role definitions from the API")]
        [switch]$RefreshRoles
    )

    $ErrorActionPreference = "Stop"

    # Connect to Authorization Service
    if (-not(New-AuthorizationServiceMsalClient -ClientId $ClientId -TenantId $TenantId -Endpoint $Endpoint -Force:$ForceAuth)) {
        throw "Failed to connect to Authorization Service. Please check your credentials and try again."
    }

    # Resolve role name to role definition ID
    $roleDefinitionId = Resolve-RoleDefinitionId -RoleName $Role -Endpoint $Endpoint -RefreshRoles:$RefreshRoles

    # Build parameters for the generic function
    $params = @{
        PrincipalObjectId = $PrincipalObjectId
        PrincipalType = $PrincipalType
        RoleDefinitionId = $roleDefinitionId
        TenantId = $TenantId
        Endpoint = $Endpoint
    }

    if (-not [string]::IsNullOrWhiteSpace($EnvironmentId)) {
        $params['EnvironmentId'] = $EnvironmentId
    }

    if (-not [string]::IsNullOrWhiteSpace($EnvironmentGroupId)) {
        $params['EnvironmentGroupId'] = $EnvironmentGroupId
    }

    $roleAssignment = New-RoleAssignment @params

    if ($roleAssignment) {
        Write-Host "Role assignment created successfully." -ForegroundColor Green
        Write-Host "  Principal Object ID: $PrincipalObjectId" -ForegroundColor Green
        Write-Host "  Principal Type: $PrincipalType" -ForegroundColor Green
        Write-Host "  Role: $Role" -ForegroundColor Green
        return $roleAssignment
    }

    Write-Host "Role assignment created successfully." -ForegroundColor Green
}
