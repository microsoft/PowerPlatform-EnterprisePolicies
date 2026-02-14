<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Removes an RBAC role assignment.

.DESCRIPTION
This cmdlet removes a role assignment by its ID. The scope can be at the tenant,
environment, or environment group level.

If -ClientId is not specified, the cmdlet uses the cached ClientId from a previous call to
New-AuthorizationApplication or any RBAC cmdlet that was given -ClientId explicitly.
When -ClientId is provided, it is stored in the cache for future use.

Returns $true if the role assignment was deleted, $false if it was not found.

.OUTPUTS
System.Boolean
Returns $true if the role assignment was deleted, $false if it was not found.

.EXAMPLE
Remove-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -RoleAssignmentId "00000000-0000-0000-0000-000000000001" -TenantId "00000000-0000-0000-0000-000000000002"

Removes a tenant-scoped role assignment.

.EXAMPLE
Remove-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -RoleAssignmentId "00000000-0000-0000-0000-000000000001" -TenantId "00000000-0000-0000-0000-000000000002" -EnvironmentId "00000000-0000-0000-0000-000000000003"

Removes an environment-scoped role assignment.

.EXAMPLE
Remove-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -RoleAssignmentId "00000000-0000-0000-0000-000000000001" -TenantId "00000000-0000-0000-0000-000000000002" -EnvironmentGroupId "00000000-0000-0000-0000-000000000004"

Removes an environment group-scoped role assignment.
#>

function Remove-RBACRoleAssignment {
    [CmdletBinding(DefaultParameterSetName = 'TenantScope', SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory=$false, HelpMessage="The application (client) ID of the app registration")]
        [string]$ClientId,

        [Parameter(Mandatory, HelpMessage="The ID of the role assignment to remove")]
        [ValidateNotNullOrEmpty()]
        [string]$RoleAssignmentId,

        [Parameter(Mandatory, HelpMessage="The Azure AD tenant ID")]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory, ParameterSetName = 'EnvironmentScope', HelpMessage="The environment ID for environment-scoped role assignments")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory, ParameterSetName = 'EnvironmentGroupScope', HelpMessage="The environment group ID for environment group-scoped role assignments")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentGroupId,

        [Parameter(Mandatory=$false, HelpMessage="The BAP endpoint to connect to")]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication instead of reusing existing session")]
        [switch]$ForceAuth,

        [Parameter(Mandatory=$false, HelpMessage="Remove the role assignment without prompting for confirmation")]
        [switch]$Force
    )

    $ErrorActionPreference = "Stop"

    if ([string]::IsNullOrWhiteSpace($ClientId)) {
        $ClientId = Get-CachedClientId
        if ([string]::IsNullOrWhiteSpace($ClientId)) {
            throw "ClientId was not provided and no cached ClientId was found. Run New-AuthorizationApplication or specify -ClientId."
        }
    }
    else {
        Set-CachedClientId -ClientId $ClientId
    }

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    # Connect to Authorization Service
    if (-not(New-AuthorizationServiceMsalClient -ClientId $ClientId -TenantId $TenantId -Endpoint $Endpoint -Force:$ForceAuth)) {
        throw "Failed to connect to Authorization Service. Please check your credentials and try again."
    }

    # Build parameters for the generic function
    $params = @{
        RoleAssignmentId = $RoleAssignmentId
        Endpoint = $Endpoint
    }

    if (-not [string]::IsNullOrWhiteSpace($EnvironmentId)) {
        $params['EnvironmentId'] = $EnvironmentId
    }

    if (-not [string]::IsNullOrWhiteSpace($EnvironmentGroupId)) {
        $params['EnvironmentGroupId'] = $EnvironmentGroupId
    }

    if ($PSCmdlet.ShouldProcess($RoleAssignmentId, "Remove RBAC Role Assignment")) {
        $result = Remove-RoleAssignment @params

        if ($result) {
            Write-Host "Role assignment '$RoleAssignmentId' removed successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Role assignment '$RoleAssignmentId' was not found." -ForegroundColor Yellow
        }

        return $result
    }
}
