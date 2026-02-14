<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Gets RBAC role assignments at a specified scope.

.DESCRIPTION
This cmdlet retrieves role assignments for Power Platform RBAC operations. The scope can be
at the tenant or environment level.

Options allow expanding security groups, environment groups, including parent scopes,
and including nested scopes in the results.

.OUTPUTS
System.Management.Automation.PSCustomObject
Returns the role assignments from the API.

.EXAMPLE
Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001"

Gets all role assignments at the tenant scope.

.EXAMPLE
Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -EnvironmentId "00000000-0000-0000-0000-000000000002"

Gets all role assignments at the environment scope.

.EXAMPLE
Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -EnvironmentId "00000000-0000-0000-0000-000000000002" -IncludeParentScopes -ExpandSecurityGroups

Gets role assignments at the environment scope, including parent scopes and expanding security group memberships.

.EXAMPLE
Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -IncludeNestedScopes -ExpandEnvironmentGroups

Gets role assignments at the tenant scope, including nested scopes and expanding environment group memberships.

.EXAMPLE
Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -PrincipalType User -PrincipalObjectId "00000000-0000-0000-0000-000000000005"

Gets role assignments for a specific user principal.

.EXAMPLE
Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -Permission "Read"

Gets role assignments filtered by a specific permission.
#>

function Get-RBACRoleAssignment {
    [CmdletBinding(DefaultParameterSetName = 'TenantScope')]
    param(
        [Parameter(Mandatory, HelpMessage="The application (client) ID of the app registration")]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,

        [Parameter(Mandatory, HelpMessage="The Azure AD tenant ID")]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory, ParameterSetName = 'EnvironmentScope', HelpMessage="The environment ID for environment-scoped queries")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory=$false, HelpMessage="Include role assignments from parent scopes")]
        [switch]$IncludeParentScopes,

        [Parameter(Mandatory=$false, HelpMessage="Expand security group memberships in the results")]
        [switch]$ExpandSecurityGroups,

        [Parameter(Mandatory=$false, HelpMessage="Expand environment group memberships in the results")]
        [switch]$ExpandEnvironmentGroups,

        [Parameter(Mandatory=$false, HelpMessage="Include role assignments from nested scopes")]
        [switch]$IncludeNestedScopes,

        [Parameter(Mandatory=$false, HelpMessage="Filter by principal type")]
        [AuthorizationPrincipalType]$PrincipalType,

        [Parameter(Mandatory=$false, HelpMessage="Filter by principal object ID")]
        [string]$PrincipalObjectId,

        [Parameter(Mandatory=$false, HelpMessage="Filter by permission name")]
        [string]$Permission,

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

    # Build parameters for the generic function
    $params = @{
        TenantId = $TenantId
        IncludeParentScopes = $IncludeParentScopes.IsPresent
        ExpandSecurityGroups = $ExpandSecurityGroups.IsPresent
        ExpandEnvironmentGroups = $ExpandEnvironmentGroups.IsPresent
        IncludeNestedScopes = $IncludeNestedScopes.IsPresent
        Endpoint = $Endpoint
    }

    if (-not [string]::IsNullOrWhiteSpace($EnvironmentId)) {
        $params['EnvironmentId'] = $EnvironmentId
    }

    if ($PSBoundParameters.ContainsKey('PrincipalType')) {
        $params['PrincipalType'] = $PrincipalType
    }

    if (-not [string]::IsNullOrWhiteSpace($PrincipalObjectId)) {
        $params['PrincipalObjectId'] = $PrincipalObjectId
    }

    if (-not [string]::IsNullOrWhiteSpace($Permission)) {
        $params['Permission'] = $Permission
    }

    $roleAssignments = Get-RoleAssignments @params

    return $roleAssignments
}
