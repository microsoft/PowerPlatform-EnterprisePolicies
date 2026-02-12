<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Tests RBAC diagnostic permissions for a principal on an environment.

.DESCRIPTION
This cmdlet tests whether a principal (user, group, or application) has a specific
Subnet Injection diagnostic permission on a Power Platform environment.

Use one of the switches to test a specific permission level:
- ReadDiagnostic: Can view diagnostic information
- RunDiagnostic: Can execute diagnostic actions
- RunMitigation: Can execute mitigation actions

Exactly one switch must be specified.

.OUTPUTS
System.Management.Automation.PSCustomObject
Returns the permission check results from the API.

.EXAMPLE
Test-RBACDiagnosticPermission -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -EnvironmentId "00000000-0000-0000-0000-000000000002" -PrincipalObjectId "00000000-0000-0000-0000-000000000003" -PrincipalType User -ReadDiagnostic

Tests the ReadDiagnostic permission for a user on the specified environment.

.EXAMPLE
Test-RBACDiagnosticPermission -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -EnvironmentId "00000000-0000-0000-0000-000000000002" -PrincipalObjectId "00000000-0000-0000-0000-000000000003" -PrincipalType ApplicationUser -RunDiagnostic

Tests the RunDiagnostic permission for an application user.

.EXAMPLE
Test-RBACDiagnosticPermission -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -EnvironmentId "00000000-0000-0000-0000-000000000002" -PrincipalObjectId "00000000-0000-0000-0000-000000000003" -PrincipalType Group -RunMitigation

Tests the RunMitigation permission for a group.
#>

function Test-RBACDiagnosticPermission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage="The application (client) ID of the app registration")]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,

        [Parameter(Mandatory, HelpMessage="The Azure AD tenant ID")]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory, HelpMessage="The environment ID to check permissions on")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory, HelpMessage="The object ID of the principal to check permissions for")]
        [ValidateNotNullOrEmpty()]
        [string]$PrincipalObjectId,

        [Parameter(Mandatory, HelpMessage="The type of principal")]
        [AuthorizationPrincipalType]$PrincipalType,

        [Parameter(Mandatory, ParameterSetName='ReadDiagnostic', HelpMessage="Test ReadDiagnostic permission (EnvironmentManagement.SubnetDiagnostics.Read)")]
        [switch]$ReadDiagnostic,

        [Parameter(Mandatory, ParameterSetName='RunDiagnostic', HelpMessage="Test RunDiagnostic permission (EnvironmentManagement.SubnetDiagnostics.Action)")]
        [switch]$RunDiagnostic,

        [Parameter(Mandatory, ParameterSetName='RunMitigation', HelpMessage="Test RunMitigation permission (EnvironmentManagement.SubnetDiagnostics.Write)")]
        [switch]$RunMitigation,

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

    # Determine permission based on parameter set
    $permission = switch ($PSCmdlet.ParameterSetName) {
        'ReadDiagnostic' { "EnvironmentManagement.SubnetDiagnostics.Read" }
        'RunDiagnostic' { "EnvironmentManagement.SubnetDiagnostics.Action" }
        'RunMitigation' { "EnvironmentManagement.SubnetDiagnostics.Write" }
    }

    $result = Test-PrincipalPermission `
        -TenantId $TenantId `
        -EnvironmentId $EnvironmentId `
        -PrincipalObjectId $PrincipalObjectId `
        -PrincipalType $PrincipalType `
        -Permissions @($permission) `
        -Endpoint $Endpoint

    return $result
}
