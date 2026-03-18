# Fix: VNet ID Trailing Slash Causes Subnet Injection Validation Failure

> **Summary:** A trailing slash in the `VirtualNetworkId` parameter (e.g., `/subscriptions/.../virtualNetworks/vnet/`) causes Azure API calls to fail with cryptic errors during subnet injection enterprise policy creation. This document describes the root cause, the fix applied to `Get-VirtualNetwork` in `VnetValidations.ps1`, and the affected cmdlets.

---

## Problem

When creating a subnet injection enterprise policy, if the user supplies a VNet resource ID with a trailing slash, the Azure Resource Manager API call fails with a non-descriptive error. The trailing slash makes the resource ID invalid from ARM's perspective, but no validation catches it before the API call.

**Example of invalid input:**
```
/subscriptions/sub-id/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/my-vnet/
```

## Root Cause

The `Get-VirtualNetwork` function in `VnetValidations.ps1` passes the VNet ID directly to `Get-AzResource` without validating its format. ARM rejects IDs ending with `/` but returns a generic error that does not indicate the trailing slash is the issue.

## Fix Applied

### Validation in `Get-VirtualNetwork` (VnetValidations.ps1)

Added an early check that rejects VNet IDs with a trailing slash before any Azure API calls:

```powershell
if ($VirtualNetworkId.EndsWith("/"))
{
    throw "The VirtualNetworkId parameter has a trailing slash. Please remove the trailing slash and try again. Provided value: $VirtualNetworkId"
}
```

### Test Coverage (VnetValidations.Tests.ps1)

Added a test to verify the validation:

```powershell
It 'Throws when VirtualNetworkId has trailing slash' {
    { Get-VirtualNetwork -VirtualNetworkId "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/" `
        -EnterprisePolicyLocation "unitedstates" } | Should -Throw "*trailing slash*"
}
```

## Scope of Impact

**Affected cmdlets:**
- `New-SubnetInjectionEnterprisePolicy` — uses `Get-VirtualNetwork` for both primary and secondary VNet validation

**Files analyzed:**

| File | Status |
|------|--------|
| `Private/VnetValidations.ps1` | ✅ Updated with trailing slash validation |
| `Public/SubnetInjection/New-SubnetInjectionEnterprisePolicy.ps1` | ✅ Protected (calls `Get-VirtualNetwork`) |
| `Source/SubnetInjection/ValidateVnetLocationForEnterprisePolicy.ps1` | ⚠️ Legacy — not updated |
| `Source/SubnetInjection/CreateSubnetInjectionEnterprisePolicy.ps1` | ⚠️ Legacy — not updated |
| `Source/SubnetInjection/UpdateSubnetInjectionEnterprisePolicy.ps1` | ⚠️ Legacy — not updated |

Legacy scripts under `Source/SubnetInjection/` are being replaced by the module and were not modified.

## Error Message

Users will now see a clear, actionable message:

> *The VirtualNetworkId parameter has a trailing slash. Please remove the trailing slash and try again. Provided value: \<value\>*

