---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 05/11/2026
PlatyPS schema version: 2024-05-01
title: Get-SubnetHistoricalUsage
---

# Get-SubnetHistoricalUsage

## SYNOPSIS

Retrieves the historical network usage of the subnet backing an enterprise policy, identified by ARM resource ID, linked environment, or system ID.

## SYNTAX

### BySystemId (Default)

```
Get-SubnetHistoricalUsage -SystemId <string> -TenantId <string> -Region <string>
 [-Endpoint <PPEndpoint>] [-AzureEnvironment <AzureEnvironment>] [-ForceAuth] [<CommonParameters>]
```

### ByEnterprisePolicyId

```
Get-SubnetHistoricalUsage -EnterprisePolicyId <string> -TenantId <string> -Region <string>
 [-Endpoint <PPEndpoint>] [-AzureEnvironment <AzureEnvironment>] [-ForceAuth] [<CommonParameters>]
```

### ByEnvironmentId

```
Get-SubnetHistoricalUsage -EnvironmentId <string> -TenantId <string> -Region <string>
 [-Endpoint <PPEndpoint>] [-AzureEnvironment <AzureEnvironment>] [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Retrieves the historical usage of the subnet backing a Subnet Injection enterprise policy.
This includes usage from all environments linked to the policy and the IPs reserved by Azure.

The policy can be identified in three ways:
- By its Azure ARM resource ID (-EnterprisePolicyId).
The policy is looked up via ARM and its systemId is resolved automatically.
- By a Power Platform environment ID (-EnvironmentId).
The cmdlet finds the policy linked to the environment and resolves its systemId.
- By the policy's system ID GUID directly (-SystemId).

## EXAMPLES

### EXAMPLE 1

Get-SubnetHistoricalUsage -SystemId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000" -Region "westus"

Retrieves the historical subnet usage using the policy's system ID directly.

### EXAMPLE 2

Get-SubnetHistoricalUsage -EnterprisePolicyId "/subscriptions/aaaabbbb-0000-cccc-1111-dddd2222eeee/resourceGroups/myRg/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy" -TenantId "00000000-0000-0000-0000-000000000000" -Region "westus"

Retrieves the historical subnet usage by looking up the policy from its ARM resource ID.

### EXAMPLE 3

Get-SubnetHistoricalUsage -EnvironmentId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000" -Region "westus"

Retrieves the historical subnet usage for the policy linked to the specified environment.

### EXAMPLE 4

Get-SubnetHistoricalUsage -SystemId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000" -Region "usgovvirginia" -Endpoint usgovhigh

Retrieves the historical subnet usage for a policy in the US Government High cloud.

## PARAMETERS

### -AzureEnvironment

The Azure environment to use.

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

### -EnterprisePolicyId

The Azure ARM resource ID of the enterprise policy.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByEnterprisePolicyId
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -EnvironmentId

The Power Platform environment ID whose linked policy should be used.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByEnvironmentId
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

Force re-authentication to Azure.

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

### -Region

The region that the tenant belongs to.

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

### -SystemId

The enterprise policy system ID (GUID).

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: BySystemId
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

The id of the tenant.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### SubnetUsageDocument
A class representing the network usage of the subnet. [SubnetUsageDocument](SubnetUsageDocument.md)

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

