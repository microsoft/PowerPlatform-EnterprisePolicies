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

Gets Power Platform RBAC role assignments at a specified scope.

## SYNTAX

### TenantScope (Default)

```
Get-RBACRoleAssignment -TenantId <string> [-ClientId <string>] [-ExcludeParentScopes]
 [-NoExpandSecurityGroups] [-NoExpandEnvironmentGroups] [-ExcludeNestedScopes]
 [-PrincipalType <AuthorizationPrincipalType>] [-PrincipalObjectId <string>] [-Permission <string>]
 [-Endpoint <BAPEndpoint>] [-ForceAuth] [<CommonParameters>]
```

### EnvironmentScope

```
Get-RBACRoleAssignment -TenantId <string> -EnvironmentId <string> [-ClientId <string>]
 [-ExcludeParentScopes] [-NoExpandSecurityGroups] [-NoExpandEnvironmentGroups]
 [-ExcludeNestedScopes] [-PrincipalType <AuthorizationPrincipalType>] [-PrincipalObjectId <string>]
 [-Permission <string>] [-Endpoint <BAPEndpoint>] [-ForceAuth] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This cmdlet retrieves role assignments for Power Platform RBAC operations.
The scope can be
at the tenant or environment level.

If -ClientId is not specified, the cmdlet uses the cached ClientId from a previous call to
New-AuthorizationApplication or any Power Platform RBAC cmdlet that was given -ClientId explicitly.
When -ClientId is provided, it is stored in the cache for future use.

By default, results include parent scopes, nested scopes, expanded security groups, and
expanded environment groups.
Use the corresponding switches to disable these behaviors.

## EXAMPLES

### EXAMPLE 1

Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001"

Gets all role assignments at the tenant scope with all expansions enabled.

### EXAMPLE 2

Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -EnvironmentId "00000000-0000-0000-0000-000000000002"

Gets all role assignments at the environment scope with all expansions enabled.

### EXAMPLE 3

Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -EnvironmentId "00000000-0000-0000-0000-000000000002" -ExcludeParentScopes -NoExpandSecurityGroups

Gets role assignments at the environment scope, excluding parent scopes and without expanding security group memberships.

### EXAMPLE 4

Get-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000001" -ExcludeNestedScopes -NoExpandEnvironmentGroups

Gets role assignments at the tenant scope, excluding nested scopes and without expanding environment group memberships.

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

### -ExcludeNestedScopes

Exclude role assignments from nested scopes

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

### -ExcludeParentScopes

Exclude role assignments from parent scopes

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

### -NoExpandEnvironmentGroups

Do not expand environment group memberships in the results

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

### -NoExpandSecurityGroups

Do not expand security group memberships in the results

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

