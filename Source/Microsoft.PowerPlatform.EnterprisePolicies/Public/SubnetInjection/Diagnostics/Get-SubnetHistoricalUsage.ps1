<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

<#
.SYNOPSIS
Retrieves the historical network usage of the subnet backing an enterprise policy, identified by ARM resource ID, linked environment, or system ID.

.DESCRIPTION
Retrieves the historical usage of the subnet backing a Subnet Injection enterprise policy. This includes usage from all environments linked to the policy and the IPs reserved by Azure.

The policy can be identified in three ways:
- By its Azure ARM resource ID (-EnterprisePolicyId). The policy is looked up via ARM and its systemId is resolved automatically.
- By a Power Platform environment ID (-EnvironmentId). The cmdlet finds the policy linked to the environment and resolves its systemId.
- By the policy's system ID GUID directly (-SystemId).

.OUTPUTS
SubnetUsageDocument
A class representing the network usage of the subnet. [SubnetUsageDocument](SubnetUsageDocument.md)

.EXAMPLE
Get-SubnetHistoricalUsage -SystemId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000" -Region "westus"

Retrieves the historical subnet usage using the policy's system ID directly.

.EXAMPLE
Get-SubnetHistoricalUsage -EnterprisePolicyId "/subscriptions/aaaabbbb-0000-cccc-1111-dddd2222eeee/resourceGroups/myRg/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy" -TenantId "00000000-0000-0000-0000-000000000000" -Region "westus"

Retrieves the historical subnet usage by looking up the policy from its ARM resource ID.

.EXAMPLE
Get-SubnetHistoricalUsage -EnvironmentId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000" -Region "westus"

Retrieves the historical subnet usage for the policy linked to the specified environment.

.EXAMPLE
Get-SubnetHistoricalUsage -SystemId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000" -Region "usgovvirginia" -Endpoint usgovhigh

Retrieves the historical subnet usage for a policy in the US Government High cloud.
#>
function Get-SubnetHistoricalUsage {
    [CmdletBinding(DefaultParameterSetName = 'BySystemId')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByEnterprisePolicyId', HelpMessage="The Azure ARM resource ID of the enterprise policy.")]
        [ValidateAzureResourceId("Microsoft.PowerPlatform/enterprisePolicies")]
        [string]$EnterprisePolicyId,

        [Parameter(Mandatory, ParameterSetName = 'ByEnvironmentId', HelpMessage="The Power Platform environment ID whose linked policy should be used.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory, ParameterSetName = 'BySystemId', HelpMessage="The enterprise policy system ID (GUID).")]
        [ValidateNotNullOrEmpty()]
        [string]$SystemId,

        [Parameter(Mandatory, HelpMessage="The id of the tenant.")]
        [string]$TenantId,

        [Parameter(Mandatory, HelpMessage="The region that the tenant belongs to.")]
        [string]$Region,

        [Parameter(Mandatory=$false, HelpMessage="The Power Platform endpoint to connect to. Defaults to 'prod'.")]
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod,

        [Parameter(Mandatory=$false, HelpMessage="The Azure environment to use.")]
        [AzureEnvironment]$AzureEnvironment = [AzureEnvironment]::AzureCloud,

        [Parameter(Mandatory=$false, HelpMessage="Force re-authentication to Azure.")]
        [switch]$ForceAuth
    )

    $ErrorActionPreference = "Stop"

    if (-not(Connect-Azure -AzureEnvironment $AzureEnvironment -TenantId $TenantId -Force:$ForceAuth)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    $resolvedSystemId = switch ($PSCmdlet.ParameterSetName) {
        'BySystemId' {
            $SystemId
        }
        'ByEnterprisePolicyId' {
            $null = $EnterprisePolicyId -match "/subscriptions/([^/]+)/"
            $null = Set-AzContext -Subscription $Matches[1]
            $policy = Get-EnterprisePolicy -PolicyArmId $EnterprisePolicyId
            if ($null -eq $policy) {
                throw "Failed to retrieve enterprise policy with ARM ID: $EnterprisePolicyId."
            }
            if ([string]::IsNullOrWhiteSpace($policy.Properties.systemId)) {
                throw "Enterprise policy does not have a systemId. The policy may not be fully provisioned."
            }
            ($policy.Properties.systemId -split '/')[-1]
        }
        'ByEnvironmentId' {
            $environment = Get-PPEnvironment -EnvironmentId $EnvironmentId -Endpoint $Endpoint -TenantId $TenantId
            if ($null -eq $environment) {
                throw "Failed to retrieve environment with ID: $EnvironmentId."
            }
            if ($null -eq $environment.properties.enterprisePolicies -or $null -eq $environment.properties.enterprisePolicies.VNets) {
                throw "No Subnet Injection Enterprise Policy is linked to environment: $EnvironmentId."
            }
            $policyArmId = $environment.properties.enterprisePolicies.VNets.id
            $null = $policyArmId -match "/subscriptions/([^/]+)/"
            $null = Set-AzContext -Subscription $Matches[1]
            $policy = Get-EnterprisePolicy -PolicyArmId $policyArmId
            if ($null -eq $policy -or [string]::IsNullOrWhiteSpace($policy.Properties.systemId)) {
                throw "Could not retrieve enterprise policy details for: $policyArmId."
            }
            ($policy.Properties.systemId -split '/')[-1]
        }
    }

    $path = "/plex/networkUsage/subnetHistoricalUsage"
    $query = "api-version=2024-10-01&enterprisePolicyId=$resolvedSystemId&region=$Region"

    $request = New-HomeTenantRouteRequest -TenantId $TenantId -Path $path -Query $query -AccessToken (Get-PPAPIAccessToken -Endpoint $Endpoint -TenantId $TenantId) -HttpMethod ([System.Net.Http.HttpMethod]::Get) -Endpoint $Endpoint
    $result = Send-Request -Request $request
    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()

    if(-not $contentString) {
        throw "Failed to retrieve the subnet usage data from response."
    }

    try {
        $usage = ConvertFrom-JsonToClass -Json $contentString -ClassType ([SubnetUsageDocument])
    }
    catch {
        Write-Verbose "Failed to convert response to SubnetUsageDocument: $($_.Exception.Message)"
        return $contentString
    }

    if ($usage.SubnetSize -gt 0) {
        $peakUsage = 0
        foreach ($series in @($usage.NetworkUsageDataByWorkload, $usage.NetworkUsageDataByEnvironment)) {
            if ($series) {
                $seriesPeak = ($series | Measure-Object -Property TotalIpUsage -Maximum).Maximum
                if ($seriesPeak -gt $peakUsage) { $peakUsage = $seriesPeak }
            }
        }

        if ($peakUsage -gt 0) {
            $peakPercent = [math]::Round(($peakUsage / $usage.SubnetSize) * 100, 1)
            $context = "Peak subnet usage was $peakUsage/$($usage.SubnetSize) IPs ($peakPercent%)."
            if ($peakPercent -ge 100) {
                Write-Error "$context The subnet is full." -ErrorAction Continue
            }
            elseif ($peakPercent -ge 90) {
                Write-Error "$context The subnet is close to full." -ErrorAction Continue
            }
            elseif ($peakPercent -ge 75) {
                Write-Warning "$context Usage is high."
            }
        }
    }

    return $usage
}
