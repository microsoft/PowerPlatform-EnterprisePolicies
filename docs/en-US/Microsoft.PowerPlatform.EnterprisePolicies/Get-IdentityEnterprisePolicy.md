---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 04/07/2026
PlatyPS schema version: 2024-05-01
title: Get-IdentityEnterprisePolicy
---

# Get-IdentityEnterprisePolicy

## SYNOPSIS

Retrieves identity enterprise policies for Power Platform.

## SYNTAX

### BySubscription (Default)

```
Get-IdentityEnterprisePolicy -SubscriptionId <string> [-TenantId <string>] [-Endpoint <PPEndpoint>]
 [-ForceAuth] [<CommonParameters>]
```

### ByResourceId

```
Get-IdentityEnterprisePolicy -PolicyResourceId <string> [-TenantId <string>]
 [-Endpoint <PPEndpoint>] [-ForceAuth] [<CommonParameters>]
```

### ByEnvironment

```
Get-IdentityEnterprisePolicy -EnvironmentId <string> [-TenantId <string>] [-Endpoint <PPEndpoint>]
 [-ForceAuth] [<CommonParameters>]
```

### ByResourceGroup

```
Get-IdentityEnterprisePolicy -SubscriptionId <string> -ResourceGroupName <string>
 [-TenantId <string>] [-Endpoint <PPEndpoint>] [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Get-IdentityEnterprisePolicy cmdlet retrieves identity enterprise policies using one of four methods:
- By Resource ID: Retrieves a specific policy using its Azure Resource Manager (ARM) resource ID
- By Environment: Retrieves the policy linked to a specific Power Platform environment
- By Subscription: Retrieves all Identity policies in the current subscription
- By Resource Group: Retrieves all Identity policies in a specific resource group

## EXAMPLES

### EXAMPLE 1

Get-IdentityEnterprisePolicy -PolicyResourceId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy"

Retrieves an identity enterprise policy by its ARM resource ID.

### EXAMPLE 2

Get-IdentityEnterprisePolicy -EnvironmentId "00000000-0000-0000-0000-000000000000" -Endpoint Prod

Retrieves the identity enterprise policy linked to the specified Power Platform environment.

### EXAMPLE 3

Get-IdentityEnterprisePolicy -SubscriptionId "aaaabbbb-0000-cccc-1111-dddd2222eeee"

Retrieves all identity enterprise policies in the specified subscription.

### EXAMPLE 4

Get-IdentityEnterprisePolicy -SubscriptionId "aaaabbbb-0000-cccc-1111-dddd2222eeee" -ResourceGroupName "myResourceGroup"

Retrieves all identity enterprise policies in the specified resource group.

## PARAMETERS

### -Endpoint

The Power Platform endpoint to connect to. Defaults to 'prod'.

```yaml
Type: PPEndpoint
DefaultValue: prod
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

### -EnvironmentId

The Power Platform environment ID to retrieve the linked policy for

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByEnvironment
  Position: Named
  IsRequired: true
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

The Entra tenant ID

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource

Returns PSResource object(s) representing the enterprise policy Azure resources. Throws an error if no policy is found.

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

