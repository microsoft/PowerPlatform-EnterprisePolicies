<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

function New-SubnetInjectionEnterprisePolicy{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$EnterprisePolicyName,

        [Parameter(Mandatory)]
        [string]$EnterprisePolicyLocation,

        [Parameter(Mandatory)]
        [string]$VirtualNetworkId,

        [Parameter(Mandatory)]
        [string]$SubnetName,

        [Parameter()]
        [string]$VirtualNetworkId2,

        [Parameter()]
        [string]$SubnetName2,

        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [AzureEnvironment]$AzureEnvironment
    )

    $ErrorActionPreference = "Stop"
    
    if (-not(Connect-Azure -AzureEnvironment $AzureEnvironment -TenantId $TenantId)) {
        throw "Failed to connect to Azure. Please check your credentials and try again."
    }

    Write-Verbose "Setting subscription context to $SubscriptionId"
    $null = Set-AzContext -Subscription $SubscriptionId

    if(-not(Initialize-SubscriptionForPowerPlatform -SubscriptionId $SubscriptionId)) {
        throw "Failed to initialize subscription for Power Platform. Please ensure the subscription is registered for Microsoft.PowerPlatform, Microsoft.Network and the enterprisePoliciesPreview feature is enabled."
    }

    $vnets = @()
    $vnets += [VnetInformation]::new((Get-VirtualNetwork -VirtualNetworkId $VirtualNetworkId -EnterprisePolicylocation $EnterprisePolicyLocation), $SubnetName)

    if(Test-PowerPlatformRegionRequiresPair -PowerPlatformRegion $EnterprisePolicyLocation) {
        $vnets += [VnetInformation]::new((Get-VirtualNetwork -VirtualNetworkId $VirtualNetworkId2 -EnterprisePolicylocation $EnterprisePolicyLocation), $SubnetName2)
        Assert-RegionPairing -VnetInformation $vnets -PowerPlatformRegion $EnterprisePolicyLocation
    }

    $body = New-EnterprisePolicyBody -PolicyType ([PolicyType]::NetworkInjection) -PolicyLocation  $EnterprisePolicyLocation -PolicyName $EnterprisePolicyName -VnetInformation $vnets

    if(-not(Set-EnterprisePolicy -ResourceGroup $ResourceGroupName -Body $body)) {
        throw "Failed to create Subnet Injection Enterprise Policy."
    }

    Write-Verbose "Subnet Injection Enterprise Policy $EnterprisePolicyName created successfully."

    $policyArmId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.PowerPlatform/enterprisePolicies/$EnterprisePolicyName"
    $policy = Get-EnterprisePolicy $policyArmId
    $policyString = $policy | ConvertTo-Json -Depth 7
    return $policyString
}