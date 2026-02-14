---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 02/13/2026
PlatyPS schema version: 2024-05-01
title: Test-AuthorizationApplication
---

# Test-AuthorizationApplication

## SYNOPSIS

Tests that an Azure AD application is correctly configured for Power Platform Authorization.

## SYNTAX

### __AllParameterSets

```
Test-AuthorizationApplication [-ClientId] <string> [-TenantId] <string> [[-Endpoint] <BAPEndpoint>]
 [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This cmdlet validates that an Azure AD application registration exists and is properly configured
for Power Platform Authorization operations.
It checks:
- The application exists in Azure AD
- The application has the required API permissions configured (Authorization.RoleAssignments.Read and Write)
- The application is configured as a public client
- The application has http://localhost configured as a redirect URI

## EXAMPLES

### EXAMPLE 1

Test-AuthorizationApplication -ClientId "00000000-0000-0000-0000-000000000001" -TenantId "12345678-1234-1234-1234-123456789012"

Tests that the application is correctly configured for the prod endpoint.

### EXAMPLE 2

Test-AuthorizationApplication -ClientId "00000000-0000-0000-0000-000000000001" -TenantId "12345678-1234-1234-1234-123456789012" -Endpoint tip1

Tests that the application is correctly configured for the TIP1 endpoint.

## PARAMETERS

### -ClientId

The Application (client) ID of the Azure AD application

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

### -Endpoint

The BAP endpoint to validate against

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

### -ForceAuth

Force re-authentication instead of reusing existing session

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

The Azure AD tenant ID

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Boolean

Returns $true if the application is correctly configured

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

