---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 11/12/2026
PlatyPS schema version: 2024-05-01
title: Enable-CMK
---

# Enable-CMK

## SYNOPSIS

Enables customer managed key (CMK) encryption for a Power Platform environment or PlatformAppsData.

## SYNTAX

### Environment (Default)

```
Enable-CMK -EnvironmentId <string> -PolicyArmId <string> [-TenantId <string>]
 [-Endpoint <PPEndpoint>] [-AzureEnvironment <AzureEnvironment>] [-ForceAuth] [-Swap] [-NoWait]
 [-TimeoutSeconds <int>] [<CommonParameters>]
```

### PlatformAppsData

```
Enable-CMK -PlatformAppsData -PolicyArmId <string> [-TenantId <string>] [-Endpoint <PPEndpoint>]
 [-AzureEnvironment <AzureEnvironment>] [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Enable-CMK cmdlet links an existing CMK enterprise policy to a Power Platform environment,
enabling the environment to encrypt its data with the key configured in the policy.

Before running this cmdlet, ensure the enterprise policy's managed identity has been granted access to the key vault
and that the environment meets the CMK prerequisites.

If the environment already has a different CMK policy linked, use the -Swap switch to replace it.
Without -Swap, the cmdlet returns an error to prevent accidental policy replacement.

Environment operations are asynchronous.
By default, the cmdlet waits for the operation to complete.
Use -NoWait to return immediately after an environment operation is initiated.

Use -PlatformAppsData instead of -EnvironmentId to link the policy through the separate PlatformApps API.
PlatformAppsData must already be enrolled.
This parameter set preserves the legacy scripts' behavior:
it defaults to the tip1 endpoint and returns after the service accepts the operation, without waiting for completion.
Specify -Endpoint explicitly to target another endpoint.
-Swap, -NoWait, and -TimeoutSeconds apply only to environments.

## EXAMPLES

### EXAMPLE 1

Enable-CMK -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/aaaabbbb-0000-cccc-1111-dddd2222eeee/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy"

Enables CMK encryption for the environment by linking it to the specified policy.

### EXAMPLE 2

Enable-CMK -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/.../enterprisePolicies/myPolicy" -Endpoint usgovhigh

Enables CMK encryption for an environment in the US Government High cloud.

### EXAMPLE 3

Enable-CMK -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/.../enterprisePolicies/newPolicy" -Swap

Replaces the existing CMK policy with a new one.

### EXAMPLE 4

Enable-CMK -EnvironmentId "00000000-0000-0000-0000-000000000000" -PolicyArmId "/subscriptions/.../enterprisePolicies/myPolicy" -NoWait

Initiates the link operation without waiting for completion.

### EXAMPLE 5

Enable-CMK -PlatformAppsData -PolicyArmId "/subscriptions/aaaabbbb-0000-cccc-1111-dddd2222eeee/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy" -Endpoint prod

Initiates CMK linking for enrolled PlatformAppsData at the explicitly selected endpoint, without waiting for completion.

## PARAMETERS

### -AzureEnvironment

The Azure environment to use. Defaults to the cloud associated with Endpoint.

```yaml
Type: AzureEnvironment
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

### -Endpoint

The Power Platform endpoint. Defaults to prod for environments and tip1 for PlatformAppsData.

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

The Power Platform environment ID

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Environment
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

### -NoWait

Return immediately without waiting for the operation to complete

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Environment
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PlatformAppsData

Link the policy to enrolled PlatformAppsData instead of an environment

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: PlatformAppsData
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PolicyArmId

The full Azure ARM resource ID of the CMK Enterprise Policy

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

### -Swap

Replace an existing linked policy with the new one

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Environment
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
  Position: Named
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
- Name: Environment
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

Returns $true when the environment operation completes successfully

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

