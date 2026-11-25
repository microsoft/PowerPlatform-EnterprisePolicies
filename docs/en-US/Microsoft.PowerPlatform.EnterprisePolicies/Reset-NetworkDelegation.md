---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 11/25/2026
PlatyPS schema version: 2024-05-01
title: Reset-NetworkDelegation
---

# Reset-NetworkDelegation

## SYNOPSIS

Requests a delegation reset for a Power Platform environment.

## SYNTAX

### __AllParameterSets

```
Reset-NetworkDelegation [-EnvironmentId] <string> [[-Region] <string>] [[-TenantId] <string>]
 [[-Endpoint] <PPEndpoint>] [-ForceAuth] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

None.

## DESCRIPTION

Requests a delegation reset for the specified Power Platform environment.
This allows changes such as updated DNS settings to take effect without unlinking the enterprise policy.
The operation may take up to 100 seconds and causes minor downtime for environments sharing the same virtual network.
You are prompted to confirm before the reset begins; use -Force to skip this prompt.

## EXAMPLES

### EXAMPLE 1

Reset-NetworkDelegation -EnvironmentId "00000000-0000-0000-0000-000000000000" -Region "westus"

Requests a delegation reset for the specified environment in westus.

### EXAMPLE 2

Reset-NetworkDelegation -EnvironmentId "00000000-0000-0000-0000-000000000000"

Requests a delegation reset using the environment's automatically resolved region.

### EXAMPLE 3

Reset-NetworkDelegation -EnvironmentId "00000000-0000-0000-0000-000000000000" -Region "usgovvirginia" -Endpoint usgovhigh -WhatIf

Previews a delegation reset for an environment in the US Government High cloud without sending the request.

### EXAMPLE 4

Reset-NetworkDelegation -EnvironmentId "00000000-0000-0000-0000-000000000000" -Force

Resets network delegation without prompting for confirmation.

## PARAMETERS

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

The Power Platform environment ID.

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

### -Force

Reset network delegation without prompting for confirmation.

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

Force re-authentication instead of reusing an existing session.

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

The Azure region in which to reset delegation. Defaults to the region the environment is in.

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

### -TenantId

The Entra tenant ID.

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

### System.Boolean

Returns `$true` when the reset completes successfully.

## NOTES

If the reset fails due to concurrent usage, pause or lower calls to subnet delegation workloads before retrying.

## RELATED LINKS

[Disable-SubnetInjection](Disable-SubnetInjection.md)

[Get-EnvironmentUsage](Get-EnvironmentUsage.md)

