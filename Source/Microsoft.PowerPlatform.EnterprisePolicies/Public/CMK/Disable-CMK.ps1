<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Disables customer managed key (CMK) encryption for a Power Platform environment or PlatformAppsData.

.DESCRIPTION
The Disable-CMK cmdlet unlinks the CMK enterprise policy from a Power Platform environment,
reverting the environment to Microsoft managed key encryption.

Environment operations are asynchronous. By default, the cmdlet waits for the operation to complete.
Use -NoWait to return immediately after an environment operation is initiated.

Use -PlatformAppsData instead of -EnvironmentId to unlink the policy through the separate PlatformApps API.
PlatformAppsData must already be enrolled, and -PolicyArmId must match its currently linked CMK policy.
This parameter set preserves the legacy scripts' behavior: it defaults to the tip1 endpoint and returns
after the service accepts the operation, without waiting for completion. Specify -Endpoint explicitly to
target another endpoint. -NoWait and -TimeoutSeconds apply only to environments.

.OUTPUTS
System.Boolean

Returns $true when the environment operation completes successfully, or when -NoWait or -PlatformAppsData is specified and the operation is initiated. Throws an error if no CMK policy is linked.

.EXAMPLE
Disable-CMK -EnvironmentId "00000000-0000-0000-0000-000000000000"

Disables CMK encryption for the environment by unlinking it from its currently linked policy.

.EXAMPLE
Disable-CMK -EnvironmentId "00000000-0000-0000-0000-000000000000" -Endpoint usgovhigh

Disables CMK encryption for an environment in the US Government High cloud.

.EXAMPLE
Disable-CMK -EnvironmentId "00000000-0000-0000-0000-000000000000" -NoWait

Initiates the unlink operation without waiting for completion.

.EXAMPLE
Disable-CMK -PlatformAppsData -PolicyArmId "/subscriptions/aaaabbbb-0000-cccc-1111-dddd2222eeee/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy" -Endpoint prod

Initiates CMK unlinking for enrolled PlatformAppsData only if the specified policy is currently linked, without waiting for completion.
#>

