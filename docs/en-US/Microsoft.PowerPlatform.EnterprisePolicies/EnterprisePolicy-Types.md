---
document type: reference
Locale: en-US
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 01/26/2026
title: Enterprise Policy Types
---

# Enterprise Policy Types

This document describes the classes used to represent Enterprise Policy resources returned by cmdlets like `Get-SubnetInjectionEnterprisePolicy`.

## EnterprisePolicy

Represents an Azure ARM Enterprise Policy resource.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| ResourceId | string | The full ARM resource ID |
| Id | string | The resource ID (same as ResourceId) |
| Kind | string | The policy type: Encryption, NetworkInjection, or Identity |
| Location | string | The Azure region where the policy is deployed |
| ResourceName | string | The name of the resource |
| Name | string | The name of the policy |
| Properties | EnterprisePolicyProperties | The policy-specific properties |
| ResourceGroupName | string | The resource group containing the policy |
| Type | string | The ARM resource type (Microsoft.PowerPlatform/enterprisePolicies) |
| ResourceType | string | The ARM resource type |
| SubscriptionId | string | The Azure subscription ID |

## EnterprisePolicyProperties

Contains the policy-specific properties of an Enterprise Policy.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| SystemId | string | The internal system ID of the policy in the format `/regions/{region}/providers/Microsoft.PowerPlatform/enterprisePolicies/{guid}` |
| NetworkInjection | NetworkInjectionProperties | Network injection configuration (for NetworkInjection policies) |

## NetworkInjectionProperties

Contains the virtual network configuration for a Network Injection Enterprise Policy.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| VirtualNetworks | VirtualNetworkReference[] | Array of virtual networks configured for subnet injection |

## VirtualNetworkReference

Represents a reference to an Azure Virtual Network and its delegated subnet.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| Id | string | The full ARM resource ID of the virtual network |
| Subnet | SubnetReference | Reference to the delegated subnet |

## SubnetReference

Represents a reference to a subnet within a virtual network.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| Name | string | The name of the subnet |

## Example

The following shows an example of an EnterprisePolicy object returned by `Get-SubnetInjectionEnterprisePolicy`:

```json
{
  "ResourceId": "/subscriptions/12345678.../enterprisePolicies/myPolicy",
  "Kind": "NetworkInjection",
  "Location": "europe",
  "Name": "myPolicy",
  "Properties": {
    "systemId": "/regions/europe/providers/Microsoft.PowerPlatform/enterprisePolicies/guid",
    "networkInjection": {
      "virtualNetworks": [
        {
          "id": "/subscriptions/12345678.../virtualNetworks/myVnet",
          "subnet": {
            "name": "default"
          }
        }
      ]
    }
  },
  "ResourceGroupName": "myResourceGroup",
  "SubscriptionId": "12345678-1234-1234-1234-123456789012"
}
```
