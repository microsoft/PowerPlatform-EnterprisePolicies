---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 01/27/2026
PlatyPS schema version: 2024-05-01
title: Test-DnsResolution
---

# Test-DnsResolution

## SYNOPSIS

Tests the DNS resolution for a given hostname in a specified environment.

## SYNTAX

### __AllParameterSets

```
Test-DnsResolution [-EnvironmentId] <string> [-HostName] <string> [[-TenantId] <string>]
 [[-Endpoint] <PPEndpoint>] [[-Region] <string>] [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Tests the DNS resolution for a given hostname in a specified environment.
This function is executed in the context of your delegated subnet in the region that you have specified.
If the region is not specified, it defaults to the region of the environment.

## EXAMPLES

### EXAMPLE 1

Test-DnsResolution -EnvironmentId "00000000-0000-0000-0000-000000000000" -HostName "microsoft.com"

### EXAMPLE 2

Test-DnsResolution -EnvironmentId "00000000-0000-0000-0000-000000000000" -HostName "microsoft.com" -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint [PPEndpoint]::Prod

### EXAMPLE 3

Test-DnsResolution -EnvironmentId "00000000-0000-0000-0000-000000000000" -HostName "microsoft.com" -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint [PPEndpoint]::Prod -Region "westus"

## PARAMETERS

### -Endpoint

The PP endpoint to connect to. Default is 'prod'.

```yaml
Type: PPEndpoint
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

### -HostName

The hostname that DNS should attempt to resolve. IP addresses are not supported.

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

### -Region

The Azure region in which to test the resolution. Defaults to the region the environment is in.

```yaml
Type: System.String
DefaultValue: ''
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

### -TenantId

The id of the tenant that the environment belongs to.

```yaml
Type: System.String
DefaultValue: ''
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.String

A string representing the result of the DNS resolution. Whether it is successful or not

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

