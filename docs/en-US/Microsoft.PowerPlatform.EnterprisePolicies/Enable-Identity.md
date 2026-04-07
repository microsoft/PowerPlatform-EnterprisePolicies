---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 04/07/2026
PlatyPS schema version: 2024-05-01
title: Enable-Identity
---

# Enable-Identity

## SYNOPSIS

Enables identity for a Power Platform environment by linking it to an enterprise policy.

## SYNTAX

### __AllParameterSets

```
Enable-Identity [-EnvironmentId] <string> [-PolicyArmId] <string> [[-TenantId] <string>]
 [[-Endpoint] <PPEndpoint>] [[-AzureEnvironment] <AzureEnvironment>] [[-TimeoutSeconds] <int>]
 [-ForceAuth] [-Swap] [-NoWait] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Enable-Identity cmdlet links an existing identity enterprise policy to a Power Platform environment,
enabling the environment to use the system-assigned managed identity configured in the policy.

If the environment already has a different identity policy linked, use the -Swap switch to replace it.
Without -Swap, the cmdlet returns an error to prevent accidental policy replacement.

The operation is asynchronous.
By default, the cmdlet waits for the operation to complete.
Use -NoWait to return immediately after the operation is initiated.

## EXAMPLES

### EXAMPLE 1

Enable-Identity -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/aaaabbbb-0000-cccc-1111-dddd2222eeee/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy"

Enables identity for the environment by linking it to the specified policy.

### EXAMPLE 2

Enable-Identity -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/.../enterprisePolicies/myPolicy" -Endpoint usgovhigh

Enables identity for an environment in the US Government High cloud.

### EXAMPLE 3

Enable-Identity -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/.../enterprisePolicies/newPolicy" -Swap

Replaces the existing identity policy with a new one.

### EXAMPLE 4

Enable-Identity -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/.../enterprisePolicies/myPolicy" -NoWait

Initiates the link operation without waiting for completion.

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
  Position: 4
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
  Position: 3
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

### -PolicyArmId

The full Azure ARM resource ID of the Identity Enterprise Policy

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Swap

Replace an existing linked policy with the new one

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

The Entra tenant ID

```yaml
Type: System.String
DefaultValue: ''
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

### -TimeoutSeconds

Maximum time in seconds to wait for the operation to complete

```yaml
Type: System.Int32
DefaultValue: 600
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 5
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

