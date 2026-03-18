# Troubleshooting: Orphaned Enterprise Policy Causes Get-SubnetInjectionEnterprisePolicy Failure

> **Summary:** When an Azure ARM resource record for an enterprise policy exists but the corresponding Power Platform Resource Provider (PPRP) backend record has been deleted or is out of sync, running `Get-SubnetInjectionEnterprisePolicy -SubscriptionId` fails with an `ItemNotFound` error. This document covers root cause analysis, confirmed workarounds (`Remove-AzResource` works because PPRP returns 204 on DELETE for non-existent resources), and a recommended long-term code fix to make `Get-EnterprisePolicy` resilient to orphaned resources. Includes diagnostic Kusto queries for PPRP tracing.

---
## Problem

Running `Get-SubnetInjectionEnterprisePolicy -SubscriptionId` fails with an `ItemNotFound` error from `Get-AzResource` at `Private/AzHelper.ps1:378`.

### Error Details

```
Get-AzResource: /home/vinod/.local/share/powershell/Modules/Microsoft.PowerPlatform.EnterprisePolicies/0.13.0/Private/AzHelper.ps1:378
Line |
 378 |      $policies = Get-AzResource @params
     |                  ~~~~~~~~~~~~~~~~~~~~~~
     | ItemNotFound : No Enterprise Policy found for tenantId: 18a59a81-eea8-4c30-948a-d8824cdc2580
     | subscriptionId: dc932f67-56de-4334-a09f-66e43501024e
     | resourceGroup: test-networking-poc
     | enterprisePolicyName: eastus_sntinjection
     | CorrelationId: 971f8741-acab-44bc-96ac-36df15d42fc6
```

### Environment

- Module version: 0.13.0
- PowerShell: Linux (pwsh)
- Azure Environment: AzureCloud
- Account: MSI@50342
- Tenant: 18a59a81-eea8-4c30-948a-d8824cdc2580
- Subscription: dc932f67-56de-4334-a09f-66e43501024e

## Root Cause Analysis

### Call Chain

1. `Get-SubnetInjectionEnterprisePolicy -SubscriptionId` resolves to `'BySubscription'` parameter set
2. Calls `Get-EnterprisePolicy -Kind ([PolicyType]::NetworkInjection)` (line 105)
3. `Get-EnterprisePolicy` builds params with `-ExpandProperties $true` and `-ResourceType "Microsoft.PowerPlatform/enterprisePolicies"` (lines 364-378)
4. `Get-AzResource @params` enumerates all enterprise policies in the subscription

### Why It Fails

The `-ExpandProperties $true` parameter in `Get-EnterprisePolicy` (line 364) causes the failure:

1. **ARM** discovers a resource record for `eastus_sntinjection` in resource group `test-networking-poc`
2. Because `-ExpandProperties` is set, ARM calls back into the **Power Platform Resource Provider (PPRP)** to hydrate the full resource properties
3. The PPRP responds with `ItemNotFound` — the ARM record exists but the PPRP backend has no corresponding resource
4. `Get-AzResource` throws a terminating error, failing the entire enumeration

This is a **ghost/orphaned ARM resource** — the ARM registration exists but the Power Platform backend resource has been deleted or is out of sync. Common causes:
- Partially completed deletion (ARM record left behind)
- Failed deployment leaving a dangling resource record
- PPRP backend cleanup that didn't notify ARM

## Workaround Analysis

### Option 1: Delete the orphaned resource via `Remove-AzResource`

```powershell
Remove-AzResource -ResourceId "/subscriptions/dc932f67-56de-4334-a09f-66e43501024e/resourceGroups/test-networking-poc/providers/Microsoft.PowerPlatform/enterprisePolicies/eastus_sntinjection" -Force
```

**Risk:** `Remove-AzResource` sends a DELETE request to the PPRP (Power Platform Resource Provider, hosted in the Quartz repo — QuartzApp Service Fabric application). Since the PPRP doesn't recognize this resource (as evidenced by the `ItemNotFound` during GET), the DELETE **may also fail** for the same reason.

**Per ARM RP contract guidelines**, the DELETE operation **should** be idempotent and return `204 No Content` when the resource doesn't exist. However, we could **not confirm** the PPRP's actual implementation (Quartz repo is internal/inaccessible from GitHub). The behavior depends entirely on how PPRP's DELETE handler is coded:
- If PPRP follows the ARM contract and treats DELETE as **idempotent** (returns 200/204 for non-existent resources), ARM will clean up its record — problem solved.
- If PPRP returns an **error** (e.g., 404 ItemNotFound) for DELETE on a non-existent resource, the call will fail and the orphaned ARM record will remain.

