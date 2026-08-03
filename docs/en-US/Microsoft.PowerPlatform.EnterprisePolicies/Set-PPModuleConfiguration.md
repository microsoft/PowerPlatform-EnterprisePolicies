---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 08/02/2026
PlatyPS schema version: 2024-05-01
title: Set-PPModuleConfiguration
---

# Set-PPModuleConfiguration

## SYNOPSIS

Stores a named configuration value in the module's local cache.

## SYNTAX

### __AllParameterSets

```
Set-PPModuleConfiguration [-Name] <string> [-Value] <Object> [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Set-PPModuleConfiguration cmdlet persists a named configuration value in the module's cached
configuration file so it is available across sessions.
The value can be any object and is stored under
the provided name.

The reserved 'ServicePrincipalAuth' name cannot be set through this cmdlet because it requires a
validated, strongly-typed configuration.
Use the dedicated Set-PPServicePrincipalAuth cmdlet to
configure service principal authentication.

Passing $null for the value removes the named configuration entry.
Use Get-PPModuleConfiguration to read
stored configuration values back.

## EXAMPLES

### EXAMPLE 1

Set-PPModuleConfiguration -Name "MySetting" -Value "SomeValue"

Stores the value "SomeValue" under the name "MySetting".

### EXAMPLE 2

Set-PPModuleConfiguration -Name "MySetting" -Value $null

Removes the "MySetting" configuration entry.

## PARAMETERS

### -Name

The name of the configuration entry to store.

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

### -Value

The value to store for the configuration entry. Pass $null to remove it.

```yaml
Type: System.Object
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### None.

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

