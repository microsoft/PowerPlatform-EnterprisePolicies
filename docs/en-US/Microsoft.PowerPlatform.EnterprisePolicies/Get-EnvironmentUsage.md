---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 02/17/2026
PlatyPS schema version: 2024-05-01
title: Get-EnvironmentUsage
---

# Get-EnvironmentUsage

## SYNOPSIS

Retrieves the current usage of the specified environment.

## SYNTAX

### __AllParameterSets

```
Get-EnvironmentUsage [-EnvironmentId] <string> [[-TenantId] <string>] [[-Endpoint] <PPEndpoint>]
 [[-Region] <string>] [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Get-EnvironmentUsage cmdlet retrieves the current usage of the specified environment.
This is only the usage that this environment has.
It doesn't include usage from other environments and it doesn't include any IP addresses that might be reserved by Azure.

## EXAMPLES

### EXAMPLE 1

Get-EnvironmentUsage -EnvironmentId "00000000-0000-0000-0000-000000000000"

Retrieves the current network usage for the specified environment using default settings.

### EXAMPLE 2

Get-EnvironmentUsage -EnvironmentId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint usgovhigh

Retrieves the current network usage for an environment in the US Government High cloud, explicitly providing the tenant ID of the environment.

### EXAMPLE 3

Get-EnvironmentUsage -EnvironmentId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint [PPEndpoint]::Prod -Region "westus"

Retrieves the current network usage for the specified environment filtered to the westus region.

## PARAMETERS

### -Endpoint

The Power Platform endpoint to connect to. Defaults to 'prod'.

```yaml
Type: PPEndpoint
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

### -ForceAuth

Force re-authentication to Azure.

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

### -Region

The Azure region to filter the usage by. Defaults to the region the environment is in.

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

### NetworkUsage
A class representing the network usage of the environment. [NetworkUsage](NetworkUsage.md)

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

