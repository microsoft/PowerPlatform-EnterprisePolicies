---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 02/17/2026
PlatyPS schema version: 2024-05-01
title: Test-NetworkConnectivity
---

# Test-NetworkConnectivity

## SYNOPSIS

Tests the connectivity to a given service in a specified environment.

## SYNTAX

### __AllParameterSets

```
Test-NetworkConnectivity [-EnvironmentId] <string> [-Destination] <string> [[-Port] <string>]
 [[-TenantId] <string>] [[-Endpoint] <PPEndpoint>] [[-Region] <string>] [-ForceAuth]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Test-NetworkConnectivity cmdlet tests the connectivity to a given service in a specified environment.
The connectivity test attempts to establish a TCP connection to the specified destination on the specified port.
The cmdlet is executed in the context of your delegated subnet in the region that you specify.
If the region isn't specified, it defaults to the region of the environment.

## EXAMPLES

### EXAMPLE 1

Test-NetworkConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "microsoft.com"

Tests TCP connectivity to microsoft.com on the default port (443) from the environment's delegated subnet.

### EXAMPLE 2

Test-NetworkConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "unknowndb.database.windows.net" -Port 1433

Tests TCP connectivity to a SQL database on port 1433 from the environment's delegated subnet.

### EXAMPLE 3

Test-NetworkConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "unknowndb.database.windows.net" -Port 1433 -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint usgovhigh

Tests TCP connectivity to a SQL database for an environment in the US Government High cloud, explicitly providing the tenant ID of the environment.

### EXAMPLE 4

Test-NetworkConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "unknowndb.database.windows.net" -Port 1433 -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint [PPEndpoint]::Prod -Region "westus"

Tests TCP connectivity to a SQL database in the westus region instead of the environment's default region.

## PARAMETERS

### -Destination

The destination that should be used to attempt the connection. This can be a hostname or an IP address.

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

### -Endpoint

The Power Platform endpoint to connect to. Defaults to 'prod'.

```yaml
Type: PPEndpoint
DefaultValue: prod
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

### -EnvironmentId

The Id of the environment to test connectivity for.

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

### -Port

The port that should be used to attempt the connection. Defaults to 443

```yaml
Type: System.String
DefaultValue: 443
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

### -Region

The Azure region in which to test the connectivity. Defaults to the region the environment is in.

```yaml
Type: System.String
DefaultValue: ''
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

### -TenantId

The id of the tenant that the environment belongs to.

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

### System.String

A string representing the result of the connectivity test.

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