function Disable-CMK {
    [CmdletBinding(DefaultParameterSetName = 'Environment')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Environment', HelpMessage="The Power Platform environment ID")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory, ParameterSetName = 'PlatformAppsData', HelpMessage="Unlink the policy from enrolled PlatformAppsData instead of an environment")]
        [switch]$PlatformAppsData,

        [Parameter(Mandatory, ParameterSetName = 'PlatformAppsData', HelpMessage="The full Azure ARM resource ID of the CMK policy currently linked to PlatformAppsData")]
        [ValidateAzureResourceId("Microsoft.PowerPlatform/enterprisePolicies")]
        [string]$PolicyArmId,

        [Parameter(Mandatory=$false, HelpMessage="The Entra tenant ID")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The Power Platform endpoint. Defaults to prod for environments and tip1 for PlatformAppsData.")]
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="The Azure environment to use. Defaults to the cloud associated with Endpoint.")]
        [AzureEnvironment]$AzureEnvironment,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication instead of reusing existing session")]
        [switch]$ForceAuth,

        [Parameter(Mandatory=$false, ParameterSetName = 'Environment', HelpMessage="Return immediately without waiting for the operation to complete")]
        [switch]$NoWait,

        [Parameter(Mandatory=$false, ParameterSetName = 'Environment', HelpMessage="Maximum time in seconds to wait for the operation to complete")]
        [int]$TimeoutSeconds = 600
    )

    $ErrorActionPreference = "Stop"

    if ($PSCmdlet.ParameterSetName -eq 'PlatformAppsData' -and -not $PSBoundParameters.ContainsKey('Endpoint')) {
        $Endpoint = [PPEndpoint]::tip1
    }

    $connectParams = @{
        TenantId = $TenantId
        Force = $ForceAuth
    }
    if ($PSBoundParameters.ContainsKey('AzureEnvironment')) {
        $connectParams['AzureEnvironment'] = $AzureEnvironment
    }
    else {
        $connectParams['Endpoint'] = $Endpoint
    }

    if (-not(Connect-Azure @connectParams)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    if ($PSCmdlet.ParameterSetName -eq 'PlatformAppsData') {
        return Set-PlatformAppsDataCMK -PolicyArmId $PolicyArmId -Operation ([LinkOperation]::unlink) -Endpoint $Endpoint -TenantId $TenantId
    }

    # Validate that the environment exists
    Write-Verbose "Retrieving environment: $EnvironmentId"
    $environment = Get-PPEnvironment -EnvironmentId $EnvironmentId -Endpoint $Endpoint -TenantId $TenantId

    if ($null -eq $environment) {
        throw "Failed to retrieve environment with ID: $EnvironmentId. If the environment exists, ensure you have the necessary permissions to access it and that you are connecting to the correct PP endpoint."
    }

    Write-Verbose "Environment retrieved successfully"

    # Check if environment has CMK enabled
    if ($null -eq $environment.properties.enterprisePolicies -or $null -eq $environment.properties.enterprisePolicies.CustomerManagedKeys) {
        throw "CMK is not enabled for this environment."
    }

    # Get the linked policy ARM ID from the environment
    $linkedPolicyArmId = $environment.properties.enterprisePolicies.CustomerManagedKeys.id
    Write-Verbose "Environment is linked to policy: $linkedPolicyArmId"

    # Extract subscription ID from policy ARM ID and set context
    if ($linkedPolicyArmId -match "/subscriptions/([^/]+)/") {
        $subscriptionId = $Matches[1]
        Write-Verbose "Setting subscription context to $subscriptionId"
        $null = Set-SubscriptionContext -SubscriptionId $subscriptionId
    }
    else {
        throw "Invalid linked policy ARM ID format: $linkedPolicyArmId"
    }

    # Get the enterprise policy and extract SystemId
    Write-Verbose "Retrieving enterprise policy: $linkedPolicyArmId"
    $policy = Get-EnterprisePolicy -PolicyArmId $linkedPolicyArmId

    if ($null -eq $policy) {
        throw "Failed to retrieve the linked enterprise policy with ARM ID: $linkedPolicyArmId. The policy may have been deleted."
    }

    $policySystemId = $policy.Properties.systemId
    if ([string]::IsNullOrWhiteSpace($policySystemId)) {
        throw "Enterprise policy does not have a systemId. The policy may not be fully provisioned."
    }

    Write-Verbose "Enterprise policy SystemId: $policySystemId"

    # Unlink the policy from the environment
    Write-Verbose "Disabling CMK for environment..."
    $unlinkResult = Set-EnvironmentEnterprisePolicy -EnvironmentId $EnvironmentId -PolicyType ([PolicyType]::Encryption) -PolicySystemId $policySystemId -Operation ([LinkOperation]::unlink) -Endpoint $Endpoint -TenantId $TenantId

    if ($unlinkResult.StatusCode -ne 202) {
        $contentString = Get-AsyncResult -Task $unlinkResult.Content.ReadAsStringAsync()
        throw "Failed to initiate unlink operation. Status code: $($unlinkResult.StatusCode). $contentString"
    }

    Write-Verbose "Unlink operation initiated successfully"

    if ($NoWait) {
        Write-Host "Operation initiated. Use the Power Platform admin center to check the operation status." -ForegroundColor Green
        return $true
    }

    # Get operation-location header and poll for completion
    if (-not $unlinkResult.Headers.Contains("operation-location")) {
        throw "Unlink response did not contain operation-location header"
    }

    $operationUrl = $unlinkResult.Headers.GetValues("operation-location") | Select-Object -First 1
    Write-Verbose "Polling operation: $operationUrl"

    $operationResult = Wait-EnterprisePolicyOperation -OperationUrl $operationUrl -Endpoint $Endpoint -TenantId $TenantId -TimeoutSeconds $TimeoutSeconds

    if ($operationResult -eq "Succeeded") {
        Write-Host "CMK disabled successfully for environment $EnvironmentId" -ForegroundColor Green
    }
    else {
        Write-Warning "CMK disable operation did not complete successfully for environment $EnvironmentId. Final status: $operationResult"
    }

    return $operationResult -eq "Succeeded"
}
