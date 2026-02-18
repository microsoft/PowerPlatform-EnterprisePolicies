---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 02/17/2026
PlatyPS schema version: 2024-05-01
title: Remove-SubnetInjectionEnterprisePolicy
---

# Remove-SubnetInjectionEnterprisePolicy

## SYNOPSIS

Removes a subnet injection enterprise policy for Power Platform.

## SYNTAX

### ByResourceId (Default)

```
Remove-SubnetInjectionEnterprisePolicy -PolicyResourceId <string> [-TenantId <string>]
 [-AzureEnvironment <AzureEnvironment>] [-ForceAuth] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### ByResourceGroup

```
Remove-SubnetInjectionEnterprisePolicy -SubscriptionId <string> -ResourceGroupName <string>
 [-TenantId <string>] [-AzureEnvironment <AzureEnvironment>] [-ForceAuth] [-Force] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### BySubscription

```
Remove-SubnetInjectionEnterprisePolicy -SubscriptionId <string> [-TenantId <string>]
 [-AzureEnvironment <AzureEnvironment>] [-ForceAuth] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Remove-SubnetInjectionEnterprisePolicy cmdlet removes a subnet injection enterprise policy using one of three methods:
- By Resource ID: Removes a specific policy using its Azure Resource Manager (ARM) resource ID.
- By Subscription: Lists all subnet injection policies in a subscription (use -PolicyResourceId to remove a specific policy).
- By Resource Group: Lists all subnet injection policies in a resource group (use -PolicyResourceId to remove a specific policy).

When using BySubscription or ByResourceGroup, if multiple policies are found, the cmdlet outputs the policy ARM IDs.
You can specify which policy to remove using -PolicyResourceId.

Note: A policy can't be deleted if it's associated with any Power Platform environments.
Unlink the policy from all environments before attempting to remove it.

## EXAMPLES

### EXAMPLE 1

Remove-SubnetInjectionEnterprisePolicy -PolicyResourceId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy"

Removes the specified subnet injection enterprise policy by its ARM resource ID.

### EXAMPLE 2

Remove-SubnetInjectionEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012"

Lists all subnet injection enterprise policies in the subscription.
When only one policy exists, it's removed.
If multiple policies exist, the ARM IDs are returned as output so you can specify which one to remove.

### EXAMPLE 3

Remove-SubnetInjectionEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup"

Lists all subnet injection enterprise policies in the resource group.
When only one policy exists, it's removed.
If multiple policies exist, their ARM IDs are returned as output so you can specify which one to remove.

### EXAMPLE 4

Remove-SubnetInjectionEnterprisePolicy -PolicyResourceId "/subscriptions/.../enterprisePolicies/myPolicy" -AzureEnvironment AzureUSGovernment

Removes the specified policy in the Azure US Government cloud.

### EXAMPLE 5

Remove-SubnetInjectionEnterprisePolicy -PolicyResourceId "/subscriptions/.../enterprisePolicies/myPolicy" -Force

Removes the specified policy without prompting for confirmation.

## PARAMETERS

### -AzureEnvironment

The Azure environment to connect to

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

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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

### -Force

Remove the policy without prompting for confirmation

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

### -PolicyResourceId

The full Azure ARM resource ID of the enterprise policy

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByResourceId
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

The Azure resource group name to search for policies

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByResourceGroup
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

The Azure subscription ID to search for policies

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByResourceGroup
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: BySubscription
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
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### None

Returns nothing on success. Throws an error if no policy is found or removal fails.
When multiple policies are found

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

