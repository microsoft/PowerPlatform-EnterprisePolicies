---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 11/12/2026
PlatyPS schema version: 2024-05-01
title: Set-PPCustomEndpoint
---

# Set-PPCustomEndpoint

## SYNOPSIS

Configures the Power Platform URLs for an air-gapped cloud.

## SYNTAX

### __AllParameterSets

```
Set-PPCustomEndpoint [-Name] <string> [-Authority] <string> [-PPEndpoint] <string>
 [-PPResource] <string> [-PPAPI] <string> [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Set-PPCustomEndpoint cmdlet adds or replaces a named entry in the module's cached CustomEndpoints
configuration.
Other endpoint entries are preserved.
All URLs must be absolute HTTPS URLs without
credentials, query strings, or fragments.

Name identifies the Power Platform endpoint (ussec or usnat).
Authority is the login base URL without
a tenant ID; authorization service authentication appends the requested tenant ID.
PPEndpoint is the
BAP endpoint URL, PPResource is the Power Apps authentication resource URL, and PPAPI is the Power
Platform API base and authentication resource URL.

Updating an endpoint clears its cached authorization service clients so subsequent authentication
uses the new settings.
Register the matching Azure environment separately using Add-AzEnvironment.
Use Get-PPModuleConfiguration -Name CustomEndpoints to read the stored entries.

## EXAMPLES

### EXAMPLE 1

Set-PPCustomEndpoint -Name ussec -Authority "https://login.sec.example" -PPEndpoint "https://bap.sec.example" -PPResource "https://apps.sec.example" -PPAPI "https://api.sec.example"

Adds or replaces the ussec entry.
Replace the example URLs with the cloud's actual URLs.

## PARAMETERS

### -Authority

The HTTPS login base URL without a tenant ID.

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

### -Name

The name of the custom Power Platform endpoint.

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

### -PPAPI

The HTTPS Power Platform API base and authentication resource URL.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PPEndpoint

The HTTPS BAP endpoint URL.

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

### -PPResource

The HTTPS Power Apps authentication resource URL.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
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

