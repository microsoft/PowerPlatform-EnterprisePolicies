<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

function Set-PlatformAppsDataCMK {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateAzureResourceId("Microsoft.PowerPlatform/enterprisePolicies")]
        [string]$PolicyArmId,

        [Parameter(Mandatory)]
        [LinkOperation]$Operation,

        [Parameter(Mandatory)]
        [PPEndpoint]$Endpoint,

        [Parameter(Mandatory=$false)]
        [string]$TenantId
    )

    $ErrorActionPreference = "Stop"

    $baseUri = Get-PPEndpointUrl -Endpoint $Endpoint
    $statusUri = "${baseUri}providers/Microsoft.BusinessAppPlatform/platformapps/status?api-version=2024-05-01"
    $statusResult = Send-RequestWithRetries -RequestFactory {
        return New-JsonRequestMessage -Uri $statusUri -AccessToken (Get-PPAccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Get)
    } -MaxRetries 3 -DelaySeconds 5

    $statusContent = Get-AsyncResult -Task $statusResult.Content.ReadAsStringAsync()
    if (-not $statusResult.IsSuccessStatusCode) {
        throw "Failed to retrieve PlatformAppsData status. Status code: $($statusResult.StatusCode). $statusContent"
    }

    $status = $statusContent | ConvertFrom-Json
    if ($null -eq $status -or $status.enrollmentState -ne "Enrolled") {
        throw "PlatformAppsData is not enrolled."
    }

    if ($Operation -eq [LinkOperation]::unlink) {
        if ($null -eq $status.enterprisePolicies -or $null -eq $status.enterprisePolicies.CustomerManagedKeys) {
            throw "No CMK enterprise policy is linked to PlatformAppsData."
        }

        $linkedPolicyArmId = $status.enterprisePolicies.CustomerManagedKeys.id
        if ($PolicyArmId -ine $linkedPolicyArmId) {
            throw "The supplied policy ARM ID does not match the CMK policy linked to PlatformAppsData: $linkedPolicyArmId"
        }
    }

    $null = $PolicyArmId -match "/subscriptions/([^/]+)/"
    $null = Set-SubscriptionContext -SubscriptionId $Matches[1]

    $policy = Get-EnterprisePolicy -PolicyArmId $PolicyArmId
    if ($null -eq $policy) {
        throw "Failed to retrieve enterprise policy with ARM ID: $PolicyArmId"
    }
    if ($policy.Kind -ne "Encryption") {
        throw "The specified policy is not a CMK (Encryption) policy. Policy kind: $($policy.Kind)"
    }

    $policySystemId = $policy.Properties.systemId
    if ([string]::IsNullOrWhiteSpace($policySystemId)) {
        throw "Enterprise policy does not have a systemId. The policy may not be fully provisioned."
    }

    $uri = "${baseUri}providers/Microsoft.BusinessAppPlatform/platformapps/enterprisePolicies/Encryption/${Operation}?api-version=2024-05-01"
    $body = @{ SystemId = $policySystemId } | ConvertTo-Json
    $result = Send-RequestWithRetries -RequestFactory {
        return New-JsonRequestMessage -Uri $uri -AccessToken (Get-PPAccessToken -Endpoint $Endpoint -TenantId $TenantId) -Content $body -HttpMethod ([System.Net.Http.HttpMethod]::Post)
    } -MaxRetries 3 -DelaySeconds 5

    if ($result.StatusCode -ne 202) {
        $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()
        throw "Failed to initiate PlatformAppsData $Operation operation. Status code: $($result.StatusCode). $contentString"
    }

    Write-Host "CMK $Operation operation initiated for PlatformAppsData. Completion has not been awaited." -ForegroundColor Green
    return $true
}
