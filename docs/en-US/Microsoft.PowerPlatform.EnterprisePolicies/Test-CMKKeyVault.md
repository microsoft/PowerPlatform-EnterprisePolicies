---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 11/12/2026
PlatyPS schema version: 2024-05-01
title: Test-CMKKeyVault
---

# Test-CMKKeyVault

## SYNOPSIS

Validates that an Azure Key Vault is correctly configured for use with a customer managed key (CMK) enterprise policy.

## SYNTAX

### __AllParameterSets

```
Test-CMKKeyVault [-SubscriptionId] <string> [-KeyVaultName] <string>
 [-EnterprisePolicyArmId] <string> [[-TenantId] <string>] [[-AzureEnvironment] <AzureEnvironment>]
 [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Test-CMKKeyVault cmdlet checks that a key vault, a CMK enterprise policy, and the encryption key satisfy the
prerequisites required by Power Platform customer managed key encryption.
It verifies:

- Key vault: soft delete and purge protection are enabled.
- Enterprise policy: it is of kind Encryption, has a system-assigned managed identity, and references the given key vault.
- Access: the enterprise policy's managed identity has Get/WrapKey/UnwrapKey key permissions (access-policy vaults) or the
  'Key Vault Crypto Service Encryption User' role (RBAC vaults).
- Key: the referenced key exists, is enabled, is activated (past its NotBefore date), and is not expired.

Details for any failed check are written as warnings.
Retrieval failures for the vault, policy, or key are thrown as errors.

## EXAMPLES

### EXAMPLE 1

Test-CMKKeyVault -SubscriptionId "12345678-1234-1234-1234-123456789012" -KeyVaultName "myVault" -EnterprisePolicyArmId "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.PowerPlatform/enterprisePolicies/myPolicy"

Validates that 'myVault' is correctly configured for the specified CMK enterprise policy.

### EXAMPLE 2

Test-CMKKeyVault -SubscriptionId "12345678-1234-1234-1234-123456789012" -KeyVaultName "myVault" -EnterprisePolicyArmId "/subscriptions/.../enterprisePolicies/myPolicy" -AzureEnvironment AzureUSGovernment

Validates the key vault configuration for a policy in the US Government cloud.

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

### -EnterprisePolicyArmId

The full Azure ARM resource ID of the CMK enterprise policy

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

### -KeyVaultName

The name of the key vault to validate

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

The Azure subscription ID that contains the key vault

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

Returns $true when every check passes; otherwise returns $false.

{{ Fill in the Description }}

### System.Boolean

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

