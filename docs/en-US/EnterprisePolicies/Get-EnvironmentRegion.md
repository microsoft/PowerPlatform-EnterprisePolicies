---
document type: cmdlet
external help file: EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: EnterprisePolicies
ms.date: 08/07/2025
PlatyPS schema version: 2024-05-01
title: Get-EnvironmentRegion
---

# Get-EnvironmentRegion

## SYNOPSIS

Retrieves the region that the specified environment is deployed in.

## SYNTAX

### __AllParameterSets

```
Get-EnvironmentRegion [-EnvironmentId] <string> [[-TenantId] <string>] [[-Endpoint] <BAPEndpoint>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Retrieves the region that the specified environment is deployed in.
Note, the region is the Power Platform region, but it is aligned with an Azure region.

## EXAMPLES

### EXAMPLE 1

Get-EnvironmentRegion -EnvironmentId "env-12345"

### EXAMPLE 2

Get-EnvironmentRegion -EnvironmentId "env-12345" -TenantId "tenant-12345" -Endpoint [BAPEndpoint]::Prod

## PARAMETERS

### -Endpoint

The BAP endpoint to connect to. Default is 'prod'.

```yaml
Type: BAPEndpoint
DefaultValue: prod
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

### -EnvironmentId

The Id of the environment to get the region for.

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

The id of the tenant that the environment belongs to.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.String
A string representing the region of the environment.

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

