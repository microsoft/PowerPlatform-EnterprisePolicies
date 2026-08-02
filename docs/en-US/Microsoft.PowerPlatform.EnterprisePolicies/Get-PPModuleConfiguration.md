---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 08/02/2026
PlatyPS schema version: 2024-05-01
title: Get-PPModuleConfiguration
---

# Get-PPModuleConfiguration

## SYNOPSIS

Reads configuration values stored in the module's local cache.

## SYNTAX

### __AllParameterSets

```
Get-PPModuleConfiguration [[-Name] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Get-PPModuleConfiguration cmdlet returns configuration values persisted in the module's cached
configuration file.
When called without a name, it returns the entire configuration container.
When a
name is provided, it returns the value stored under that name, or $null when the name is not set.

## EXAMPLES

### EXAMPLE 1

Get-PPModuleConfiguration

Returns every stored module configuration value.

### EXAMPLE 2

Get-PPModuleConfiguration -Name "ServicePrincipalAuth"

Returns the stored service principal authentication configuration, or $null when it has not been set.

## PARAMETERS

### -Name

The name of the configuration entry to return. Omit to return all configuration.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
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

### System.Object

Returns the configuration container when no name is provided

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

