---
document type: cmdlet
external help file: Microsoft.PowerPlatform.EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 08/02/2026
PlatyPS schema version: 2024-05-01
title: Set-PPServicePrincipalAuth
---

# Set-PPServicePrincipalAuth

## SYNOPSIS

Configures the service principal that the module uses to authenticate to Azure.

## SYNTAX

### ManagedIdentity (Default)

```
Set-PPServicePrincipalAuth -ClientId <string> -TenantId <string> [<CommonParameters>]
```

### CertificateSubjectName

```
Set-PPServicePrincipalAuth -ClientId <string> -TenantId <string> -CertificateSubjectName <string>
 [<CommonParameters>]
```

### CertificateThumbprint

```
Set-PPServicePrincipalAuth -ClientId <string> -TenantId <string> -CertificateThumbprint <string>
 [<CommonParameters>]
```

### Clear

```
Set-PPServicePrincipalAuth -Clear [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The Set-PPServicePrincipalAuth cmdlet stores a service principal authentication configuration in the
module's local cache.
Once configured, Connect-Azure uses the service principal instead of the default
interactive login (unless re-authentication is forced).

The parameters available depend on the authentication method, expressed by the ServicePrincipalAuthMethod
enum:

- ManagedIdentity: authenticates with a user-assigned managed identity identified by -ClientId.
- Certificate: authenticates with a certificate-based service principal identified by -ClientId and
  -TenantId, using either -CertificateThumbprint or -CertificateSubjectName to locate the certificate.

Use -Clear to remove any stored configuration so Connect-Azure reverts to the default interactive flow.

## EXAMPLES

### EXAMPLE 1

Set-PPServicePrincipalAuth -ClientId "11111111-1111-1111-1111-111111111111"

Configures Connect-Azure to authenticate using a user-assigned managed identity.

### EXAMPLE 2

Set-PPServicePrincipalAuth -ClientId "22222222-2222-2222-2222-222222222222" -TenantId "33333333-3333-3333-3333-333333333333" -CertificateThumbprint "A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4E5F6A1B2"

Configures Connect-Azure to authenticate using a certificate-based service principal located by thumbprint.

### EXAMPLE 3

Set-PPServicePrincipalAuth -ClientId "22222222-2222-2222-2222-222222222222" -TenantId "33333333-3333-3333-3333-333333333333" -CertificateSubjectName "CN=MyServicePrincipalCert"

Configures Connect-Azure to authenticate using a certificate-based service principal located by subject name.

### EXAMPLE 4

Set-PPServicePrincipalAuth -Clear

Removes the stored service principal configuration so Connect-Azure reverts to the default interactive flow.

## PARAMETERS

### -CertificateSubjectName

The subject name of the certificate to authenticate with.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: CertificateSubjectName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -CertificateThumbprint

The thumbprint of the certificate to authenticate with.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: CertificateThumbprint
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Clear

Removes any stored service principal authentication configuration.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Clear
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ClientId

The client ID of the user-assigned managed identity.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: CertificateSubjectName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: CertificateThumbprint
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: ManagedIdentity
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

The Azure AD tenant ID the service principal belongs to.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: CertificateSubjectName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: CertificateThumbprint
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: ManagedIdentity
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

### None.

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

