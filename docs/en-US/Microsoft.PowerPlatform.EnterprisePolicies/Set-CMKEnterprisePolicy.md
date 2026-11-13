---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 11/12/2026
PlatyPS schema version: 2024-05-01
title: Set-CMKEnterprisePolicy
---

# Set-CMKEnterprisePolicy

## SYNOPSIS

Updates the key vault configuration of an existing customer managed key (CMK) enterprise policy.

## SYNTAX

### __AllParameterSets

```
Set-CMKEnterprisePolicy [-PolicyResourceId] <string> [[-KeyVaultId] <string>] [[-KeyName] <string>]
 [[-KeyVersion] <string>] [[-TenantId] <string>] [[-AzureEnvironment] <AzureEnvironment>]
 [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Set-CMKEnterprisePolicy cmdlet updates the key vault, key name, and/or key version referenced by an existing
CMK enterprise policy.
Only the values you provide are changed; any parameter you omit keeps its current value.

The policy's system-assigned managed identity and resource tags are preserved.
At least one of KeyVaultId, KeyName, or KeyVersion
must be provided.

## EXAMPLES

### EXAMPLE 1

Set-CMKEnterprisePolicy -PolicyResourceId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy" -KeyVersion "fedcba9876543210fedcba9876543210"

Updates only the key version referenced by the policy, leaving the key vault and key name unchanged.

### EXAMPLE 2

Set-CMKEnterprisePolicy -PolicyResourceId "/subscriptions/.../enterprisePolicies/myPolicy" -KeyVaultId "/subscriptions/.../providers/Microsoft.KeyVault/vaults/newVault" -KeyName "newKey" -KeyVersion "0123456789abcdef0123456789abcdef"

Points the policy at a different key vault, key, and key version.

### EXAMPLE 3

Set-CMKEnterprisePolicy -PolicyResourceId "/subscriptions/.../enterprisePolicies/myPolicy" -KeyName "rotatedKey" -AzureEnvironment AzureUSGovernment

Updates the key name for a policy in the US Government cloud.

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
  Position: 5
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

### -KeyName

The name of the key in the key vault. Omit to keep the current value.

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

### -KeyVaultId

The full Azure resource ID of the key vault. Omit to keep the current value.

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

### -KeyVersion

The version of the key in the key vault. Omit to keep the current value.

```yaml
Type: System.String
DefaultValue: ''
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

### -PolicyResourceId

The full Azure ARM resource ID of the CMK enterprise policy to update

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

### -TenantId

The Entra tenant ID

```yaml
Type: System.String
DefaultValue: ''
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

### Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource

Returns the PSResource object representing the updated enterprise policy Azure resource.

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

