---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 04/23/2026
PlatyPS schema version: 2024-05-01
title: New-SubnetInjectionEnterprisePolicy
---

# New-SubnetInjectionEnterprisePolicy

## SYNOPSIS

Creates a new subnet injection enterprise policy for Power Platform.

## SYNTAX

### SingleVnet (Default)

```
New-SubnetInjectionEnterprisePolicy -SubscriptionId <string> -ResourceGroupName <string>
 -PolicyName <string> -PolicyLocation <string> -VirtualNetworkId <string> -SubnetName <string>
 -TenantId <string> [-AzureEnvironment <AzureEnvironment>] [-ForceAuth] [<CommonParameters>]
```

### PairedVnet

```
New-SubnetInjectionEnterprisePolicy -SubscriptionId <string> -ResourceGroupName <string>
 -PolicyName <string> -PolicyLocation <string> -VirtualNetworkId <string> -SubnetName <string>
 -VirtualNetworkId2 <string> -SubnetName2 <string> -TenantId <string>
 [-AzureEnvironment <AzureEnvironment>] [-ForceAuth] [<CommonParameters>]
```

### AcknowledgedSingleVnet

```
New-SubnetInjectionEnterprisePolicy -SubscriptionId <string> -ResourceGroupName <string>
 -PolicyName <string> -PolicyLocation <string> -VirtualNetworkId <string> -SubnetName <string>
 -IAcceptLimitationsOfSingleRegionVnet -TenantId <string> [-AzureEnvironment <AzureEnvironment>]
 [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The New-SubnetInjectionEnterprisePolicy cmdlet creates a subnet injection enterprise policy that enables Power Platform environments to use delegated subnets from Azure Virtual Networks.
The policy allows Power Platform services to inject into your virtual network for secure connectivity.

Some Power Platform regions support two virtual networks in paired Azure regions.
Use the VirtualNetworkId2 and SubnetName2 parameters when you deploy to these regions.

If you want to deploy to a paired-region geo with only a single virtual network, pass the
IAcceptLimitationsOfSingleRegionVnet switch to acknowledge the reduced regional redundancy.

## EXAMPLES

### EXAMPLE 1

New-SubnetInjectionEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myPolicy" -PolicyLocation "unitedstates" -VirtualNetworkId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVnet" -SubnetName "default" -AzureEnvironment AzureCloud

Creates a subnet injection enterprise policy in the United States region using a single virtual network.

### EXAMPLE 2

New-SubnetInjectionEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myPolicy" -PolicyLocation "unitedstates" -VirtualNetworkId "/subscriptions/.../virtualNetworks/vnet1" -SubnetName "subnet1" -VirtualNetworkId2 "/subscriptions/.../virtualNetworks/vnet2" -SubnetName2 "subnet2" -TenantId "87654321-4321-4321-4321-210987654321" -AzureEnvironment AzureCloud

Creates a subnet injection enterprise policy using two virtual networks in paired regions, which is recommended for Power Platform regions that support paired VNets.

### EXAMPLE 3

New-SubnetInjectionEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myPolicy" -PolicyLocation "unitedstates" -VirtualNetworkId "/subscriptions/.../virtualNetworks/vnet1" -SubnetName "subnet1" -TenantId "87654321-4321-4321-4321-210987654321" -IAcceptLimitationsOfSingleRegionVnet

Creates a subnet injection enterprise policy with a single virtual network in a region that supports paired VNets.
The IAcceptLimitationsOfSingleRegionVnet switch acknowledges that this configuration does not provide paired-region redundancy.

## PARAMETERS

### -AzureEnvironment

The Azure environment to use

```yaml
Type: AzureEnvironment
DefaultValue: AzureCloud
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ForceAuth

Force re-authentication instead of reusing existing session

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IAcceptLimitationsOfSingleRegionVnet

Acknowledge creating a policy with a single virtual network in a Power Platform region that supports paired virtual networks. This configuration does not provide paired-region redundancy.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AcknowledgedSingleVnet
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PolicyLocation

The Power Platform region for the enterprise policy (e.g., 'unitedstates', 'europe')

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PolicyName

The name for the enterprise policy

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ResourceGroupName

The name of the resource group where the enterprise policy will be created

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -SubnetName

The name of the subnet within the virtual network

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -SubnetName2

The name of the subnet within the second virtual network

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: PairedVnet
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -SubscriptionId

The Azure subscription ID where the enterprise policy will be created

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -TenantId

The Azure AD tenant ID

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -VirtualNetworkId

The full Azure resource ID of the virtual network

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -VirtualNetworkId2

The full Azure resource ID of the second virtual network in the paired Azure region

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: PairedVnet
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource

Returns the PSResource object representing the created enterprise policy Azure resource.

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

