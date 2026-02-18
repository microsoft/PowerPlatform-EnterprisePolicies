---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 02/17/2026
PlatyPS schema version: 2024-05-01
title: Disable-SubnetInjection
---

# Disable-SubnetInjection

## SYNOPSIS

Disables subnet injection for a Power Platform environment by unlinking it from its enterprise policy.

## SYNTAX

### __AllParameterSets

```
Disable-SubnetInjection [-EnvironmentId] <string> [[-TenantId] <string>] [[-Endpoint] <PPEndpoint>]
 [[-TimeoutSeconds] <int>] [-ForceAuth] [-NoWait] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Disable-SubnetInjection cmdlet unlinks the subnet injection enterprise policy from a Power Platform environment,
disabling the environment's use of delegated virtual network subnets.

The operation is asynchronous.
By default, the cmdlet waits for the operation to complete.
Use -NoWait to return immediately after the operation is initiated.

## EXAMPLES

### EXAMPLE 1

Disable-SubnetInjection -EnvironmentId "00000000-0000-0000-0000-000000000000"

Disables subnet injection for the environment by unlinking it from its currently linked policy.

### EXAMPLE 2

Disable-SubnetInjection -EnvironmentId "00000000-0000-0000-0000-000000000000" -Endpoint usgovhigh

Disables subnet injection for an environment in the US Government High cloud.

### EXAMPLE 3

Disable-SubnetInjection -EnvironmentId "00000000-0000-0000-0000-000000000000" -NoWait

Initiates the unlink operation without waiting for completion.

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
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -EnvironmentId

The Power Platform environment ID

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
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

### -NoWait

Return immediately without waiting for the operation to complete

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

### -TenantId

The Azure AD tenant ID

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -TimeoutSeconds

Maximum time in seconds to wait for the operation to complete

```yaml
Type: System.Int32
DefaultValue: 600
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
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

### System.Boolean

Returns $true when the operation completes successfully

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

