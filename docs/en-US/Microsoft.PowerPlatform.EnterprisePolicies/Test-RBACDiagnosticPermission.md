---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 02/13/2026
PlatyPS schema version: 2024-05-01
title: Test-RBACDiagnosticPermission
---

# Test-RBACDiagnosticPermission

## SYNOPSIS

Tests RBAC diagnostic permissions for a principal on an environment.

## SYNTAX

### ReadDiagnostic

```
Test-RBACDiagnosticPermission -TenantId <string> -EnvironmentId <string> -PrincipalObjectId <string>
 -PrincipalType <AuthorizationPrincipalType> -ReadDiagnostic [-ClientId <string>]
 [-Endpoint <BAPEndpoint>] [-ForceAuth] [<CommonParameters>]
```

### RunDiagnostic

```
Test-RBACDiagnosticPermission -TenantId <string> -EnvironmentId <string> -PrincipalObjectId <string>
 -PrincipalType <AuthorizationPrincipalType> -RunDiagnostic [-ClientId <string>]
 [-Endpoint <BAPEndpoint>] [-ForceAuth] [<CommonParameters>]
```

### RunMitigation

```
Test-RBACDiagnosticPermission -TenantId <string> -EnvironmentId <string> -PrincipalObjectId <string>
 -PrincipalType <AuthorizationPrincipalType> -RunMitigation [-ClientId <string>]
 [-Endpoint <BAPEndpoint>] [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This cmdlet tests whether a principal (user, group, or application) has a specific
Subnet Injection diagnostic permission on a Power Platform environment.

If -ClientId is not specified, the cmdlet uses the cached ClientId from a previous call to
New-AuthorizationApplication or any RBAC cmdlet that was given -ClientId explicitly.
When -ClientId is provided, it is stored in the cache for future use.

Use one of the switches to test a specific permission level:
- ReadDiagnostic: Can view diagnostic information
- RunDiagnostic: Can execute diagnostic actions
- RunMitigation: Can execute mitigation actions

Exactly one switch must be specified.

## EXAMPLES

### EXAMPLE 1

Test-RBACDiagnosticPermission -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -EnvironmentId "00000000-0000-0000-0000-000000000002" -PrincipalObjectId "00000000-0000-0000-0000-000000000003" -PrincipalType User -ReadDiagnostic

Tests the ReadDiagnostic permission for a user on the specified environment.

### EXAMPLE 2

Test-RBACDiagnosticPermission -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -EnvironmentId "00000000-0000-0000-0000-000000000002" -PrincipalObjectId "00000000-0000-0000-0000-000000000003" -PrincipalType ApplicationUser -RunDiagnostic

Tests the RunDiagnostic permission for an application user.

### EXAMPLE 3

Test-RBACDiagnosticPermission -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -EnvironmentId "00000000-0000-0000-0000-000000000002" -PrincipalObjectId "00000000-0000-0000-0000-000000000003" -PrincipalType Group -RunMitigation

Tests the RunMitigation permission for a group.

## PARAMETERS

### -ClientId

The application (client) ID of the app registration

```yaml
Type: System.String
DefaultValue: ''
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

### -Endpoint

The BAP endpoint to connect to

```yaml
Type: BAPEndpoint
DefaultValue: prod
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

### -EnvironmentId

The environment ID to check permissions on

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
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

### -PrincipalObjectId

The object ID of the principal to check permissions for

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PrincipalType

The type of principal

```yaml
Type: AuthorizationPrincipalType
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ReadDiagnostic

Test ReadDiagnostic permission (EnvironmentManagement.SubnetDiagnostics.Read)

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ReadDiagnostic
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -RunDiagnostic

Test RunDiagnostic permission (EnvironmentManagement.SubnetDiagnostics.Action)

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: RunDiagnostic
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -RunMitigation

Test RunMitigation permission (EnvironmentManagement.SubnetDiagnostics.Write)

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: RunMitigation
  Position: Named
  IsRequired: true
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
  Position: Named
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

### System.Management.Automation.PSCustomObject
Returns the permission check results from the API.

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

