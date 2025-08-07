# Project

This repository contains the source code for the Power Platform Enterprise Policies project, which provides a set of scripts to help setup and manage enterprise policies for Power Platform environments. In addition, it includes scripts for helping troubleshoot issues with the VNET functionality provided by Power Platform.

## Using the Enterprise Policies Scripts

The Enterprise Policies scripts are designed to help manage and enforce policies across Power Platform environments. They can be run in both Windows PowerShell and PowerShell Core environments.

Clone the repository and navigate to the `Source` directory.

If you have never interacted with the scripts before, run the following command to setup your subscription as well as your machine:

```powershell
.\SetupSubscriptionForPowerPlatform.ps1
.\InstallPowerAppsCmdlets.ps1
```

This will install the necessary Power Platform cmdlets and set up your environment for running the scripts.

You can then run the scripts as needed. For example, to run the `CreateSubnetInjectionEnterprisePolicy.ps1` script, you would use:

```powershell
.\SubnetInjection\CreateSubnetInjectionEnterprisePolicy.ps1
```

## Using the Diagnostic Scripts

The diagnostic scripts are designed to help troubleshoot issues with the VNET functionality provided by Power Platform. They can be run in both Windows PowerShell and PowerShell Core environments.

Clone the repository and navigate to the `Source` directory.

Run the following command the first time you open the PowerShell session:

```powershell
Import-Module .\EnterprisePolicies
```

This will import the module, validate prerequisites and make the scripts available for use.

You can then run the diagnostic scripts as needed. For example, to run the `Get-EnvironmentUsage` cmdlets, you would use:

```powershell
Get-EnvironmentUsage -EnvironmentId "your-environment-id"
```

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit [Contributor License Agreements](https://cla.opensource.microsoft.com).

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
