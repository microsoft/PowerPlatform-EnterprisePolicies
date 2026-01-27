---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 01/26/2026
PlatyPS schema version: 2024-05-01
title: Test-TLSHandshake
---

# Test-TLSHandshake

## SYNOPSIS

Attempts to establish a TLS handshake with the provided destination and port.

## SYNTAX

### __AllParameterSets

```
Test-TLSHandshake [-EnvironmentId] <string> [-Destination] <string> [[-Port] <string>]
 [[-TenantId] <string>] [[-Endpoint] <BAPEndpoint>] [[-Region] <string>] [-ForceAuth]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Tests that a TLS handshake can be established against the provided destination and port.

This function is executed in the context of your delegated subnet in the region that you have specified.
If the region is not specified, it defaults to the region of the environment.

## EXAMPLES

### EXAMPLE 1

Test-TLSHandshake -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "microsoft.com"

### EXAMPLE 2

Test-TLSHandshake -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "unknowndb.database.windows.net" -Port 1433

### EXAMPLE 3

Test-TLSHandshake -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "unknowndb.database.windows.net" -Port 1433 -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint [BAPEndpoint]::Prod

### EXAMPLE 4

Test-TLSHandshake -EnvironmentId "00000000-0000-0000-0000-000000000000" -Destination "unknowndb.database.windows.net" -Port 1433 -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint [BAPEndpoint]::Prod -Region "westus"

## PARAMETERS

### -Destination

The destination that should be used to attempt the handshake for. This should only be a hostname.

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

The BAP endpoint to connect to. Default is 'prod'.

```yaml
Type: BAPEndpoint
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

The Id of the environment to test the handshake for.

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

The port that should be used to attempt the handshake for. Defaults to 443

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

The Azure region in which to test the handshake. Defaults to the region the environment is in.

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

### TLSConnectivityInformation
A class representing the result of the TLS handshake. [TLSConnectivityInformation](TLSConnectivityInformation.md)

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

