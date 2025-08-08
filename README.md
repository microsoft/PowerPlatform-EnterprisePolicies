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

## Using the SubnetInjection Diagnostic Scripts

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

For a full list of available cmdlets and their usage, you can refer to the help documentation by checking out the [EnterprisePolicies Docs](./docs/en-US/EnterprisePolicies) folder.

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
