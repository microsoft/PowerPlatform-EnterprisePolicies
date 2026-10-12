BeforeDiscovery {
    . $PSScriptRoot\Shared.ps1
    $moduleFiles = Get-ChildItem -Path "$Global:ModuleManifestPath\Private\*.ps1"
    $scriptFiles = $Global:ModuleScriptsPaths | ForEach-Object { Get-ChildItem -Path "$_\*.ps1" -Recurse }
}

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $Global:ModuleManifestFilePath
        $? | Should -Be $true
    }

    Context "Testing file <fileName>" -ForEach $moduleFiles {
        BeforeAll {
            # Renaming the automatic $_ variable to $file
            # to make it easier to work with
            $file = $_
            $fileName = Split-Path -Path $file -Leaf
            $disclaimer = '<#\r\nSAMPLE CODE NOTICE\r\n\r\nTHIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,\r\nOF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.\r\nTHE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.\r\nNO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.\r\n#>'
            $excludeFromTestFile = @(
                "Assert-PrereqsAreInstalledAndLoaded.ps1", #This file is used to check if the required modules are installed and loaded. It does not have any logic that requires testing.
                "Types.psm1" #This file only contains type definitions and does not have any logic that requires testing.
                "MSALWrapper.ps1" #This file is a wrapper for MSAL authentication and does not have any logic that requires testing.
            )
        }

        It 'Is a valid powershell file' {
            $fileContent = Get-Content -Path $file -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($fileContent, [ref]$errors)
            $errors.Count | Should -Be 0
        }

        It 'Contains header disclaimer file' {
            $file | Should -FileContentMatchMultiline $disclaimer
        }

        It 'Has an associated test file' {
            $testFileName = $fileName.Replace('.ps1','.Tests.ps1')
            if($fileName -in $excludeFromTestFile)
            {
                "$PSScriptRoot\$testFileName" | Should -Not -Exist
            }
            else
            {
                "$PSScriptRoot\$testFileName" | Should -Exist
            }
        }
    }
}

Describe 'Trusted override import' {
    BeforeAll {
        $originalOverride = $env:POWERPLATFORM_ENTERPRISE_POLICIES_OVERRIDE
        $testModuleRoot = Join-Path $TestDrive 'OverrideImportTests'
        $null = New-Item -ItemType Directory -Path $testModuleRoot
        Get-ChildItem -LiteralPath $Global:ModuleManifestPath | Copy-Item -Destination $testModuleRoot -Recurse
        $moduleScript = Join-Path $testModuleRoot 'OverrideImportTests.psm1'
        Copy-Item -LiteralPath "$testModuleRoot\Microsoft.PowerPlatform.EnterprisePolicies.psm1" -Destination $moduleScript
    }

    AfterAll {
        $env:POWERPLATFORM_ENTERPRISE_POLICIES_OVERRIDE = $originalOverride
    }

    It 'Preserves exports when an override replaces helpers and assigns a public variable' {
        $override = Join-Path $TestDrive 'override.ps1'
        @'
function Get-PPEndpointUrl { param([PPEndpoint]$Endpoint) return 'https://custom.example/' }
function Get-CachedConfiguration { param([string]$Name) return 'custom configuration' }
function Get-OverrideOnly { return 'private' }
$public = @([pscustomobject]@{ BaseName = 'Get-OverrideOnly' })
'@ | Set-Content -LiteralPath $override
        $env:POWERPLATFORM_ENTERPRISE_POLICIES_OVERRIDE = $override
        $module = Import-Module -Name $moduleScript -Prefix HookTest -PassThru -Force -ErrorAction Stop
        try {
            (& $module { Get-PPEndpointUrl -Endpoint Custom }) | Should -Be 'https://custom.example/'
            Get-HookTestPPModuleConfiguration -Name 'test' | Should -Be 'custom configuration'
            $module.ExportedFunctions.Count | Should -Be @(Get-ChildItem -LiteralPath "$testModuleRoot\Public" -Recurse -Filter '*.ps1').Count
            @($module.ExportedFunctions.Keys | Where-Object { $_ -like '*OverrideOnly*' }).Count | Should -Be 0
        }
        finally {
            Remove-Module $module -Force
        }
    }

    It 'Rejects an existing Windows <PathKind> script' -ForEach @(
        @{ PathKind = 'drive-relative' },
        @{ PathKind = 'root-relative' }
    ) -Skip:([System.IO.Path]::DirectorySeparatorChar -ne '\') {
        $override = Join-Path $testModuleRoot 'relative-override.ps1'
        "throw 'An ambiguous override path was executed'" | Set-Content -LiteralPath $override
        $absoluteOverride = (Get-Item -LiteralPath $override).FullName
        $drive = Split-Path -Path $absoluteOverride -Qualifier
        Push-Location -LiteralPath $testModuleRoot
        try {
            $path = if ($PathKind -eq 'drive-relative') {
                "$drive$(Split-Path -Path $absoluteOverride -Leaf)"
            }
            else {
                $absoluteOverride.Substring($drive.Length)
            }
            Test-Path -LiteralPath $path -PathType Leaf | Should -BeTrue
            $env:POWERPLATFORM_ENTERPRISE_POLICIES_OVERRIDE = $path
            { Import-Module -Name $moduleScript -Force -ErrorAction Stop } | Should -Throw '*absolute path*'
        }
        finally {
            Pop-Location
        }
    }

    It 'Rejects an invalid configured path: <Path>' -ForEach @(
        @{ Path = 'relative.ps1' },
        @{ Path = 'C:\MissingOverride\override.ps1' },
        @{ Path = 'C:\MissingOverride\override.json' }
    ) {
        $env:POWERPLATFORM_ENTERPRISE_POLICIES_OVERRIDE = $Path
        { Import-Module -Name $moduleScript -Force -ErrorAction Stop } | Should -Throw '*absolute path*'
    }

    It 'Propagates a terminating override failure' {
        $override = Join-Path $TestDrive 'failing.ps1'
        "throw 'Override configuration is invalid'" | Set-Content -LiteralPath $override
        $env:POWERPLATFORM_ENTERPRISE_POLICIES_OVERRIDE = $override
        { Import-Module -Name $moduleScript -Force -ErrorAction Stop } | Should -Throw '*Override configuration is invalid*'
    }
}

