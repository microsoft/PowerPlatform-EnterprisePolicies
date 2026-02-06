<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Validates that the account has the correct permissions to run diagnostic commands.

.DESCRIPTION
Tests that the generated Bearer token for the logged in account has the claim that is necessary to be able to call the diagnostic APIs.
The necessary permission is the Power Platform Administrator role which is assigned through the Entra portal.

.OUTPUTS
System.Boolean
Whether the account has the required permissions.

.EXAMPLE
Test-AccountPermissions

.EXAMPLE
Test-AccountPermissions -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint [BAPEndpoint]::Prod
#>

function Test-AccountPermissions{
    param(
        [Parameter(Mandatory=$false, HelpMessage="The id of the tenant that the environment belongs to.")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The BAP endpoint to connect to. Default is 'prod'.")]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication to Azure.")]
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    $token = Get-PPAPIAccessToken -TenantId $TenantId -Endpoint $Endpoint
    $parts = $token.Split('.')
    if ($parts.Count -ne 3) {
        throw "Token is not in an expected format."
    }

    $pad = '=' * ((4 - $parts[1].Length % 4) % 4)
    $base64 = ($parts[1] + $pad).Replace('-', '+').Replace('_', '/')

    $payload = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($base64)) | ConvertFrom-Json

    if(-not($payload.wids)){
        Write-Host "Token does not contain wids claim. Check that the user has roles assigned in Entra." -ForegroundColor Red
        return $false
    }

    if($payload.wids | Where-Object { $_ -eq "11648597-926c-4cf3-9c36-bcebb0ba8dcc"} ){
        Write-Host "Token contains Power Platform Administrator role." -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "Token does not contain required Power Platform Administrator role." -ForegroundColor Red
        return $false
    }
}