**ARM deletion retry behavior** (from [official docs](https://learn.microsoft.com/azure/azure-resource-manager/management/delete-resource-group)):
- After DELETE, ARM issues a GET to confirm deletion. If GET returns 404, ARM considers the deletion successful and removes the resource from its cache.
- ARM retries DELETE for 5xx, 429, and 408 status codes (retry period: 15 minutes).
- If the RP returns a non-retryable error, ARM fails the deletion.

### Option 2: Direct ARM REST API call to delete the record

If `Remove-AzResource` fails because PPRP rejects the DELETE, try calling the ARM API directly to see if the RP error still blocks removal:

```powershell
# Get the current auth token
$token = (Get-AzAccessToken).Token

# Call ARM REST API directly
$resourceId = "/subscriptions/dc932f67-56de-4334-a09f-66e43501024e/resourceGroups/test-networking-poc/providers/Microsoft.PowerPlatform/enterprisePolicies/eastus_sntinjection"
$uri = "https://management.azure.com${resourceId}?api-version=2020-10-01"

Invoke-RestMethod -Uri $uri -Method DELETE -Headers @{
    Authorization = "Bearer $token"
    Content-Type  = "application/json"
}
```

Note: This calls the same RP under the hood, so if PPRP returns an error, this will also fail.

### Option 3: Contact PPRP / Azure Support

If programmatic deletion fails, the ARM record must be cleaned up by:
- **PPRP team** (Quartz, QuartzApp — owns the `Microsoft.PowerPlatform` RP): They can investigate why the backend is out of sync and fix the RP-side data.
- **Azure Support**: Can escalate to ARM to manually purge the orphaned resource record.
- **ARM team directly**: In extreme cases, ARM can remove a stale resource record from its database if the RP confirms the resource no longer exists.

### Option 4: Make `Get-EnterprisePolicy` resilient to orphaned resources (code fix)

Add error handling in `Get-EnterprisePolicy` so that a single orphaned resource doesn't break the entire enumeration. For example:

```powershell
# Approach A: Try with ExpandProperties, fall back to without
try {
    $policies = Get-AzResource @params
}
catch {
    Write-Warning "Failed to expand properties for some resources. Retrying without property expansion: $_"
    $params.Remove('ExpandProperties')
    $policies = Get-AzResource @params
}

# Approach B: Enumerate without expansion, then expand individually
$params.Remove('ExpandProperties')
$policies = Get-AzResource @params
$expandedPolicies = foreach ($p in $policies) {
    try {
        Get-AzResource -ResourceId $p.ResourceId -ExpandProperties
    }
    catch {
        Write-Warning "Skipping orphaned resource $($p.ResourceId): $_"
        $p  # return the unexpanded resource as fallback
    }
}
```

**Approach B** is preferred — it allows healthy resources to be returned even when one resource is orphaned.

## Recommendation

1. **Immediate**: Try `Remove-AzResource` to clean up the orphaned record. Per ARM RP contract, PPRP *should* return 204 for non-existent resources on DELETE — but this is unconfirmed.
2. **If Remove-AzResource fails**: Contact the **PPRP team** (Quartz/QuartzApp) to investigate the backend desync, or escalate via **Azure Support** to have ARM purge the orphaned record.
3. **Long-term**: Implement resilience in `Get-EnterprisePolicy` (Option 4, Approach B) so orphaned resources don't break enumeration for all users in the subscription. This is the only fix that protects against future occurrences.

## Pending: Quartz Repo Investigation (from other agent)

The following questions need to be answered by reviewing the PPRP code in the Quartz repo (QuartzApp Service Fabric application):

1. **DELETE handler behavior**: In the PPRP enterprise policy DELETE handler, what HTTP status code is returned when the resource does **not** exist in the PPRP backend?
   - Does it return `204 No Content` (idempotent, per ARM contract)?
   - Or does it return `404 ItemNotFound` / throw an error?
   - Provide the relevant code snippet and file path.

2. **GET handler behavior**: When `ExpandProperties` triggers a GET to hydrate resource properties, and the resource doesn't exist in PPRP, does PPRP return `ItemNotFound` as a terminating error or a non-terminating warning?
   - This confirms whether the GET failure is expected behavior or a bug.

3. **Orphaned resource scenario**: Is there any existing mechanism in PPRP to handle the case where an ARM resource record exists but the PPRP backend has no corresponding resource?
   - E.g., a reconciliation job, a soft-delete state, or a cleanup process.

4. **Root cause of desync**: What could cause the ARM record to exist without a PPRP backend record?
   - Failed async provisioning that left ARM in a created state?
   - A PPRP-side cleanup/migration that didn't notify ARM?

---

## Quartz Repo Investigation Findings (from Quartz agent)

### Q1: DELETE Handler Behavior — ✅ Returns 204 (Idempotent)

**File:** `quartz/src/PowerPlatformRP/Manager/Managers/EnterprisePolicyManager.cs` lines 602-649

When DELETE is called for an enterprise policy that **does not exist** in PPRP Cosmos DB, the handler returns **HTTP 204 No Content** — fully idempotent per ARM RP contract.

```csharp
// EnterprisePolicyManager.cs:615-630
var enterprisePolicyDoc = await this
    .GetEnterprisePolicyDocumentFromStorageAsync(
        tenantId, subscriptionId, resourceGroup, enterprisePolicyName)
    .ConfigureAwait(false);

if (enterprisePolicyDoc == null)  // <-- resource not in Cosmos
{
    this.Logger.LogInformation(...);
    return new NoContentResult();  // <-- HTTP 204
}
```

Both the "not found" and "successfully deleted" paths return `NoContentResult()` (204).

**Implication: `Remove-AzResource` WILL WORK as a workaround.** ARM will send DELETE to PPRP, PPRP returns 204, ARM does a GET-after-DELETE which returns 404, ARM considers deletion successful and removes its stale record.

---

### Q2: GET Handler Behavior — Returns 404 ItemNotFound (Terminating Error)

**File:** `quartz/src/PowerPlatformRP/Manager/Managers/EnterprisePolicyManager.cs` lines 176-207

When ARM calls GET to hydrate/expand properties and the resource doesn't exist in Cosmos, PPRP **throws `ItemNotFoundException`** which maps to **HTTP 404**:

```csharp
// EnterprisePolicyManager.cs:195-200
if (enterprisePolicyDoc == null)
{
    var message = $"No Enterprise Policy found for tenantId: {tenantId} ...";
    throw new ItemNotFoundException(message);  // <-- throws 404
}
```

**Exception → HTTP mapping:**

```csharp
// ItemNotFoundException.cs:16
[MonitoredExceptionMetadata(HttpStatusCode.NotFound, ErrorNamespaces.ItemNotFound,
    ErrorCodes.ItemNotFoundError, MonitoredExceptionKind.Benign)]
public class ItemNotFoundException : MonitoredException
```

The `MonitoredExceptionsMiddleware` (`Shared/Common.WebApi/Middlewares/MonitoredExceptionsMiddleware.cs`) catches this and serializes it as an HTTP 404 JSON error response.

**This confirms the root cause:** When `Get-AzResource -ExpandProperties` enumerates enterprise policies, ARM finds the orphaned ARM record and calls PPRP GET to hydrate it. PPRP returns 404, which causes `Get-AzResource` to throw a terminating error, breaking the entire enumeration.

---

### Q3: Orphaned Resource Handling — No Reconciliation Exists

**No reconciliation job, no soft-delete, no cleanup process exists.**

| Aspect | Finding |
|--------|---------|
| **ARM↔PPRP reconciliation job** | ❌ None. No job compares ARM records against Cosmos records. |
| **Soft-delete** | ❌ `EnterprisePolicyDocument` (`Storage/Entities/EnterprisePolicyDocument.cs`) has no `isDeleted`/`deletedAt` field. Deletion is a hard Cosmos `DeleteItemAsync`. |
| **Health jobs** | `EnterprisePolicyHealthJob` and `CheckIndividualEnterprisePolicyHealthJob` (`Jobs/BackgroundJobs/`) monitor encryption EP health (key vault access) but do **not** reconcile ARM records. If EP is missing from Cosmos, the health job logs a warning and completes — no cleanup. |
| **Garbage collection** | ❌ None found. |
| **Hard delete implementation** | `EnterprisePolicyRepository.cs:445-547` — cascading hard delete: Private Endpoints → Virtual Network Subnets → Enterprise Policy document, all via `DeleteItemAsync`. |

---

### Q4: Root Causes of ARM↔PPRP Desync

Several code paths can leave an ARM record without a corresponding PPRP record:

#### Scenario A: Failed Async Provisioning (ARM record created, PPRP create fails)

**File:** `EnterprisePolicyManager.cs` lines 235-458 (CreateOrUpdateEnterprisePolicyAsync)

ARM handles resource creation in two phases:
1. ARM creates its own resource record (before calling PPRP)
2. ARM calls PPRP PUT to create the backend resource

If step 2 fails (network error, Cosmos timeout, validation error), ARM may still have the resource record. The PPRP create is **synchronous** (no async provisioning state), so a failure means Cosmos never got the record, but ARM might have already registered it.

#### Scenario B: PPRP-side deletion without ARM notification

**File:** `EnterprisePolicyRepository.cs:541-547`

The hard delete in PPRP (`DeleteItemAsync`) has no mechanism to notify ARM. If a PPRP-side cleanup, migration, or manual Cosmos operation removes a record, ARM is never told.

#### Scenario C: Partial cascade delete failure

**File:** `EnterprisePolicyManager.cs:1083-1115` (DeleteEnterprisePolicyAndItsSubResourcesAsync)

During deletion, PPRP first deletes sub-resources (private endpoints, VNet subnets) then the EP itself. If the EP delete succeeds in PPRP but ARM's DELETE response handling fails, ARM keeps its record.

#### Scenario D: Failed SAL/NRP operations during create

After creating the EP in Cosmos (line 366-369), PPRP creates SALs (Subnet Access Links) via NRP (lines 372-381). If SAL creation fails, the EP exists in PPRP but may be in an inconsistent state. If someone then manually cleans up the PPRP record (e.g., via Cosmos directly), ARM retains the stale record.

---

## Confirmed Recommendation

Based on the Quartz code investigation:

1. **✅ `Remove-AzResource` WILL work** — PPRP DELETE returns 204 for non-existent resources (confirmed in code). This will clean up the orphaned ARM record for `eastus_sntinjection`.

```powershell
Remove-AzResource -ResourceId "/subscriptions/dc932f67-56de-4334-a09f-66e43501024e/resourceGroups/test-networking-poc/providers/Microsoft.PowerPlatform/enterprisePolicies/eastus_sntinjection" -Force
```

2. **Long-term fix still recommended** — Implement resilience in `Get-EnterprisePolicy` (Option 4, Approach B from above) to handle orphaned resources gracefully, since there's no reconciliation mechanism to prevent future orphans.

---

## Diagnostic Kusto Queries

Use these queries against `DB_EG_Island_Prod_CAPAnalytics_All` to trace PPRP operations for this tenant/subscription. Adjust `_eventTime` to the time of reproduction.

### Query 1: PPRP OperationEvents by Tenant

Traces all PowerPlatformRP operations for the affected tenant to see GET/DELETE calls and their outcomes:

```kql
let _eventTime =  datetime(2026-03-05 06:10);
let _startTime = _eventTime - 40m;
let _endTime =_eventTime + 20m;
	macro-expand isfuzzy=true force_remote=false DB_EG_Island_Prod_CAPAnalytics_All as X
	(
	X.OperationEvents
	| where env_time between (_startTime .. _endTime)
	| where applicationName == "fabric:/PowerPlatform.QuartzApp"
	| where activityName contains "PowerPlatformRP"
	//| where eventType  == "End"
	| extend requestUri = extract_json("$requestUri", customDimensions)
	| where principalTenantId == "18a59a81-eea8-4c30-948a-d8824cdc2580"
	| project-reorder env_time, applicationName, activityName, requestUri, customDimensions, correlationId
	| limit 100
)
```

### Query 2: PPRP CommunicationEvents by CorrelationId

Check incoming communication events for specific correlation IDs to trace the full request lifecycle:

```kql
let _eventTime =  datetime(2026-03-05 06:10);
let _startTime = _eventTime - 40m;
let _endTime =_eventTime + 20m;
	macro-expand isfuzzy=true force_remote=false DB_EG_Island_Prod_CAPAnalytics_All as X
	(
	X.CommunicationEvents
	| where env_time between (_startTime .. _endTime)
	| where applicationName == "fabric:/PowerPlatform.QuartzApp"
	| where correlationId in ("0170c60d-5cc1-429e-afae-91b146006b17", "a063ac20-ff63-4b81-8210-a176bb782d0e", "0f1bc5bd-4a3c-4232-bf8f-a99c2567c5a7", "d90deae5-feda-455f-b319-0432aa702842")
	| where eventType  == "End"
	| where direction == "Incoming"
	| extend requestUri = extract_json("$requestUri", customDimensions)
	| where requestUri !contains "health/ping"
	| project-reorder env_time, applicationName, activityName, requestUri, customDimensions, correlationId
	| limit 1000
)
```

**What to look for:**
- In Query 1: Look for GET requests to `/enterprisePolicies/eastus_sntinjection` — these should show the `ItemNotFound` error response that causes the `Get-AzResource` failure.
- In Query 2: Trace the full communication flow for specific correlation IDs to confirm the request reached PPRP and see the exact error response.
- After running `Remove-AzResource`: Re-run Query 1 with updated `_eventTime` to confirm DELETE was received by PPRP and returned 204.

## References

- [ARM Resource Group and Resource Deletion](https://learn.microsoft.com/azure/azure-resource-manager/management/delete-resource-group) — Documents ARM's DELETE retry and GET-after-DELETE behavior
- [ARM RP Contract — DELETE should be idempotent](https://learn.microsoft.com/azure/architecture/microservices/design/api-design#idempotent-operations) — HTTP spec requires DELETE to be idempotent
- PPRP source: Quartz repo (QuartzApp Service Fabric application) — [Eng Hub internal docs](https://eng.ms/docs/experiences-devices/business-and-industry-copilot/bic-power-platform/pplat-managed-platform/quartz-governance-services-power-platform/internal-docs/index)
