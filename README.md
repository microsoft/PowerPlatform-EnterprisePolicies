# Power Platform Enterprise Policies PowerShell Scripts

These scripts automate managing (create, update, get, delete) Power Platform Enterprise Policies as Azure resources.</br>
In addition, we are providing sample scripts on how to associate these policies with Power Platform environments.</br>
Please note that these scripts are provided under MIT license and its usage is the sole responsibility of the user.

## Subnet Injection, Identity, and CMK Users

### Using the Power Platform Enterprise Policies Module

The Microsoft.PowerPlatform.EnterprisePolicies module is a new module that aims to simplify the management and creation of enterprise policies. It additionally, contains some diagnostic tooling specific for subnet injection scenarios. For a full list of commands that are available and its respective documentation see [Microsoft.PowerPlatform.EnterprisePolicies](./docs/en-US/Microsoft.PowerPlatform.EnterprisePolicies/Microsoft.PowerPlatform.EnterprisePolicies.md)

### Install the module from the PS Gallery

In a PowerShell session, run the following command the first time you open the PowerShell session:

```powershell
Install-Module -Name Microsoft.PowerPlatform.EnterprisePolicies
Import-Module Microsoft.PowerPlatform.EnterprisePolicies
```

This will import the module, validate prerequisites and make the functions available for use. If you are missing any prerequisites, the module will inform you and ask for permission to install them.

### Download the module from Github Releases

