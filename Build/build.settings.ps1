###############################################################################
# Customize these properties and tasks for your module.
###############################################################################

Properties {
    # ----------------------- Basic properties --------------------------------

    # The root directories for the module's docs, src and test.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $DocsRootDir = "$PSScriptRoot\..\docs"
    $SrcRootDir  = "$PSScriptRoot\..\Source\Microsoft.PowerPlatform.EnterprisePolicies"
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $RepoRootDir = "$PSScriptRoot\.."
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TestRootDir = "$PSScriptRoot\..\Source\Tests"
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ScriptsRootDir = "$PSScriptRoot\..\Source\Microsoft.PowerPlatform.EnterprisePolicies\Public\SubnetInjection"
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $PublicScriptsDir = "$PSScriptRoot\..\Source\Microsoft.PowerPlatform.EnterprisePolicies\Public"
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]

    $BuildVersion = "1.0.0"
    if($env:GitVersion_MajorMinorPatch)
    {
        $BuildVersion = $env:GitVersion_MajorMinorPatch

    }

    # The name of your module should match the basename of the PSD1 file.
    $ModuleName = Get-Item $SrcRootDir/*.psd1 |
                      Where-Object { $null -ne (Test-ModuleManifest -Path $_ -ErrorAction SilentlyContinue) } |
                      Select-Object -First 1 | Foreach-Object BaseName

    # The $OutDir must match the ModuleName in order to support publishing the module.
    $ReleaseDir = "$PSScriptRoot\..\Release"
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $OutDir     = "$ReleaseDir\$ModuleName"

    # Default Locale used for documentation generatioon, defaults to en-US.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $DefaultLocale = "en-US"

    # Items in the $Exclude array will not be copied to the $OutDir e.g. $Exclude = @('.gitattributes')
    # Typically you wouldn't put any file under the src dir unless the file was going to ship with
    # the module. However, if there are such files, add their $SrcRootDir relative paths to the exclude list.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $Exclude = @("*.md")

    # ------------------ Script analysis properties ---------------------------

    # Enable/disable use of PSScriptAnalyzer to perform script analysis.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ScriptAnalysisEnabled = $false

    # When PSScriptAnalyzer is enabled, control which severity level will generate a build failure.
    # Valid values are Error, Warning, Information and None.  "None" will report errors but will not
    # cause a build failure.  "Error" will fail the build only on diagnostic records that are of
    # severity error.  "Warning" will fail the build on Warning and Error diagnostic records.
    # "Any" will fail the build on any diagnostic record, regardless of severity.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    [ValidateSet('Error', 'Warning', 'Any', 'None')]
    $ScriptAnalysisFailBuildOnSeverityLevel = 'Error'

    # Path to the PSScriptAnalyzer settings file.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ScriptAnalyzerSettingsPath = "$PSScriptRoot\ScriptAnalyzerSettings.psd1"

    # ------------------- Script signing properties ---------------------------

    # Set to $true if you want to sign your scripts. You will need to have a code-signing certificate.
    # You can specify the certificate's subject name below. If not specified, you will be prompted to
    # provide either a subject name or path to a PFX file.  After this one time prompt, the value will
    # saved for future use and you will no longer be prompted.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ScriptSigningEnabled = $false

    # Specify the Subject Name of the certificate used to sign your scripts.  Leave it as $null and the
    # first time you build, you will be prompted to enter your code-signing certificate's Subject Name.
    # This variable is used only if $SignScripts is set to $true.
    #
    # This does require the code-signing certificate to be installed to your certificate store.  If you
    # have a code-signing certificate in a PFX file, install the certificate to your certificate store
    # with the command below. You may be prompted for the certificate's password.
    #
    # Import-PfxCertificate -FilePath .\myCodeSigingCert.pfx -CertStoreLocation Cert:\CurrentUser\My
    #
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CertSubjectName = $null

    # Certificate store path.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CertPath = "Cert:\"

    # ------------------- Testing properties ----------------------------------

    # Enable/disable Pester code coverage reporting.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CodeCoverageEnabled = $true

    # CodeCoverageFiles specifies the files to perform code coverage analysis on. This property
    # acts as a direct input to the Pester -CodeCoverage parameter, so will support constructions
    # like the ones found here: https://github.com/pester/Pester/wiki/Code-Coverage.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CodeCoverageFiles = "$ScriptsRootDir\**\*.ps1", "$SrcRootDir\**\*.ps1"

    # Specifies an output file path to send to Invoke-Pester's CodeCoverage.OutputPath configuration.
    # This is typically used to write out test results so that they can be sent to a CI
    # system like AppVeyor.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CodeCoverageOutputPath = "$PSScriptRoot\coverage.xml"

    # Specifies the code coverage output format to use when the OutputFormat property is given
    # a path.  This parameter is passed through to Invoke-Pester's CodeCoverage.OutputFormat configuration.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CodeCoverageOutputFormat = "JaCoCo"

    # -------------------- Publishing properties ------------------------------

    # Your NuGet API key for the PSGallery.  Leave it as $null and the first time you publish,
    # you will be prompted to enter your API key.  The build will store the key encrypted in the
    # settings file, so that on subsequent publishes you will no longer be prompted for the API key.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $NuGetApiKey = $null

    # Name of the repository you wish to publish to. If $null is specified the default repo (PowerShellGallery) is used.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $PublishRepository = $null

    # Path to the release notes file.  Set to $null if the release notes reside in the manifest file.
    # The contents of this file are used during publishing for the ReleaseNotes parameter.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ReleaseNotesPath = $null

    # ----------------------- Misc properties ---------------------------------

    # The local installation directory for the install task. Defaults to your home Modules location.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $InstallPath = $null

    # In addition, PFX certificates are supported in an interactive scenario only,
    # as a way to import a certificate into the user personal store for later use.
    # This can be provided using the CertPfxPath parameter. PFX passwords will not be stored.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $SettingsPath = "$env:LOCALAPPDATA\Plaster\NewModuleTemplate\SecuredBuildSettings.clixml"

    # Specifies that Pester should output test results.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TestOutputEnabled = $true

    # Specifies an output file path to send to Invoke-Pester's -OutputFile parameter.
    # This is typically used to write out test results so that they can be sent to a CI
    # system like AppVeyor.
    if($PSVersionTable.PSEdition -eq "Core") {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
        $TestOutputFile = "$PSScriptRoot\TestResultCore.xml"
    }
    else {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
        $TestOutputFile = "$PSScriptRoot\TestResult.xml"
    }


    # Specifies the test output format to use when the TestOutputFile property is given
    # a path.  This parameter is passed through to Invoke-Pester's -OutputFormat parameter.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TestOutputFormat = "NUnitXml"
}

###############################################################################
# Customize these tasks for performing operations before and/or after Build.
###############################################################################

# Executes before the BuildImpl phase of the Build task.
Task PreBuild {

}

# Executes after the Sign phase of the Build task.
Task PostBuild {
    $FunctionsToExport = @()
    Get-ChildItem $PublicScriptsDir -Recurse -Filter *.ps1 | ForEach-Object {
        $FunctionsToExport += (Split-Path -Leaf $_.FullName).Split('.')[0]
    }
    if($FunctionsToExport.Count -eq 0)
    {
        throw "No public functions found to export. Please check that there are .ps1 files under the Public folder."
    }
    $moduleFile = Get-Item "$ReleaseDir\$ModuleName\*.psd1"
    (Get-Content $moduleFile).Replace("ModuleVersion = '1.0.0'", "ModuleVersion = '$BuildVersion'") | Set-Content $moduleFile
    (Get-Content $moduleFile).Replace("ReleaseNotes = ''", "ReleaseNotes = 'https://github.com/microsoft/PowerPlatform-EnterprisePolicies/releases/tag/$BuildVersion'") | Set-Content $moduleFile
    (Get-Content $moduleFile).Replace("FunctionsToExport = '*'", "FunctionsToExport = @('$($FunctionsToExport -join "','")')") | Set-Content $moduleFile
    Copy-Item $RepoRootDir\LICENSE $ReleaseDir\$ModuleName\LICENSE.md
}

###############################################################################
# Customize these tasks for performing operations before and/or after BuildHelp.
###############################################################################

# Executes before the GenerateMarkdown phase of the BuildHelp task.
Task PreBuildHelp {
}

# Executes after the BuildHelpImpl phase of the BuildHelp task.
Task PostBuildHelp -requiredVariables DocsRootDir, ModuleName, DefaultLocale{
    
    $markdownToAppend = @"
## Types

### Classes

#### [EnvironmentNetworkUsageDocument](EnvironmentNetworkUsageDocument.md)

The `EnvironmentNetworkUsageDocument` class represents historical network usage information and network usage metadata about the delegated network of a Power Platform environment.

#### [NetworkUsage](NetworkUsage.md)

The `NetworkUsage` class represents metadata about the network configuration of a Power Platform environment.

### [NetworkUsageData](NetworkUsageData.md)

The `NetworkUsageData` class represents historical network usage information about the network configuration of a Power Platform environment.

### [SubnetUsageDocument](SubnetUsageDocument.md)

The `SubnetUsageDocument` class represents historical network usage information and network usage metadata of a subnet delegated to one or more power platform environments.

### Enums

#### [BAPEndpoint](BAPEndpoint.md)

Represents the different BAP endpoints that can be used to connect to Power Platform services. Only endpoints that are currently supported are included.
"@

    $targetFile = "$DocsRootDir\$DefaultLocale\$ModuleName\$ModuleName.md"
    Add-Content -Path $targetFile -Value $markdownToAppend

}

###############################################################################
# Customize these tasks for performing operations before and/or after Install.
###############################################################################

# Executes before the InstallImpl phase of the Install task.
Task PreInstall {
}

# Executes after the InstallImpl phase of the Install task.
Task PostInstall {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Publish.
###############################################################################

# Executes before publishing occurs.
Task PrePublish {
}

# Executes after publishing occurs.
Task PostPublish {
}

