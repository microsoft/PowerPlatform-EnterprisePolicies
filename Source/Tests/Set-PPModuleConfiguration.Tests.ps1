param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Set-PPModuleConfiguration Tests' {
    BeforeAll {
        Mock Write-Verbose {}
        Mock Set-CachedConfiguration {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    It 'Blocks the reserved ServicePrincipalAuth name and points to the dedicated cmdlet' {
        { Set-PPModuleConfiguration -Name "ServicePrincipalAuth" -Value @{ Method = "ManagedIdentity"; ClientId = "abc" } } |
            Should -Throw "*Set-PPServicePrincipalAuth*"

        Should -Invoke Set-CachedConfiguration -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    It 'Stores a generic named value' {
        Set-PPModuleConfiguration -Name "MySetting" -Value "SomeValue"

        Should -Invoke Set-CachedConfiguration -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { $Name -eq "MySetting" -and $Value -eq "SomeValue" }
    }

    It 'Passes a null value through to remove the entry' {
        { Set-PPModuleConfiguration -Name "MySetting" -Value $null } | Should -Not -Throw

        Should -Invoke Set-CachedConfiguration -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { $Name -eq "MySetting" -and $null -eq $Value }
    }

    It 'Throws when Name is null or empty' {
        { Set-PPModuleConfiguration -Name "" -Value "x" } | Should -Throw
    }
}
