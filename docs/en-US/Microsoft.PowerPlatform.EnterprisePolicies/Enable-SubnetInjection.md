---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 01/28/2026
PlatyPS schema version: 2024-05-01
title: Enable-SubnetInjection
---

# Enable-SubnetInjection

## SYNOPSIS

Enables Subnet Injection for a Power Platform environment by linking it to an Enterprise Policy.

## SYNTAX

### __AllParameterSets

```
Enable-SubnetInjection [-EnvironmentId] <string> [-PolicyArmId] <string> [[-TenantId] <string>]
 [[-Endpoint] <BAPEndpoint>] [[-TimeoutSeconds] <int>] [-ForceAuth] [-Swap] [-NoWait]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This cmdlet links an existing Subnet Injection Enterprise Policy to a Power Platform environment,
enabling the environment to use the delegated virtual network subnets configured in the policy.

If the environment already has a different policy linked, use the -Swap switch to replace it.
Without -Swap, the cmdlet will throw an error to prevent accidental policy replacement.

The operation is asynchronous.
By default, the cmdlet waits for the operation to complete.
Use -NoWait to return immediately after the operation is initiated.

## EXAMPLES

### EXAMPLE 1

Enable-SubnetInjection -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy"

Enables Subnet Injection for the environment by linking it to the specified policy.

### EXAMPLE 2

Enable-SubnetInjection -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/.../enterprisePolicies/myPolicy" -TenantId "87654321-4321-4321-4321-210987654321" -Endpoint usgovhigh

Enables Subnet Injection for an environment in the US Government High cloud.

### EXAMPLE 3

Enable-SubnetInjection -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/.../enterprisePolicies/newPolicy" -Swap

Replaces the existing Subnet Injection policy with a new one.

### EXAMPLE 4

Enable-SubnetInjection -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/.../enterprisePolicies/myPolicy" -NoWait

Initiates the link operation without waiting for completion.

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

The full Azure ARM resource ID of the Subnet Injection Enterprise Policy

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

The Azure AD tenant ID

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
  Position: 4
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

