# The PowerShell Script Analyzer will generate a warning
# diagnostic record for this file due to a bug -
# https://github.com/PowerShell/PSScriptAnalyzer/issues/472
@{
    # Only diagnostic records of the specified severity will be generated.
    # Uncomment the following line if you only want Errors and Warnings but
    # not Information diagnostic records.
    #Severity = @('Error','Warning')

    # Analyze **only** the following rules. Use IncludeRules when you want
    # to invoke only a small subset of the default rules.
    IncludeRules = @('PSAvoidDefaultValueSwitchParameter',
                     'PSMisleadingBacktick',
                     'PSMissingModuleManifestField',
                     'PSReservedCmdletChar',
                     'PSReservedParams',
                     'PSShouldProcess',
                     'PSUseApprovedVerbs',
                     'PSAvoidUsingCmdletAliases',
                     'PSUseDeclaredVarsMoreThanAssigments',
                     'PSAvoidUsingUsernameAndPasswordParams',
                     'PSAvoidUsingComputerNameHardcoded',
                     'PSAvoidUsingConvertToSecureStringWithPlainText',
                     'PSUseCompatibleSyntax',
                     'PSDSCUseIdenticalMandatoryParametersForDSC',
                     'PSDSCStandardDSCFunctionsInResource')

    # Do not analyze the following rules. Use ExcludeRules when you have
    # commented out the IncludeRules settings above and want to include all
    # the default rules except for those you exclude below.
    # Note: if a rule is in both IncludeRules and ExcludeRules, the rule
    # will be excluded.
    #ExcludeRules = @('PSAvoidUsingWriteHost')

    # You can use the following entry to supply parameters to rules that take parameters.
    # For instance, the PSAvoidUsingCmdletAliases rule takes an accept list for aliases you
    # want to allow.
    #Rules = @{
    #    Check if your script uses cmdlets that are compatible on PowerShell Core,
    #    version 6.0.0-alpha, on Linux.
    #    PSUseCompatibleCmdlets = @{Compatibility = @("core-6.0.0-alpha-linux")}
    #}
}