Describe 'Script Tests' {
    BeforeAll {
        # List of files that historically do not have a test file. All new scripts shall have test files.
        $excludeFromTestFile = @()
    }
    Context "Testing file <fileName>" -ForEach $scriptFiles {
        BeforeAll {
            # Renaming the automatic $_ variable to $file
            # to make it easier to work with
            $file = $_
            $fileName = Split-Path -Path $file -Leaf
            $disclaimer = '<#\r\nSAMPLE CODE NOTICE\r\n\r\nTHIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,\r\nOF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.\r\nTHE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.\r\nNO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.\r\n#>'
            $fileContent = Get-Content -Path $file -ErrorAction Stop
        }

        It 'Is a valid powershell file' {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($fileContent, [ref]$errors)
            $errors.Count | Should -Be 0
        }

        It 'Contains header disclaimer file' {
            $file | Should -FileContentMatchMultiline $disclaimer
        }

        It 'Has an associated test file' {
            $testFileName = $fileName.Replace('.ps1','.Tests.ps1')
            if($fileName -in $excludeFromTestFile)
            {
                "$PSScriptRoot\$testFileName" | Should -Not -Exist
            }
            else
            {
                "$PSScriptRoot\$testFileName" | Should -Exist
            }
        }

        It 'Has a single function defined and matches file name'{
            $functions = @()
            $tokens = $null
            $errors = $null
            $tokens = [System.Management.Automation.PSParser]::Tokenize($fileContent, [ref]$errors)
            for ($i = 0; $i -lt $tokens.Count; $i++) {
                if ($tokens[$i].Type -eq 'Keyword' -and $tokens[$i].Content -eq 'function') {
                    # The next token should be the function name
                    if ($i + 1 -lt $tokens.Count) {
                        $functionName = $tokens[$i + 1].Content
                        $functions += $functionName
                    }
                }
            }
            $functions.Count | Should -Be 1
            if($functions.Count -eq 1)
            {
                $functions[0] | Should -Be ($fileName -replace '\.ps1$','')
            }
        }
    }

    Context 'Validating exclude tests list'{
        It 'Exclude list should not contain non-existent scripts. Please remove the following scripts: <needToCleanUp>.' {
            $scriptNames = $Global:ModuleScriptsPaths | ForEach-Object { Get-ChildItem -Path "$_\*.ps1" } | ForEach-Object { $_.Name }
            $needToCleanUp = $()
            $excludeFromTestFile | ForEach-Object {
                if($_ -notin $scriptNames)
                {
                    $needToCleanUp += $_
                }
            }
            $needToCleanUp | Should -BeNullOrEmpty
        }
    }
}
