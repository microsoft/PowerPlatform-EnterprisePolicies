---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 11/12/2026
PlatyPS schema version: 2024-05-01
title: Disable-CMK
---

# Disable-CMK

## SYNOPSIS

Disables customer managed key (CMK) encryption for a Power Platform environment or PlatformAppsData.

## SYNTAX

### Environment (Default)

```
Disable-CMK -EnvironmentId <string> [-TenantId <string>] [-Endpoint <PPEndpoint>]
 [-AzureEnvironment <AzureEnvironment>] [-ForceAuth] [-NoWait] [-TimeoutSeconds <int>]
 [<CommonParameters>]
```

### PlatformAppsData

```
Disable-CMK -PlatformAppsData -PolicyArmId <string> [-TenantId <string>] [-Endpoint <PPEndpoint>]
 [-AzureEnvironment <AzureEnvironment>] [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Disable-CMK cmdlet unlinks the CMK enterprise policy from a Power Platform environment,
reverting the environment to Microsoft managed key encryption.

Environment operations are asynchronous.
By default, the cmdlet waits for the operation to complete.
Use -NoWait to return immediately after an environment operation is initiated.

Use -PlatformAppsData instead of -EnvironmentId to unlink the policy through the separate PlatformApps API.
PlatformAppsData must already be enrolled, and -PolicyArmId must match its currently linked CMK policy.
This parameter set preserves the legacy scripts' behavior: it defaults to the tip1 endpoint and returns
after the service accepts the operation, without waiting for completion.
Specify -Endpoint explicitly to
target another endpoint.
-NoWait and -TimeoutSeconds apply only to environments.

## EXAMPLES

### EXAMPLE 1

Disable-CMK -EnvironmentId "00000000-0000-0000-0000-000000000000"

Disables CMK encryption for the environment by unlinking it from its currently linked policy.

### EXAMPLE 2

Disable-CMK -EnvironmentId "00000000-0000-0000-0000-000000000000" -Endpoint usgovhigh

Disables CMK encryption for an environment in the US Government High cloud.

### EXAMPLE 3

Disable-CMK -EnvironmentId "00000000-0000-0000-0000-000000000000" -NoWait

Initiates the unlink operation without waiting for completion.

### EXAMPLE 4

Disable-CMK -PlatformAppsData -PolicyArmId "/subscriptions/aaaabbbb-0000-cccc-1111-dddd2222eeee/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy" -Endpoint prod

Initiates CMK unlinking for enrolled PlatformAppsData only if the specified policy is currently linked, without waiting for completion.

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

Unlink the policy from enrolled PlatformAppsData instead of an environment

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

The full Azure ARM resource ID of the CMK policy currently linked to PlatformAppsData

```yaml
Type: System.String
DefaultValue: ''
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

