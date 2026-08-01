param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Set-PPModuleConfiguration Tests' {
    BeforeAll {
        Mock Write-Verbose {}
        Mock Set-ServicePrincipalAuth {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    It 'Routes ServicePrincipalAuth configuration to Set-ServicePrincipalAuth' {
        $config = @{ Method = "ManagedIdentity"; ClientId = "abc" }

        Set-PPModuleConfiguration -Name "ServicePrincipalAuth" -Value $config

        Should -Invoke Set-ServicePrincipalAuth -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { $Configuration.ClientId -eq "abc" }
    }

    It 'Passes a null value through to clear the configuration' {
        { Set-PPModuleConfiguration -Name "ServicePrincipalAuth" -Value $null } | Should -Not -Throw

        Should -Invoke Set-ServicePrincipalAuth -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { $null -eq $Configuration }
    }

    It 'Throws for an unsupported configuration name' {
        { Set-PPModuleConfiguration -Name "SomethingElse" -Value "x" } | Should -Throw "*Unsupported configuration name*"
    }

    It 'Throws when Name is null or empty' {
        { Set-PPModuleConfiguration -Name "" -Value "x" } | Should -Throw
    }
}
