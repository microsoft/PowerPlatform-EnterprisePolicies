---
document type: enum
external help file: EnterprisePolicies-Help.xml
HelpUri: ''
Locale: en-US
Module Name: EnterprisePolicies
ms.date: 08/07/2025
PlatyPS schema version: 2024-05-01
title: BAPEndpoint
---

# BAPEndpoint

## Description
Represents the different BAP endpoints that can be used to connect to Power Platform services. Only endpoints that are currently supported are included.

## Syntax
| Enum Value Name | Description |
|-----------------|-------------|
| unknown | No option selected. |
| tip1 | Microsoft internal use only. |
| tip2 | Microsoft internal use only. |
| prod | Public cloud endpoint, functions default to this value usually. |
| usgovhigh | Government Community Cloud High endpoint. |
| dod | Department of Defense endpoint. |
| china | China cloud endpoint. |

## Examples
### Example 1
```powershell
$endpoint = [BAPEndpoint]::Prod
```