BeforeDiscovery {
    . $PSScriptRoot\Shared.ps1
    $moduleFiles = Get-ChildItem -Path "$Global:ModuleManifestPath\*.psm1"
    $scriptFiles = $Global:ModuleScriptsPaths | ForEach-Object { Get-ChildItem -Path "$_\*.ps1" }
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
                "Types.psm1" #This file only contains type definitions and does not have any logic that requires testing. 
            )
        }
    
        It 'Exists in the manifest' {
            $Global:ModuleManifestFilePath | Should -FileContentMatch "$fileName"
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
            $testFileName = $fileName.Replace('.psm1','.Tests.ps1')
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

Describe 'Script Tests' {
    BeforeAll {
        # List of files that historically do not have a test file. All new scripts shall have test files.
        $excludeFromTestFile = @(
            "CreateSubnetInjectionEnterprisePolicy.ps1",
            "GetSubnetInjectionEnterprisePoliciesInResourceGroup.ps1",
            "GetSubnetInjectionEnterprisePoliciesInSubscription.ps1",
            "GetSubnetInjectionEnterPrisePolicyByResourceId.ps1",
            "GetSubnetInjectionEnterprisePolicyForEnvironment.ps1",
            "NewSubnetInjection.ps1",
            "RemoveSubnetInjectionEnterprisePolicy.ps1",
            "RevertSubnetInjection.ps1",
            "SetupVnetForSubnetDelegation.ps1",
            "SwapSubnetInjection.ps1",
            "UpdateSubnetInjectionEnterprisePolicy.ps1",
            "ValidateVnetLocationForEnterprisePolicy.ps1"
        )
    }
    Context "Testing file <fileName>" -ForEach $scriptFiles {
        BeforeAll {
            # Renaming the automatic $_ variable to $file
            # to make it easier to work with
            $file = $_
            $fileName = Split-Path -Path $file -Leaf
            $disclaimer = '<#\r\nSAMPLE CODE NOTICE\r\n\r\nTHIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,\r\nOF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.\r\nTHE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.\r\nNO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.\r\n#>'
            $moduleImportPattern = 'Import-Module "\$PSScriptRoot\\\.\.\\(\\\.\.\\)?CommonV2\\EnterprisePolicies" -Force'
            $usingPattern = 'using module \.\.\\(\\\.\.\\)?CommonV2\\Types\.psm1'
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

        It 'Always imports the module' {
            if($fileName -in $excludeFromTestFile)
            {
                return
            }
            $fileContent = Get-Content -Path $file -ErrorAction Stop
            $fileContent | select-string -Pattern $moduleImportPattern | Should -Not -Be $null
        }

        It 'Always uses the using module statement' {
            if($fileName -in $excludeFromTestFile)
            {
                return
            }
            $fileContent = Get-Content -Path $file -ErrorAction Stop
            $fileContent | select-string -Pattern $usingPattern | Should -Not -Be $null
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
