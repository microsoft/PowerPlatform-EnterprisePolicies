<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Gets Power Platform RBAC role assignments at a specified scope.

.DESCRIPTION
This cmdlet retrieves role assignments for Power Platform RBAC operations. The scope can be
at the tenant or environment level.

If -ClientId is not specified, the cmdlet uses the cached ClientId from a previous call to
New-AuthorizationApplication or any Power Platform RBAC cmdlet that was given -ClientId explicitly.
When -ClientId is provided, it is stored in the cache for future use.

By default, results include parent scopes, nested scopes, expanded security groups, and
expanded environment groups. Use the corresponding switches to disable these behaviors.

.OUTPUTS
System.Management.Automation.PSCustomObject
Returns the role assignments from the API.

.EXAMPLE
Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001"

Gets all role assignments at the tenant scope with all expansions enabled.

.EXAMPLE
Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -EnvironmentId "00000000-0000-0000-0000-000000000002"

Gets all role assignments at the environment scope with all expansions enabled.

.EXAMPLE
Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -EnvironmentId "00000000-0000-0000-0000-000000000002" -ExcludeParentScopes -NoExpandSecurityGroups

Gets role assignments at the environment scope, excluding parent scopes and without expanding security group memberships.

.EXAMPLE
Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -ExcludeNestedScopes -NoExpandEnvironmentGroups

Gets role assignments at the tenant scope, excluding nested scopes and without expanding environment group memberships.

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
        [Parameter(Mandatory=$false, HelpMessage="The application (client) ID of the app registration")]
        [string]$ClientId,

        [Parameter(Mandatory, HelpMessage="The Azure AD tenant ID")]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory, ParameterSetName = 'EnvironmentScope', HelpMessage="The environment ID for environment-scoped queries")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory=$false, HelpMessage="Exclude role assignments from parent scopes")]
        [switch]$ExcludeParentScopes,

        [Parameter(Mandatory=$false, HelpMessage="Do not expand security group memberships in the results")]
        [switch]$NoExpandSecurityGroups,

        [Parameter(Mandatory=$false, HelpMessage="Do not expand environment group memberships in the results")]
        [switch]$NoExpandEnvironmentGroups,

        [Parameter(Mandatory=$false, HelpMessage="Exclude role assignments from nested scopes")]
        [switch]$ExcludeNestedScopes,

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

    # Connect to Authorization Service (resolves ClientId from cache if not provided)
    if (-not(New-AuthorizationServiceMsalClient -ClientId $ClientId -TenantId $TenantId -Endpoint $Endpoint -Force:$ForceAuth)) {
        throw "Failed to connect to Authorization Service. Please check your credentials and try again."
    }

    # Build parameters for the generic function (switches are negatives, so invert)
    $params = @{
        TenantId = $TenantId
        IncludeParentScopes = -not $ExcludeParentScopes.IsPresent
        ExpandSecurityGroups = -not $NoExpandSecurityGroups.IsPresent
        ExpandEnvironmentGroups = -not $NoExpandEnvironmentGroups.IsPresent
        IncludeNestedScopes = -not $ExcludeNestedScopes.IsPresent
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
