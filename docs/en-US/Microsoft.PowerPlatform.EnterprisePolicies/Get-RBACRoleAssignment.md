---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 02/13/2026
PlatyPS schema version: 2024-05-01
title: Get-RBACRoleAssignment
---

# Get-RBACRoleAssignment

## SYNOPSIS

Gets RBAC role assignments at a specified scope.

## SYNTAX

### TenantScope (Default)

```
Get-RBACRoleAssignment -ClientId <string> -TenantId <string> [-IncludeParentScopes]
 [-ExpandSecurityGroups] [-ExpandEnvironmentGroups] [-IncludeNestedScopes]
 [-PrincipalType <AuthorizationPrincipalType>] [-PrincipalObjectId <string>] [-Permission <string>]
 [-Endpoint <BAPEndpoint>] [-ForceAuth] [<CommonParameters>]
```

### EnvironmentScope

```
Get-RBACRoleAssignment -ClientId <string> -TenantId <string> -EnvironmentId <string>
 [-IncludeParentScopes] [-ExpandSecurityGroups] [-ExpandEnvironmentGroups] [-IncludeNestedScopes]
 [-PrincipalType <AuthorizationPrincipalType>] [-PrincipalObjectId <string>] [-Permission <string>]
 [-Endpoint <BAPEndpoint>] [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This cmdlet retrieves role assignments for Power Platform RBAC operations.
The scope can be
at the tenant or environment level.

Options allow expanding security groups, environment groups, including parent scopes,
and including nested scopes in the results.

## EXAMPLES

### EXAMPLE 1

Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001"

Gets all role assignments at the tenant scope.

### EXAMPLE 2

Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -EnvironmentId "00000000-0000-0000-0000-000000000002"

Gets all role assignments at the environment scope.

### EXAMPLE 3

Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -EnvironmentId "00000000-0000-0000-0000-000000000002" -IncludeParentScopes -ExpandSecurityGroups

Gets role assignments at the environment scope, including parent scopes and expanding security group memberships.

### EXAMPLE 4

Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -IncludeNestedScopes -ExpandEnvironmentGroups

Gets role assignments at the tenant scope, including nested scopes and expanding environment group memberships.

### EXAMPLE 5

Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -PrincipalType User -PrincipalObjectId "00000000-0000-0000-0000-000000000005"

Gets role assignments for a specific user principal.

### EXAMPLE 6

Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -Permission "Read"

Gets role assignments filtered by a specific permission.

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

The environment ID for environment-scoped queries

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: EnvironmentScope
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ExpandEnvironmentGroups

Expand environment group memberships in the results

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

### -ExpandSecurityGroups

Expand security group memberships in the results

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

### -IncludeNestedScopes

Include role assignments from nested scopes

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

### -IncludeParentScopes

Include role assignments from parent scopes

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

### -Permission

Filter by permission name

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

### -PrincipalObjectId

Filter by principal object ID

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

### -PrincipalType

Filter by principal type

```yaml
Type: AuthorizationPrincipalType
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
Returns the role assignments from the API.

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