Go to the [Releases](https://github.com/microsoft/PowerPlatform-EnterprisePolicies/releases/latest) page and download the latest release zip file. Extract the contents to a local directory.

Navigate to the extracted directory and run the following command the first time you open the PowerShell session:

```powershell
Import-Module .\Microsoft.PowerPlatform.EnterprisePolicies
```

This will import the module, validate prerequisites and make the commands available for use. If you are missing any prerequisites, the module will inform you and ask for permission to install them.

### Forcing re-authentication

By default, the powershell module will attempt to reuse an existing Azure session if one is available. If you want to manually choose which account to use instead of letting the module automatically select one, you can pass the `-ForceAuth` switch to any of the cmdlets:

```powershell
Get-EnvironmentUsage -EnvironmentId "your-environment-id" -ForceAuth
```

This will prompt you to re-authenticate, allowing you to select or enter the credentials for the account you want to use.

### Subnet Users

### Subnet Injection Diagnostics commands

The diagnostic commands are designed to help troubleshoot issues with the VNET functionality provided by Power Platform. They can be run in both Windows PowerShell and PowerShell Core environments.

You can get the module in two different ways. Either through the PowerShell Gallery or by downloading the module from Github Releases. Both options provide the same functionality.

#### Permissions required for diagnostic commands

In order to run these diagnostics commands the user used to invoke the commands must have the Power Platform Administrator role.

To validate that the role is correctly assigned you can use the `Test-AccountPermissions` command.

#### Running the diagnostic functions

Once your module has been imported into your PowerShell session, you can now run the diagnostic functions as needed. For example, to run the `Get-EnvironmentUsage` function, you would use:

```powershell
Get-EnvironmentUsage -EnvironmentId "your-environment-id"
```

For a full list of available functions and their usage, you can refer to the help documentation by checking out the [EnterprisePolicies Docs](./docs/en-US/Microsoft.PowerPlatform.EnterprisePolicies) folder.

### Identity Users

Identity enterprise policies let a Power Platform environment use a managed identity for scenarios such as customer managed key encryption. They are now managed through the `Microsoft.PowerPlatform.EnterprisePolicies` module, which replaces the legacy scripts that previously lived under `Source/Identity`.

The summaries below give a quick overview of each cmdlet. For full parameter lists, examples, and output types, follow the links to the cmdlet reference documentation on Microsoft Learn.

#### Managing identity enterprise policies

- **[New-IdentityEnterprisePolicy](https://learn.microsoft.com/en-us/powershell/module/microsoft.powerplatform.enterprisepolicies/new-identityenterprisepolicy?view=pa-ps-latest)** : Creates a new identity enterprise policy as an Azure resource in the specified subscription, resource group, and location.
- **[Get-IdentityEnterprisePolicy](https://learn.microsoft.com/en-us/powershell/module/microsoft.powerplatform.enterprisepolicies/get-identityenterprisepolicy?view=pa-ps-latest)** : Retrieves identity enterprise policies. Replaces the separate legacy scripts that looked up a policy by ARM resource ID, subscription, or resource group.
- **[Remove-IdentityEnterprisePolicy](https://learn.microsoft.com/en-us/powershell/module/microsoft.powerplatform.enterprisepolicies/remove-identityenterprisepolicy?view=pa-ps-latest)** : Deletes an identity enterprise policy.

#### Linking policies to environments

- **[Enable-Identity](https://learn.microsoft.com/en-us/powershell/module/microsoft.powerplatform.enterprisepolicies/enable-identity?view=pa-ps-latest)** : Links an identity enterprise policy to a Power Platform environment. Use the `-Swap` switch to replace a policy that is already linked to the environment.
- **[Disable-Identity](https://learn.microsoft.com/en-us/powershell/module/microsoft.powerplatform.enterprisepolicies/disable-identity?view=pa-ps-latest)** : Unlinks an identity enterprise policy from a Power Platform environment.

## CMK Users

Customer managed key (CMK) enterprise policies let a Power Platform environment encrypt its data with a key you manage in Azure Key Vault. Policy management and environment linking are now managed through the `Microsoft.PowerPlatform.EnterprisePolicies` module, replacing the corresponding legacy scripts under `Source/Cmk`.

The summaries below give a quick overview of each cmdlet. For full parameter lists, examples, and output types, follow the links to the module's generated cmdlet documentation.

Before creating enterprise policies, register the Azure subscription for the Microsoft.PowerPlatform resource provider (this happens automatically the first time you run a creation cmdlet, or you can run [SetupSubscriptionForPowerPlatform.ps1](./Source/SetupSubscriptionForPowerPlatform.ps1)).

#### Managing CMK enterprise policies

- **[New-CMKEnterprisePolicy](./docs/en-US/Microsoft.PowerPlatform.EnterprisePolicies/New-CMKEnterprisePolicy.md)** : Creates a new CMK enterprise policy as an Azure resource in the specified subscription, resource group, and location, referencing a key vault key. Omit `-KeyVersion` to use the latest enabled key version.
- **[Get-CMKEnterprisePolicy](./docs/en-US/Microsoft.PowerPlatform.EnterprisePolicies/Get-CMKEnterprisePolicy.md)** : Retrieves CMK enterprise policies by ARM resource ID, by environment, by subscription, or by resource group. Replaces the separate legacy scripts that looked up a policy in each of those ways.
- **[Set-CMKEnterprisePolicy](./docs/en-US/Microsoft.PowerPlatform.EnterprisePolicies/Set-CMKEnterprisePolicy.md)** : Updates the key vault, key name, and/or key version referenced by an existing policy. Only the values you provide change; omitted values are left as-is.
- **[Remove-CMKEnterprisePolicy](./docs/en-US/Microsoft.PowerPlatform.EnterprisePolicies/Remove-CMKEnterprisePolicy.md)** : Deletes a CMK enterprise policy. A policy that is still linked to an environment cannot be deleted.

#### Linking policies to environments

- **[Enable-CMK](./docs/en-US/Microsoft.PowerPlatform.EnterprisePolicies/Enable-CMK.md)** : Links a CMK enterprise policy to a Power Platform environment so its data is encrypted with your key. Use the `-Swap` switch to replace a policy that is already linked to the environment.
- **[Disable-CMK](./docs/en-US/Microsoft.PowerPlatform.EnterprisePolicies/Disable-CMK.md)** : Unlinks the CMK enterprise policy from an environment, reverting it to Microsoft managed key encryption.

#### PlatformAppsData compatibility

PlatformAppsData uses a separate PlatformApps-scoped API, not the environment API used by `Enable-CMK` and `Disable-CMK`. The existing scripts check `platformapps/status` for an `Enrolled` state, then link or unlink an encryption policy through `platformapps/enterprisePolicies/Encryption` (API version `2024-05-01`).

The standalone [AddCustomerManagedKeyToPlatformAppsData.ps1](./Source/Cmk/AddCustomerManagedKeyToPlatformAppsData.ps1) and [RemoveCustomerManagedKeyFromPlatformAppsData.ps1](./Source/Cmk/RemoveCustomerManagedKeyFromPlatformAppsData.ps1) scripts and their shared helpers are retained unchanged. This migration does not add module replacements for them or change enrollment requirements. These scripts require the legacy dependencies installed by [InstallPowerAppsCmdlets.ps1](./Source/InstallPowerAppsCmdlets.ps1).

Both scripts still default to the `tip1` endpoint when `-endpoint` is omitted.

#### Validating the key vault

- **[Test-CMKKeyVault](./docs/en-US/Microsoft.PowerPlatform.EnterprisePolicies/Test-CMKKeyVault.md)** : Validates that a key vault, a CMK enterprise policy, and the encryption key satisfy the CMK prerequisites (soft delete and purge protection enabled, the policy identity has the required key access, and the key exists, is enabled, is activated, and is not expired).

#### Grant enterprise policy permissions to access key vault

After creating the enterprise policy, you must grant its managed identity access to the key vault before linking it to an environment. The enterprise policy's managed identity Object ID can be found in the `New-CMKEnterprisePolicy` output under `Identity.PrincipalId`, or via the Azure Portal (navigate to the enterprise policy resource → Identity tab).

**If your key vault uses Azure role-based access control (recommended)**:</br>
Assign the **Key Vault Crypto Service Encryption User** role to the enterprise policy's managed identity:
```powershell
New-AzRoleAssignment `
  -ObjectId "<enterprise-policy-PrincipalId>" `
  -RoleDefinitionName "Key Vault Crypto Service Encryption User" `
  -Scope "<key-vault-ARM-resource-id>"
```
Alternatively, in the Azure Portal: Key vaults → select your vault → Access control (IAM) → Add role assignment → search "Key Vault Crypto Service Encryption User" → select the enterprise policy → Review + assign.</br>

**If your key vault uses vault access policy**:</br>
Add an access policy with Get (Key Management Operations), WrapKey and UnwrapKey (Cryptographic Operations):
```powershell
Set-AzKeyVaultAccessPolicy `
  -VaultName "<key-vault-name>" `
  -ObjectId "<enterprise-policy-PrincipalId>" `
  -PermissionsToKeys Get, WrapKey, UnwrapKey
```

> **Note**: RBAC role assignments can take up to 5 minutes to propagate. If you run `Test-CMKKeyVault` immediately after granting the role, it may report a false failure. Wait a few minutes and retry.</br>

For more details, see [Grant enterprise policy permissions to access key vault](https://learn.microsoft.com/power-platform/admin/customer-managed-key#create-enterprise-policy).</br>

#### Prerequisites for linking an environment

> Before linking an environment to a CMK enterprise policy (including via the Power Platform Admin Center):</br>
> 1. The environment must be enabled as a [Managed Environment](https://learn.microsoft.com/power-platform/admin/managed-environment-enable).</br>
> 2. The Power Platform / Dynamics 365 admin must have the **Reader** role on the enterprise policy Azure resource:</br>
>    `New-AzRoleAssignment -ObjectId <PP-admin-object-id> -RoleDefinitionName Reader -Scope <EP-ARM-resource-id>`</br>
>    To find the admin's Object ID: Azure Portal → Microsoft Entra ID → Users → select user → copy Object ID.</br>
> See [Microsoft Learn: CMK prerequisites](https://learn.microsoft.com/power-platform/admin/customer-managed-key#create-encryption-key-and-grant-access) for details.

## Development

To get started with development, clone the repository and open it in VSCode. The scripts are written in PowerShell and follow standard PowerShell conventions.

Please place any common functions in the `Private` folder, and any module-level functions that are going to be exposed in the `Public` folder.

In order to run tests, please ensure you do the following from the repository root:

```powershell
# You might need the --interactive flag
dotnet restore
```

> [!NOTE]
> If you are not a Microsoft employee, you will need to modify the Nuget.config file to point to the public NuGet repository.

Then, you can enable running the tests by going to the Run and Debug view in VSCode and selecting and running the `Load Modules` script. This will load the necessary modules and allow you to run the tests.

> [!NOTE]
> You should clear out any Pester installations, as the tests are written using the latest version of Pester.

## FAQ

### General FAQ

#### Unable to add/remove EP to/from environment due to "Error getting environment"
* StatusCode: 404 
* ErrorMessage contains: *The environment '\<guid\>' could not be found in the tenant...*
* **Solution**: Ensure the user has the `Power Platform Administrator` (or equivalent) role

### Subnet Injection FAQ

#### Unable to delete VNet / Unable to modify subnet
* ErrorCode: `InUseSubnetCannotBeDeleted` or `SubnetMissingRequiredDelegation`
* ErrorMessage contains: *.../serviceAssociationLinks/PowerPlatformServiceLink...*
* **Solution**: delete the Subnet Injection enterprise policy firs with [Remove-SubnetInjectionEnterprisePolicy](./docs/en-US/Microsoft.PowerPlatform.EnterprisePolicies/Remove-SubnetInjectionEnterprisePolicy.md)

### CMK FAQ

**Q: I created a CMK Enterprise Policy but get a 403 / Forbidden error when the service accesses my Key Vault. What do I do?**</br>
A: After creating the CMK enterprise policy, Azure creates a managed identity for it. This identity needs **Key Vault Crypto Service Encryption User** role (or the legacy Wrap/Unwrap key permissions in vault access policy) on your Key Vault. See [Microsoft Learn: Grant access](https://learn.microsoft.com/power-platform/admin/customer-managed-key#create-encryption-key-and-grant-access). Find the managed identity Object ID in the Azure Portal under the enterprise policy resource → Identity blade, then grant access:
```powershell
# For RBAC (recommended):
New-AzRoleAssignment -ObjectId <EP-managed-identity-object-id> `
    -RoleDefinitionName "Key Vault Crypto Service Encryption User" `
    -Scope "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault>"
```

**Q: The scripts authenticate to the wrong Azure subscription. How do I fix this?**</br>
A: The scripts call `Connect-AzAccount` which defaults to your last-used subscription. Use one of these approaches:
```powershell
# Option 1 — Set default subscription before running scripts:
Update-AzConfig -DefaultSubscriptionForLogin <your-subscription-id>

# Option 2 — Pre-authenticate with a specific subscription:
Connect-AzAccount -Subscription <your-subscription-id>
```

**Q: I get a "file is not digitally signed" error running the scripts. What should I do?**</br>
A: After downloading or cloning the repository, Windows may block the files. Right-click each .ps1 file → Properties → check "Unblock", or run:
```powershell
Get-ChildItem -Path . -Recurse -Filter *.ps1 | Unblock-File
```

**Q: The "Validate Key Vault" step fails even though my Key Vault exists. What went wrong?**</br>
A: Common causes include: (1) the Key Vault key is not enabled or has expired, (2) soft-delete and purge-protection are not enabled on the Key Vault, (3) the managed identity does not have the correct permissions (see first FAQ above). Verify all requirements at [Microsoft Learn: Create encryption key and grant access](https://learn.microsoft.com/power-platform/admin/customer-managed-key#create-encryption-key-and-grant-access).
