---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 01/29/2026
PlatyPS schema version: 2024-05-01
title: New-AuthorizationApplication
---

# New-AuthorizationApplication

## SYNOPSIS

Creates a new Azure AD application registration and service principal for Power Platform Authorization.

## SYNTAX

### __AllParameterSets

```
New-AuthorizationApplication [-DisplayName] <string> [-TenantId] <string>
 [[-Endpoint] <BAPEndpoint>] [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This cmdlet creates a public client application (app registration) and its associated service principal
in Azure AD with the required API permissions for Power Platform Authorization operations.
The application
is configured as a single-tenant app with delegated permissions for Authorization.RoleAssignments.Read
and Authorization.RoleAssignments.Write.

Admin consent is NOT granted automatically.
A tenant administrator must grant consent before
the application can be used.

## EXAMPLES

### EXAMPLE 1

New-AuthorizationApplication -DisplayName "MyAuthorizationApp" -TenantId "12345678-1234-1234-1234-123456789012"

Creates a new app registration and service principal named "MyAuthorizationApp".

### EXAMPLE 2

New-AuthorizationApplication -DisplayName "MyAuthorizationApp" -TenantId "12345678-1234-1234-1234-123456789012" -Endpoint usgovhigh

Creates a new app registration and service principal for the US Government High cloud.

## PARAMETERS

### -DisplayName

The display name for the application registration

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

The BAP endpoint to connect to

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

### System.String

Returns the Application (client) ID of the created application.

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

