---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 11/12/2026
PlatyPS schema version: 2024-05-01
title: New-CMKEnterprisePolicy
---

# New-CMKEnterprisePolicy

## SYNOPSIS

Creates a new customer managed key (CMK) enterprise policy for Power Platform.

## SYNTAX

### __AllParameterSets

```
New-CMKEnterprisePolicy [-SubscriptionId] <string> [-ResourceGroupName] <string>
 [-PolicyName] <string> [-PolicyLocation] <string> [-KeyVaultId] <string> [-KeyName] <string>
 [[-KeyVersion] <string>] [[-TenantId] <string>] [[-AzureEnvironment] <AzureEnvironment>]
 [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The New-CMKEnterprisePolicy cmdlet creates a customer managed key enterprise policy that enables Power Platform
environments to encrypt their data with a key stored in an Azure Key Vault.

The policy is created with a system-assigned managed identity.
After creation, you must grant that identity access
to the key vault (the 'Key Vault Crypto Service Encryption User' role, or Get/WrapKey/UnwrapKey key permissions when
the vault uses access policies) before linking the policy to an environment.

## EXAMPLES

### EXAMPLE 1

New-CMKEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myCmkPolicy" -PolicyLocation "unitedstates" -KeyVaultId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.KeyVault/vaults/myVault" -KeyName "myKey" -KeyVersion "0123456789abcdef0123456789abcdef"

Creates a CMK enterprise policy in the United States region that references a specific key version.

### EXAMPLE 2

New-CMKEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myCmkPolicy" -PolicyLocation "unitedstates" -KeyVaultId "/subscriptions/.../providers/Microsoft.KeyVault/vaults/myVault" -KeyName "myKey"

Creates a CMK enterprise policy that references the key without pinning a version, so the latest enabled key version is used.

### EXAMPLE 3

New-CMKEnterprisePolicy -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "myResourceGroup" -PolicyName "myCmkPolicy" -PolicyLocation "usgov" -KeyVaultId "/subscriptions/.../providers/Microsoft.KeyVault/vaults/myVault" -KeyName "myKey" -TenantId "87654321-4321-4321-4321-210987654321" -AzureEnvironment AzureUSGovernment

Creates a CMK enterprise policy in the US Government cloud.

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
  Position: 8
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

The name of the key in the key vault

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 5
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -KeyVaultId

The full Azure resource ID of the key vault that holds the encryption key

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -KeyVersion

The version of the key in the key vault. Omit to use the latest enabled key version.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 6
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PolicyLocation

The Power Platform region for the enterprise policy (e.g., 'unitedstates', 'europe')

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PolicyName

The name for the enterprise policy

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ResourceGroupName

The name of the resource group where the enterprise policy will be created

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

### -SubscriptionId

The Azure subscription ID where the enterprise policy will be created

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
  Position: 7
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

Returns the PSResource object representing the created enterprise policy Azure resource.

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

