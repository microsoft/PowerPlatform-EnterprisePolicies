<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Disables subnet injection for a Power Platform environment by unlinking it from its enterprise policy.

.DESCRIPTION
The Disable-SubnetInjection cmdlet unlinks the subnet injection enterprise policy from a Power Platform environment,
disabling the environment's use of delegated virtual network subnets.

The operation is asynchronous. By default, the cmdlet waits for the operation to complete.
Use -NoWait to return immediately after the operation is initiated.

.OUTPUTS
System.Boolean

Returns $true when the operation completes successfully, or when -NoWait is specified and the operation is initiated.

.EXAMPLE
Disable-SubnetInjection -EnvironmentId "00000000-0000-0000-0000-000000000000"

Disables subnet injection for the environment by unlinking it from its currently linked policy.

.EXAMPLE
Disable-SubnetInjection -EnvironmentId "00000000-0000-0000-0000-000000000000" -TenantId "aaaabbbb-0000-cccc-1111-dddd2222eeee" -Endpoint usgovhigh

Disables subnet injection for an environment in the US Government High cloud.

.EXAMPLE
Disable-SubnetInjection -EnvironmentId "00000000-0000-0000-0000-000000000000" -NoWait

Initiates the unlink operation without waiting for completion.
#>

function Disable-SubnetInjection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage="The Power Platform environment ID")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory=$false, HelpMessage="The Azure AD tenant ID")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The PP endpoint to connect to")]
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication instead of reusing existing session")]
        [switch]$ForceAuth,

        [Parameter(Mandatory=$false, HelpMessage="Return immediately without waiting for the operation to complete")]
        [switch]$NoWait,

        [Parameter(Mandatory=$false, HelpMessage="Maximum time in seconds to wait for the operation to complete")]
        [int]$TimeoutSeconds = 600
    )

    $ErrorActionPreference = "Stop"

    # Connect to Azure
    if (-not(Connect-Azure -Endpoint $Endpoint -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    # Validate that the environment exists
    Write-Verbose "Retrieving environment: $EnvironmentId"
    $environment = Get-PPEnvironment -EnvironmentId $EnvironmentId -Endpoint $Endpoint -TenantId $TenantId

    if ($null -eq $environment) {
        throw "Failed to retrieve environment with ID: $EnvironmentId. If the environment exists, ensure you have the necessary permissions to access it and that you are connecting to the correct PP endpoint."
    }

    Write-Verbose "Environment retrieved successfully"

    # Check if environment has Subnet Injection enabled
    if ($null -eq $environment.properties.enterprisePolicies -or $null -eq $environment.properties.enterprisePolicies.VNets) {
        Write-Host "Subnet Injection is not enabled for this environment." -ForegroundColor Yellow
        return $false
    }

    # Get the linked policy ARM ID from the environment
    $linkedPolicyArmId = $environment.properties.enterprisePolicies.VNets.id
    Write-Verbose "Environment is linked to policy: $linkedPolicyArmId"

    # Extract subscription ID from policy ARM ID and set context
    if ($linkedPolicyArmId -match "/subscriptions/([^/]+)/") {
        $subscriptionId = $Matches[1]
        Write-Verbose "Setting subscription context to $subscriptionId"
        $null = Set-AzContext -Subscription $subscriptionId
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
    Write-Verbose "Disabling Subnet Injection for environment..."
    $unlinkResult = Set-EnvironmentEnterprisePolicy -EnvironmentId $EnvironmentId -PolicyType ([PolicyType]::NetworkInjection) -PolicySystemId $policySystemId -Operation ([LinkOperation]::unlink) -Endpoint $Endpoint -TenantId $TenantId

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

    Write-Host "Subnet Injection disabled successfully for environment $EnvironmentId" -ForegroundColor Green

    return $operationResult -eq "Succeeded"
}
