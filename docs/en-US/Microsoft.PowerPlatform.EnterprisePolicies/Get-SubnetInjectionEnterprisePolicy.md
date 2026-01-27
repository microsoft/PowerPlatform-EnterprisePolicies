---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 01/26/2026
PlatyPS schema version: 2024-05-01
title: Get-SubnetInjectionEnterprisePolicy
---

# Get-SubnetInjectionEnterprisePolicy

## SYNOPSIS

Retrieves Subnet Injection Enterprise Policies for Power Platform.

## SYNTAX

### BySubscription (Default)

```
Get-SubnetInjectionEnterprisePolicy -SubscriptionId <string> [-TenantId <string>]
 [-Endpoint <BAPEndpoint>] [-ForceAuth] [<CommonParameters>]
```

### ByResourceId

```
Get-SubnetInjectionEnterprisePolicy -PolicyResourceId <string> [-TenantId <string>]
 [-Endpoint <BAPEndpoint>] [-ForceAuth] [<CommonParameters>]
```

### ByEnvironment

```
Get-SubnetInjectionEnterprisePolicy -EnvironmentId <string> [-TenantId <string>]
 [-Endpoint <BAPEndpoint>] [-ForceAuth] [<CommonParameters>]
```

### ByResourceGroup

```
Get-SubnetInjectionEnterprisePolicy -SubscriptionId <string> -ResourceGroupName <string>
 [-TenantId <string>] [-Endpoint <BAPEndpoint>] [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This cmdlet retrieves Subnet Injection Enterprise Policies using one of four methods:
- By Resource ID: Retrieves a specific policy using its Azure ARM resource ID
- By Environment: Retrieves the policy linked to a specific Power Platform environment
- By Subscription: Retrieves all Subnet Injection policies in the current subscription
- By Resource Group: Retrieves all Subnet Injection policies in a specific resource group

## EXAMPLES

### EXAMPLE 1

Get-SubnetInjectionEnterprisePolicy -PolicyResourceId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy" -TenantId "87654321-4321-4321-4321-210987654321"

Retrieves a Subnet Injection Enterprise Policy by its ARM resource ID.

### EXAMPLE 2

Get-SubnetInjectionEnterprisePolicy -EnvironmentId "00000000-0000-0000-0000-000000000000" -Endpoint Prod

Retrieves the Subnet Injection Enterprise Policy linked to the specified Power Platform environment.

### EXAMPLE 3

Get-SubnetInjectionEnterprisePolicy -EnvironmentId "00000000-0000-0000-0000-000000000000" -TenantId "87654321-4321-4321-4321-210987654321" -Endpoint usgovhigh

Retrieves the Subnet Injection Enterprise Policy linked to an environment in the US Government High cloud.

### EXAMPLE 4

Get-SubnetInjectionEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012"

Retrieves all Subnet Injection Enterprise Policies in the specified subscription.

### EXAMPLE 5

Get-SubnetInjectionEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup"

Retrieves all Subnet Injection Enterprise Policies in the specified resource group.

## PARAMETERS

### -Endpoint

The BAP endpoint to connect to

```yaml
Type: BAPEndpoint
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.String

A JSON string representation of the enterprise policy resource(s)

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

