---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 02/17/2026
PlatyPS schema version: 2024-05-01
title: Test-AccountPermissions
---

# Test-AccountPermissions

## SYNOPSIS

Validates that the account has the correct permissions to run diagnostic commands.

## SYNTAX

### __AllParameterSets

```
Test-AccountPermissions [[-TenantId] <string>] [[-Endpoint] <PPEndpoint>] [-ForceAuth]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Test-AccountPermissions cmdlet tests that the generated bearer token for the signed in account has the claim that's necessary to call the diagnostic APIs.
The necessary permission is the Power Platform administrator role, which is assigned through the Microsoft Entra ID portal.

## EXAMPLES

### EXAMPLE 1

Test-AccountPermissions

Validates that the signed-in account has the Power Platform Administrator role using default settings.

### EXAMPLE 2

Test-AccountPermissions -TenantId "00000000-0000-0000-0000-000000000000" -Endpoint usgovhigh

Validates account permissions for an environment in the US Government High cloud, explicitly providing the tenant ID of the environment.

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
  Position: 1
  IsRequired: false
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

### -TenantId

The id of the tenant that the environment belongs to.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
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

### System.Boolean
Whether the account has the required permissions.

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

