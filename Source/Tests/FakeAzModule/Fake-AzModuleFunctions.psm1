# If you want to test a parameter in a filter, make sure you define it in the function signature.

# Mock for Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource
# This is the type returned by Get-AzResource when the Az module is loaded
if (-not ('Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource' -as [type])) {
    Add-Type -TypeDefinition @"
namespace Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels
{
    public class PSResource
    {
        public string ResourceId { get; set; }
        public string Id { get; set; }
        public string Kind { get; set; }
        public string Location { get; set; }
        public string ResourceName { get; set; }
        public string Name { get; set; }
        public object Properties { get; set; }
        public string ResourceGroupName { get; set; }
        public string Type { get; set; }
        public string ResourceType { get; set; }
        public string SubscriptionId { get; set; }
    }
}
"@
}

function Connect-AzAccount {
    param(
        [string] $Tenant,
        [string] $Environment
    )
}
function Get-AzContext {}
function Set-AzContext {}
function Get-AzADAppCredential {}
function New-AzADAppCredential {}
function Get-AzADApplication {}
function New-AzADApplication {}
function New-AzADServicePrincipal {}
function Get-AzADServicePrincipal {}

# Az.Resources cmdlets
function Get-AzResourceGroup {}
function New-AzResourceGroup {}
function Get-AzResource {
    param(
        [string]$ResourceId,
        [string]$ResourceType,
        [string]$ResourceGroupName,
        [switch]$ExpandProperties
    )
}
function New-AzResourceGroupDeployment {}
function Get-AzResourceProvider {}
function Register-AzResourceProvider {}
function Get-AzProviderFeature {}
function Register-AzProviderFeature {}
function Remove-AzResource {
    param(
        [string]$ResourceId,
        [switch]$Force
    )
}

# Az.Network cmdlets
function Get-AzVirtualNetwork {}
function New-AzVirtualNetwork {}
function Set-AzVirtualNetwork {}
function Get-AzVirtualNetworkSubnetConfig {}
function New-AzVirtualNetworkSubnetConfig {}
function Add-AzVirtualNetworkSubnetConfig {}
function New-AzDelegation {}
function Add-AzDelegation {}
