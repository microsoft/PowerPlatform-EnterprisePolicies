param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-PPModuleConfiguration Tests' {
    It 'Returns the whole configuration container when no name is provided' {
        Mock Get-CachedConfiguration { return [PSCustomObject]@{ Foo = "Bar" } } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

        $result = Get-PPModuleConfiguration

        $result.Foo | Should -Be "Bar"
        Should -Invoke Get-CachedConfiguration -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { [string]::IsNullOrWhiteSpace($Name) }
    }

    It 'Returns a single value when a name is provided' {
        Mock Get-CachedConfiguration { return "SomeValue" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { $Name -eq "MySetting" }

        Get-PPModuleConfiguration -Name "MySetting" | Should -Be "SomeValue"

        Should -Invoke Get-CachedConfiguration -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { $Name -eq "MySetting" }
    }
}
