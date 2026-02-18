<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

function Get-PPEnvironment {
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentId,
        [Parameter(Mandatory)]
        [PPEndpoint]$Endpoint,
        [Parameter(Mandatory=$false)]
        [string]$TenantId
    )

    $apiVersion = "2016-11-01"
    $baseUri = Get-PPEndpointUrl -Endpoint $Endpoint
    $uri = "${baseUri}providers/Microsoft.BusinessAppPlatform/environments/${EnvironmentId}?api-version=${apiVersion}"

    $result = Send-RequestWithRetries -RequestFactory {
        return New-JsonRequestMessage -Uri $uri -AccessToken (Get-PPAccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Get)
     } -MaxRetries 3 -DelaySeconds 5

    if (-not $result.IsSuccessStatusCode) {
        $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()
        throw "Failed to retrieve environment. Status code: $($result.StatusCode). $contentString"
    }

    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()
    $environment = $contentString | ConvertFrom-Json

    return $environment
}

function Set-EnvironmentEnterprisePolicy {
    <#
    .SYNOPSIS
    Links or unlinks an enterprise policy to/from a Power Platform environment.

    .DESCRIPTION
    Calls the PP API to link or unlink an enterprise policy to/from a Power Platform environment.
    This is an async operation that returns a 202 Accepted response with operation-location header.

    .PARAMETER EnvironmentId
    The Power Platform environment ID.

    .PARAMETER PolicyType
    The type of enterprise policy (NetworkInjection, Encryption, Identity).

    .PARAMETER PolicySystemId
    The system ID of the enterprise policy (from properties.systemId). Required for link operations.

    .PARAMETER Operation
    The operation to perform: link or unlink.

    .PARAMETER Endpoint
    The PP endpoint to use.

    .PARAMETER TenantId
    Optional Azure AD tenant ID.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentId,

        [Parameter(Mandatory)]
        [PolicyType]$PolicyType,

        [Parameter(Mandatory)]
        [string]$PolicySystemId,

        [Parameter(Mandatory)]
        [LinkOperation]$Operation,

        [Parameter(Mandatory)]
        [PPEndpoint]$Endpoint,

        [Parameter(Mandatory=$false)]
        [string]$TenantId
    )

    $apiVersion = "2019-10-01"
    $baseUri = Get-PPEndpointUrl -Endpoint $Endpoint
    $uri = "${baseUri}providers/Microsoft.BusinessAppPlatform/environments/${EnvironmentId}/enterprisePolicies/${PolicyType}/${Operation}?api-version=${apiVersion}"

    $body = @{ SystemId = $PolicySystemId } | ConvertTo-Json

    $result = Send-RequestWithRetries -RequestFactory {
        return New-JsonRequestMessage -Uri $uri -AccessToken (Get-PPAccessToken -Endpoint $Endpoint -TenantId $TenantId) -Content $body -HttpMethod ([System.Net.Http.HttpMethod]::Post)
    } -MaxRetries 3 -DelaySeconds 5

    return $result
}

function Wait-EnterprisePolicyOperation {
    <#
    .SYNOPSIS
    Polls an enterprise policy operation until completion.

    .DESCRIPTION
    Polls the operation-location URL returned from a link/unlink operation until it succeeds, fails, or times out.

    .PARAMETER OperationUrl
    The operation-location URL to poll.

    .PARAMETER Endpoint
    The PP endpoint to use.

    .PARAMETER TenantId
    Optional Azure AD tenant ID.

    .PARAMETER TimeoutSeconds
    Maximum time to wait for the operation to complete. Default is 600 seconds (10 minutes).

    .PARAMETER PollIntervalSeconds
    Interval between polls when operation is running. Default is 15 seconds.

    .PARAMETER NotStartedPollIntervalSeconds
    Interval between polls when operation has not started yet. Default is 5 seconds.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$OperationUrl,

        [Parameter(Mandatory)]
        [PPEndpoint]$Endpoint,

        [Parameter(Mandatory=$false)]
        [string]$TenantId,

        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 600,

        [Parameter(Mandatory=$false)]
        [int]$PollIntervalSeconds = 15,

        [Parameter(Mandatory=$false)]
        [int]$NotStartedPollIntervalSeconds = 5
    )

    $elapsed = 0
    while ($elapsed -lt $TimeoutSeconds) {
        $result = Send-RequestWithRetries -RequestFactory {
            return New-JsonRequestMessage -Uri $OperationUrl -AccessToken (Get-PPAccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Get)
        } -MaxRetries 3 -DelaySeconds 5

        if (-not $result.IsSuccessStatusCode) {
            $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()
            throw "Failed to poll operation status. Status code: $($result.StatusCode). $contentString"
        }

        $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()
        $operation = $contentString | ConvertFrom-Json

        if ($null -eq $operation -or $null -eq $operation.state -or $null -eq $operation.state.id) {
            throw "Invalid operation response: $contentString"
        }

        $state = $operation.state.id
        Write-Verbose "Operation state: $state"

        switch ($state) {
            "Succeeded" {
                return $state
            }
            "Failed" {
                $errorMessage = if ($operation.error -and $operation.error.message) { $operation.error.message } else { "Unknown error" }
                throw "Enterprise policy operation failed: $errorMessage"
            }
            "Running" {
                Write-Host "Operation in progress ($state). Waiting $PollIntervalSeconds seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds $PollIntervalSeconds
                $elapsed += $PollIntervalSeconds
            }
            "NotStarted" {
                Write-Host "Operation not started yet. Waiting $NotStartedPollIntervalSeconds seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds $NotStartedPollIntervalSeconds
                $elapsed += $NotStartedPollIntervalSeconds
            }
            default {
                throw "Unknown operation state: $state"
            }
        }
    }

    throw "Operation timed out after $TimeoutSeconds seconds"
}
