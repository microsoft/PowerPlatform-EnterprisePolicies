<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Requests a delegation reset for a Power Platform environment.

.DESCRIPTION
Requests a delegation reset for the specified Power Platform environment.
This allows changes such as updated DNS settings to take effect without unlinking the enterprise policy.
The operation may take up to 100 seconds and causes minor downtime for environments sharing the same virtual network.
You are prompted to confirm before the reset begins; use -Force to skip this prompt.

.OUTPUTS
System.Boolean

Returns $true when the reset completes successfully.

.EXAMPLE
Reset-NetworkDelegation -EnvironmentId "00000000-0000-0000-0000-000000000000" -Region "westus"

Requests a delegation reset for the specified environment in westus.

.EXAMPLE
Reset-NetworkDelegation -EnvironmentId "00000000-0000-0000-0000-000000000000"

Requests a delegation reset using the environment's automatically resolved region.

.EXAMPLE
Reset-NetworkDelegation -EnvironmentId "00000000-0000-0000-0000-000000000000" -Region "usgovvirginia" -Endpoint usgovhigh -WhatIf

Previews a delegation reset for an environment in the US Government High cloud without sending the request.

.EXAMPLE
Reset-NetworkDelegation -EnvironmentId "00000000-0000-0000-0000-000000000000" -Force

Resets network delegation without prompting for confirmation.
#>
function Reset-NetworkDelegation {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, HelpMessage="The Power Platform environment ID.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory=$false, HelpMessage="The Azure region in which to reset delegation. Defaults to the region the environment is in.")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
        [string]$Region,

        [Parameter(Mandatory=$false, HelpMessage="The Entra tenant ID.")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The Power Platform endpoint to connect to. Defaults to 'prod'.")]
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication instead of reusing an existing session.")]
        [switch]$ForceAuth,

        [Parameter(Mandatory=$false, HelpMessage="Reset network delegation without prompting for confirmation.")]
        [switch]$Force
    )

    $ErrorActionPreference = "Stop"

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $target = $EnvironmentId
    if ($Region) {
        $target = "$EnvironmentId (region: $Region)"
    }

    if (-not $PSCmdlet.ShouldProcess($target, "Reset network delegation. Reset will incur a minor downtime on the environments linked to the same vnet.")) {
        return
    }

    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    if ([string]::IsNullOrWhiteSpace($Region)) {
        $resolvedRegion = Get-EnvironmentRegionFromCache -EnvironmentId $EnvironmentId -Endpoint $Endpoint -TenantId $TenantId
        if ([string]::IsNullOrWhiteSpace($resolvedRegion)) {
            throw "Failed to resolve the environment region."
        }
        $Region = $resolvedRegion
    }

    $query = "api-version=2026-02-01&region=$([System.Uri]::EscapeDataString($Region))"
    $request = New-EnvironmentRouteRequest -EnvironmentId $EnvironmentId -Path "/plex/resetDelegation" -Query $query -AccessToken (Get-PPAPIAccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Post) -Endpoint $Endpoint
    Write-Host "Calling the network delegation reset API for environment '$EnvironmentId'. This may take up to 100 seconds to return."
    $null = Send-Request -Request $request
    return $true
}
