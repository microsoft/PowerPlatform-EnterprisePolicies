---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 02/13/2026
PlatyPS schema version: 2024-05-01
title: New-RBACRoleAssignment
---

# New-RBACRoleAssignment

## SYNOPSIS

Creates a Power Platform RBAC role assignment.

## SYNTAX

### TenantScope (Default)

```
New-RBACRoleAssignment -PrincipalObjectId <string> -PrincipalType <AuthorizationPrincipalType>
 -Role <string> -TenantId <string> [-ClientId <string>] [-Endpoint <BAPEndpoint>] [-ForceAuth]
 [-RefreshRoles] [<CommonParameters>]
```

### EnvironmentScope

```
New-RBACRoleAssignment -PrincipalObjectId <string> -PrincipalType <AuthorizationPrincipalType>
 -Role <string> -TenantId <string> -EnvironmentId <string> [-ClientId <string>]
 [-Endpoint <BAPEndpoint>] [-ForceAuth] [-RefreshRoles] [<CommonParameters>]
```

### EnvironmentGroupScope

```
New-RBACRoleAssignment -PrincipalObjectId <string> -PrincipalType <AuthorizationPrincipalType>
 -Role <string> -TenantId <string> -EnvironmentGroupId <string> [-ClientId <string>]
 [-Endpoint <BAPEndpoint>] [-ForceAuth] [-RefreshRoles] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This cmdlet creates a role assignment for a principal (user, group, or application) to grant
permissions via Power Platform RBAC.
The role can be scoped at the tenant,
environment, or environment group level.

If -ClientId is not specified, the cmdlet uses the cached ClientId from a previous call to
New-AuthorizationApplication or any Power Platform RBAC cmdlet that was given -ClientId explicitly.
When -ClientId is provided, it is stored in the cache for future use.

The Role parameter accepts the role definition name as returned by the Power Platform
Authorization API (e.g., "Power Platform Reader").
Use -RefreshRoles to update the
cached list of available roles.

## EXAMPLES

### EXAMPLE 1

New-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -PrincipalObjectId "00000000-0000-0000-0000-000000000001" -PrincipalType User -Role "Power Platform Reader" -TenantId "00000000-0000-0000-0000-000000000002"

Creates a tenant-scoped role assignment for a user with the "Power Platform Reader" role.

### EXAMPLE 2

New-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -PrincipalObjectId "00000000-0000-0000-0000-000000000001" -PrincipalType Group -Role "Power Platform Reader" -TenantId "00000000-0000-0000-0000-000000000002" -EnvironmentId "00000000-0000-0000-0000-000000000003"

Creates an environment-scoped role assignment for a group.

### EXAMPLE 3

New-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -PrincipalObjectId "00000000-0000-0000-0000-000000000001" -PrincipalType ApplicationUser -Role "Power Platform Reader" -TenantId "00000000-0000-0000-0000-000000000002" -EnvironmentGroupId "00000000-0000-0000-0000-000000000004"

Creates an environment group-scoped role assignment for an application.

### EXAMPLE 4

New-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -PrincipalObjectId "00000000-0000-0000-0000-000000000001" -PrincipalType User -Role "Power Platform Reader" -TenantId "00000000-0000-0000-0000-000000000002" -RefreshRoles

Creates a role assignment while forcing a refresh of the cached role definitions.

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

### -EnvironmentGroupId

The environment group ID for environment group-scoped assignments

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: EnvironmentGroupScope
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -EnvironmentId

The environment ID for environment-scoped assignments

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

The object ID of the principal to assign the role to

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

### -RefreshRoles

Force re-fetch of role definitions from the API

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

### -Role

The role definition name to assign (e.g., 'Power Platform Reader')

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
Returns the created role assignment object from the API.

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

