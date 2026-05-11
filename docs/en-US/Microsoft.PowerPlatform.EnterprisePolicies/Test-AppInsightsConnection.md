---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 05/07/2026
PlatyPS schema version: 2024-05-01
title: Test-AppInsightsConnection
---

# Test-AppInsightsConnection

## SYNOPSIS

Tests connectivity to Application Insights by sending a test telemetry event from a specified environment.

## SYNTAX

### __AllParameterSets

```
Test-AppInsightsConnection [-EnvironmentId] <string> [-ConnectionString] <string>
 [-Message] <string> [[-TenantId] <string>] [[-Endpoint] <PPEndpoint>] [[-Region] <string>]
 [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Test-AppInsightsConnection cmdlet validates an Application Insights connection string and sends a test telemetry event to the configured Application Insights resource.
The test is executed in the context of your delegated subnet in the region that you specify.
If the region isn't specified, it defaults to the region of the environment.

## EXAMPLES

### EXAMPLE 1

Test-AppInsightsConnection -EnvironmentId "00000000-0000-0000-0000-000000000000" -ConnectionString "InstrumentationKey=00000000-0000-0000-0000-000000000000;IngestionEndpoint=https://westus-0.in.applicationinsights.azure.com/" -Message "Hello from Power Platform"

Sends a test event with the supplied message to Application Insights from the environment's delegated subnet.

### EXAMPLE 2

Test-AppInsightsConnection -EnvironmentId "00000000-0000-0000-0000-000000000000" -ConnectionString "InstrumentationKey=...;IngestionEndpoint=https://usgovvirginia-0.in.applicationinsights.azure.us/" -Message "Test" -Endpoint usgovhigh

Sends a test event from an environment in the US Government High cloud.

### EXAMPLE 3

Test-AppInsightsConnection -EnvironmentId "00000000-0000-0000-0000-000000000000" -ConnectionString "..." -Message "Test" -Region "westus"

Sends a test event from the westus region instead of the environment's default region.

## PARAMETERS

### -ConnectionString

The Application Insights connection string to validate and use for the test event.

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

The Id of the environment to test the Application Insights connection from.

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

### -Message

The message body to send as the test telemetry event.

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

### -Region

The Azure region in which to test the connection. Defaults to the region the environment is in.

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

### ApplicationInsightsInformation
A class representing the result of the Application Insights connection test. [ApplicationInsightsInformation](ApplicationInsightsInformation.md)

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

