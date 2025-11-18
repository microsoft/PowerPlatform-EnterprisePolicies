---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 11/17/2025
PlatyPS schema version: 2024-05-01
title: Get-EnvironmentHistoricalUsage
---

# Get-EnvironmentHistoricalUsage

## SYNOPSIS

Retrieves the historical network usage of the specified environment.

## SYNTAX

### __AllParameterSets

```
Get-EnvironmentHistoricalUsage [-EnvironmentId] <string> [[-TenantId] <string>] [-Region] <string>
 [[-Endpoint] <BAPEndpoint>] [-ShowDetails] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Retrieves the historical usage of the specified environment.
Note, this is only the historical usage that this environment has.
It does not include usage from other environments and it does not include any ips that might be reserved by azure.

## EXAMPLES

### EXAMPLE 1

Get-EnvironmentHistoricalUsage -EnvironmentId "00000000-0000-0000-0000-000000000000" -Region "westus"

### EXAMPLE 2

Get-EnvironmentHistoricalUsage -EnvironmentId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000" -Region "westus" -Endpoint [BAPEndpoint]::Prod -ShowDetails

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

The Id of the environment to get usage for.

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

### -Region

The region that the environment belongs to.

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

### -ShowDetails

Switch to show detailed usage information.

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

### EnvironmentNetworkUsageDocument
A class representing the historical network usage of the environment. [EnvironmentNetworkUsageDocument](EnvironmentNetworkUsageDocument.md)

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

