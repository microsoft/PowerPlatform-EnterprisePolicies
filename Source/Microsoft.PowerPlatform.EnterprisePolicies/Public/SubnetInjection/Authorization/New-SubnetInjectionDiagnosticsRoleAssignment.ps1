<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Creates a role assignment for Subnet Injection Diagnostics.

.DESCRIPTION
This cmdlet creates a role assignment for a principal (user, group, or application) to grant
permissions for Subnet Injection Diagnostics operations. The role can be scoped at the tenant,
environment, or environment group level.

Available roles:
- Administrator: Full administrative access to Subnet Injection Diagnostics
- Operator: Operational access to Subnet Injection Diagnostics
- Reader: Read-only access to Subnet Injection Diagnostics

.OUTPUTS
System.Management.Automation.PSCustomObject
Returns the created role assignment object from the API.

.EXAMPLE
New-SubnetInjectionDiagnosticsRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -PrincipalObjectId "00000000-0000-0000-0000-000000000001" -PrincipalType User -Role Reader -TenantId "00000000-0000-0000-0000-000000000002"

Creates a tenant-scoped Reader role assignment for a user.

.EXAMPLE
New-SubnetInjectionDiagnosticsRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -PrincipalObjectId "00000000-0000-0000-0000-000000000001" -PrincipalType Group -Role Operator -TenantId "00000000-0000-0000-0000-000000000002" -EnvironmentId "00000000-0000-0000-0000-000000000003"

Creates an environment-scoped Operator role assignment for a group.

.EXAMPLE
New-SubnetInjectionDiagnosticsRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -PrincipalObjectId "00000000-0000-0000-0000-000000000001" -PrincipalType ApplicationUser -Role Administrator -TenantId "00000000-0000-0000-0000-000000000002" -EnvironmentGroupId "00000000-0000-0000-0000-000000000004"

Creates an environment group-scoped Administrator role assignment for an application.
#>

function New-SubnetInjectionDiagnosticsRoleAssignment {
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
        [SubnetInjectionDiagnosticsRole]$Role,

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
        ([SubnetInjectionDiagnosticsRole]::Administrator) { "d6a1e3c4-9f5b-4d8e-b2c7-7a4e3f1d9b8c" }
        ([SubnetInjectionDiagnosticsRole]::Operator) { "b4e9c1a2-6d3f-4a8b-9e7c-5f2d1b8a3c6e" }
        ([SubnetInjectionDiagnosticsRole]::Reader) { "c5f0d2b3-8e4a-4c7d-a1b9-6e3f2d8c5a4b" }
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
