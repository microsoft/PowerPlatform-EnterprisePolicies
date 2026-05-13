---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 05/12/2026
PlatyPS schema version: 2024-05-01
title: Test-AppInsightsConnectivity
---

# Test-AppInsightsConnectivity

## SYNOPSIS

Tests network connectivity to the Application Insights ingestion endpoint described by a connection string.

## SYNTAX

### __AllParameterSets

```
Test-AppInsightsConnectivity [-EnvironmentId] <string> [-ConnectionString] <string>
 [[-Message] <string>] [[-TenantId] <string>] [[-Endpoint] <PPEndpoint>] [[-Region] <string>]
 [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Test-AppInsightsConnectivity cmdlet validates that the Application Insights ingestion endpoint described by the supplied connection string is reachable from the delegated subnet of the specified environment.
Optionally, a test telemetry event can be sent along with the connectivity check by supplying a message.
The test is executed in the context of your delegated subnet in the region that you specify.
If the region isn't specified, it defaults to the region of the environment.

## EXAMPLES

### EXAMPLE 1

Test-AppInsightsConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -ConnectionString "InstrumentationKey=00000000-0000-0000-0000-000000000000;IngestionEndpoint=https://westus-0.in.applicationinsights.azure.com/"

Tests connectivity to the Application Insights ingestion endpoint from the environment's delegated subnet.

### EXAMPLE 2

Test-AppInsightsConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -ConnectionString "InstrumentationKey=...;IngestionEndpoint=https://westus-0.in.applicationinsights.azure.com/" -Message "Hello from Power Platform"

Tests connectivity and additionally sends a test telemetry event with the supplied message.

### EXAMPLE 3

Test-AppInsightsConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -ConnectionString "InstrumentationKey=...;IngestionEndpoint=https://usgovvirginia-0.in.applicationinsights.azure.us/" -Endpoint usgovhigh

Tests connectivity from an environment in the US Government High cloud.

### EXAMPLE 4

Test-AppInsightsConnectivity -EnvironmentId "00000000-0000-0000-0000-000000000000" -ConnectionString "..." -Region "westus"

Tests connectivity from the westus region instead of the environment's default region.

## PARAMETERS

### -ConnectionString

The Application Insights connection string whose ingestion endpoint should be tested.

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

The Id of the environment to test the Application Insights connectivity from.

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

Optional message body to send as a test telemetry event alongside the connectivity check.

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

### ApplicationInsightsInformation
A class representing the result of the Application Insights connectivity test. [ApplicationInsightsInformation](ApplicationInsightsInformation.md)

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

