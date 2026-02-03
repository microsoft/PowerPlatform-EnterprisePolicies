<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Creates a role assignment for Authorization.

.DESCRIPTION
This cmdlet creates a role assignment for a principal (user, group, or application) to grant
permissions for Authorization operations. The role can be scoped at the tenant,
environment, or environment group level.

Available roles:
- Administrator: Full administrative access
- Reader: Read-only access
- Contributor: Contributor access
- Owner: Owner access with full control

.OUTPUTS
System.Management.Automation.PSCustomObject
Returns the created role assignment object from the API.

.EXAMPLE
New-AuthorizationRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -PrincipalObjectId "00000000-0000-0000-0000-000000000001" -PrincipalType User -Role Reader -TenantId "00000000-0000-0000-0000-000000000002"

Creates a tenant-scoped Reader role assignment for a user.

.EXAMPLE
New-AuthorizationRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -PrincipalObjectId "00000000-0000-0000-0000-000000000001" -PrincipalType Group -Role Contributor -TenantId "00000000-0000-0000-0000-000000000002" -EnvironmentId "00000000-0000-0000-0000-000000000003"

Creates an environment-scoped Contributor role assignment for a group.

.EXAMPLE
New-AuthorizationRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -PrincipalObjectId "00000000-0000-0000-0000-000000000001" -PrincipalType ApplicationUser -Role Owner -TenantId "00000000-0000-0000-0000-000000000002" -EnvironmentGroupId "00000000-0000-0000-0000-000000000004"

Creates an environment group-scoped Owner role assignment for an application.
#>

function New-AuthorizationRoleAssignment {
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

        [Parameter(Mandatory, HelpMessage="The role to assign")]
        [AuthorizationRole]$Role,

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
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    # Connect to Authorization Service
    if (-not(New-AuthorizationServiceMsalClient -ClientId $ClientId -TenantId $TenantId -Endpoint $Endpoint -Force:$ForceAuth)) {
        throw "Failed to connect to Authorization Service. Please check your credentials and try again."
    }

    # Map role to role definition ID
    $roleDefinitionId = switch ($Role) {
        ([AuthorizationRole]::Administrator) { "95e94555-018c-447b-8691-bdac8e12211e" }
        ([AuthorizationRole]::Reader) { "c886ad2e-27f7-4874-8381-5849b8d8a090" }
        ([AuthorizationRole]::Contributor) { "ff954d61-a89a-4fbe-ace9-01c367b89f87" }
        ([AuthorizationRole]::Owner) { "0cb07c69-1631-4725-ab35-e59e001c51ea" }
    }

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
