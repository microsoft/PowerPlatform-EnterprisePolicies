---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 02/17/2026
PlatyPS schema version: 2024-05-01
title: Remove-RBACRoleAssignment
---

# Remove-RBACRoleAssignment

## SYNOPSIS

Removes a Power Platform RBAC role assignment.

## SYNTAX

### TenantScope (Default)

```
Remove-RBACRoleAssignment -RoleAssignmentId <string> -TenantId <string> [-ClientId <string>]
 [-Endpoint <PPEndpoint>] [-ForceAuth] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### EnvironmentScope

```
Remove-RBACRoleAssignment -RoleAssignmentId <string> -TenantId <string> -EnvironmentId <string>
 [-ClientId <string>] [-Endpoint <PPEndpoint>] [-ForceAuth] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### EnvironmentGroupScope

```
Remove-RBACRoleAssignment -RoleAssignmentId <string> -TenantId <string> -EnvironmentGroupId <string>
 [-ClientId <string>] [-Endpoint <PPEndpoint>] [-ForceAuth] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This cmdlet removes a role assignment by its ID.
The scope can be at the tenant,
environment, or environment group level.

If -ClientId is not specified, the cmdlet uses the cached ClientId from a previous call to
New-AuthorizationApplication or any Power Platform RBAC cmdlet that was given -ClientId explicitly.
When -ClientId is provided, it is stored in the cache for future use.

Returns $true if the role assignment was deleted, $false if it was not found.

## EXAMPLES

### EXAMPLE 1

Remove-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -RoleAssignmentId "00000000-0000-0000-0000-000000000001" -TenantId "00000000-0000-0000-0000-000000000002"

Removes a tenant-scoped role assignment.

### EXAMPLE 2

Remove-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -RoleAssignmentId "00000000-0000-0000-0000-000000000001" -TenantId "00000000-0000-0000-0000-000000000002" -EnvironmentId "00000000-0000-0000-0000-000000000003"

Removes an environment-scoped role assignment.

### EXAMPLE 3

Remove-RBACRoleAssignment -ClientId "00000000-0000-0000-0000-000000000000" -RoleAssignmentId "00000000-0000-0000-0000-000000000001" -TenantId "00000000-0000-0000-0000-000000000002" -EnvironmentGroupId "00000000-0000-0000-0000-000000000004"

Removes an environment group-scoped role assignment.

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

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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

The Power Platform endpoint to connect to

```yaml
Type: PPEndpoint
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

The environment group ID for environment group-scoped role assignments

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

The environment ID for environment-scoped role assignments

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

### -Force

Remove the role assignment without prompting for confirmation

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

### -RoleAssignmentId

The ID of the role assignment to remove

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

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Boolean
Returns $true if the role assignment was deleted

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

