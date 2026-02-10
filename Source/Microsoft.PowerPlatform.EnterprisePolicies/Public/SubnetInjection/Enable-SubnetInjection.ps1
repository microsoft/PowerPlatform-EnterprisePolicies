<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Enables Subnet Injection for a Power Platform environment by linking it to an Enterprise Policy.

.DESCRIPTION
This cmdlet links an existing Subnet Injection Enterprise Policy to a Power Platform environment,
enabling the environment to use the delegated virtual network subnets configured in the policy.

If the environment already has a different policy linked, use the -Swap switch to replace it.
Without -Swap, the cmdlet will throw an error to prevent accidental policy replacement.

The operation is asynchronous. By default, the cmdlet waits for the operation to complete.
Use -NoWait to return immediately after the operation is initiated.

.OUTPUTS
System.Boolean

Returns $true when the operation completes successfully, or when -NoWait is specified and the operation is initiated.

.EXAMPLE
Enable-SubnetInjection -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy"

Enables Subnet Injection for the environment by linking it to the specified policy.

.EXAMPLE
Enable-SubnetInjection -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/.../enterprisePolicies/myPolicy" -TenantId "87654321-4321-4321-4321-210987654321" -Endpoint usgovhigh

Enables Subnet Injection for an environment in the US Government High cloud.

.EXAMPLE
Enable-SubnetInjection -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/.../enterprisePolicies/newPolicy" -Swap

Replaces the existing Subnet Injection policy with a new one.

.EXAMPLE
Enable-SubnetInjection -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/.../enterprisePolicies/myPolicy" -NoWait

Initiates the link operation without waiting for completion.
#>

function Enable-SubnetInjection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage="The Power Platform environment ID")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory, HelpMessage="The full Azure ARM resource ID of the Subnet Injection Enterprise Policy")]
        [ValidateAzureResourceId("Microsoft.PowerPlatform/enterprisePolicies")]
        [string]$PolicyArmId,

        [Parameter(Mandatory=$false, HelpMessage="The Azure AD tenant ID")]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="The BAP endpoint to connect to")]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication instead of reusing existing session")]
        [switch]$ForceAuth,

        [Parameter(Mandatory=$false, HelpMessage="Replace an existing linked policy with the new one")]
        [switch]$Swap,

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
    $environment = Get-BAPEnvironment -EnvironmentId $EnvironmentId -Endpoint $Endpoint -TenantId $TenantId

    if ($null -eq $environment) {
        throw "Failed to retrieve environment with ID: $EnvironmentId. If the environement exists, ensure you have the necessary permissions to access it and that you are connecting to the correct BAP endpoint."
    }

    Write-Verbose "Environment retrieved successfully"

    # Check if environment already has a linked Subnet Injection policy
    $hasExistingPolicy = $null -ne $environment.properties.enterprisePolicies -and $null -ne $environment.properties.enterprisePolicies.VNets

    if ($hasExistingPolicy) {
        $existingPolicyId = $environment.properties.enterprisePolicies.VNets.id
        if ($existingPolicyId -ieq $PolicyArmId) {
            Write-Host "Subnet Injection is already enabled with this policy." -ForegroundColor Yellow
            return
        }
        # Different policy is linked
        if (-not $Swap) {
            throw "Environment already has Subnet Injection enabled with a different policy: $existingPolicyId. Use the -Swap parameter to replace it."
        }
        Write-Host "Swapping existing policy with the new one..." -ForegroundColor Yellow
    }
    elseif ($Swap) {
        throw "Cannot use -Swap when no Subnet Injection policy is currently linked to the environment. Remove the -Swap parameter to enable Subnet Injection."
    }

    # Extract subscription ID from policy ARM ID and set context (format validated by attribute)
    $null = $PolicyArmId -match "/subscriptions/([^/]+)/"
    $subscriptionId = $Matches[1]
    Write-Verbose "Setting subscription context to $subscriptionId"
    $null = Set-AzContext -Subscription $subscriptionId

    # Get the enterprise policy and extract SystemId
    Write-Verbose "Retrieving enterprise policy: $PolicyArmId"
    $policy = Get-EnterprisePolicy -PolicyArmId $PolicyArmId

    if ($null -eq $policy) {
        throw "Failed to retrieve enterprise policy with ARM ID: $PolicyArmId. Ensure the policy exists, you have access to it, and its of type 'NetworkInjection'."
    }

    if ($policy.Kind -ne "NetworkInjection") {
        throw "The specified policy is not a Subnet Injection (NetworkInjection) policy. Policy kind: $($policy.Kind)"
    }

    $policySystemId = $policy.Properties.systemId
    if ([string]::IsNullOrWhiteSpace($policySystemId)) {
        throw "Enterprise policy does not have a systemId. The policy may not be fully provisioned."
    }

    Write-Verbose "Enterprise policy SystemId: $policySystemId"

    # Validate that the environment location matches the policy location
    $environmentLocation = $environment.location
    $policyLocation = $policy.Location

    if ($environmentLocation -ine $policyLocation) {
        if($environmentLocation -eq "unitedstates" -and $policyLocation -eq "unitedstateseuap") {
            Write-Verbose "Environment is in 'unitedstates' and policy is in 'unitedstateseuap'. Treating locations as compatible."
        }
        else {
            throw "Environment location '$environmentLocation' does not match the enterprise policy location '$policyLocation'. The environment and policy must be in the same location."
        }
    }

    Write-Verbose "Environment location '$environmentLocation' matches policy location '$policyLocation'"

    # Link the policy to the environment
    Write-Verbose "Enabling Subnet Injection for environment..."
    $linkResult = Set-EnvironmentEnterprisePolicy -EnvironmentId $EnvironmentId -PolicyType ([PolicyType]::NetworkInjection) -PolicySystemId $policySystemId -Operation ([LinkOperation]::link) -Endpoint $Endpoint -TenantId $TenantId

    if ($linkResult.StatusCode -ne 202) {
        $contentString = Get-AsyncResult -Task $linkResult.Content.ReadAsStringAsync()
        throw "Failed to initiate link operation. Status code: $($linkResult.StatusCode). $contentString"
    }

    Write-Verbose "Link operation initiated successfully"

    if ($NoWait) {
        Write-Host "Operation initiated. Use the Power Platform admin center to check the operation status." -ForegroundColor Green
        return $true
    }

    # Get operation-location header and poll for completion
    if (-not $linkResult.Headers.Contains("operation-location")) {
        throw "Link response did not contain operation-location header"
    }

    $operationUrl = $linkResult.Headers.GetValues("operation-location") | Select-Object -First 1
    Write-Verbose "Polling operation: $operationUrl"

    $operationResult = Wait-EnterprisePolicyOperation -OperationUrl $operationUrl -Endpoint $Endpoint -TenantId $TenantId -TimeoutSeconds $TimeoutSeconds

    Write-Host "Subnet Injection enabled successfully for environment $EnvironmentId" -ForegroundColor Green

    return $operationResult -eq "Succeeded"
}
