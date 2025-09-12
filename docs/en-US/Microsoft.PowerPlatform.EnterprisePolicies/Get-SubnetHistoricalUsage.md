---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 09/08/2025
PlatyPS schema version: 2024-05-01
title: Get-SubnetHistoricalUsage
---

# Get-SubnetHistoricalUsage

## SYNOPSIS

Retrieves the historical network usage of the specified subnet based on enterprise policy id and region.

## SYNTAX

### __AllParameterSets

```
Get-SubnetHistoricalUsage [-EnterprisePolicyId] <string> [[-TenantId] <string>] [-Region] <string>
 [[-Endpoint] <BAPEndpoint>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Retrieves the historical usage of the specified subnet.
This includes usage from all environments with the specified enterprise policy id and the ips reserved by azure.

## EXAMPLES

### EXAMPLE 1

Get-SubnetHistoricalUsage -EnterprisePolicyId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000" -Region "westus" -Endpoint [BAPEndpoint]::Prod

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

### -EnterprisePolicyId

The Id of the enterprise policy to get usage for.

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

The region that the tenant belongs to.

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

### -TenantId

The id of the tenant.

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

### SubnetUsageDocument
A class representing the network usage of the subnet. [SubnetUsageDocument](SubnetUsageDocument.md)

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

