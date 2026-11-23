[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery {
    . $PSScriptRoot\Shared.ps1
}

Describe 'Reset-EnvironmentDelegation Tests' {
    BeforeAll {
        $script:environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
        $script:tenantId = "12345678-1234-1234-1234-123456789012"
        $script:secureString = ConvertTo-SecureString "TestToken" -AsPlainText -Force
    }

    BeforeEach {
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Get-EnvironmentRegionFromCache { return "eastus" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Get-PPAPIAccessToken { return $script:secureString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Send-Request {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    It 'Returns true after sending a bodyless reset POST with the supplied region' {
        $result = Reset-EnvironmentDelegation -EnvironmentId $script:environmentId -Region "westus"

        $result | Should -BeTrue
        Should -Invoke Get-EnvironmentRegionFromCache -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Should -Invoke Send-Request -Times 1 -Exactly -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter {
            $Request.Method -eq [System.Net.Http.HttpMethod]::Post -and
            $Request.RequestUri.AbsolutePath -eq "/plex/resetDelegation" -and
            $Request.RequestUri.Query -eq "?region=westus" -and
            $null -eq $Request.Content
        }
    }

    It 'Uses the resolved environment region when region is omitted' {
        $result = Reset-EnvironmentDelegation -EnvironmentId $script:environmentId -Endpoint usgovhigh -TenantId $script:tenantId

        $result | Should -BeTrue
        Should -Invoke Get-EnvironmentRegionFromCache -Times 1 -Exactly -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter {
            $EnvironmentId -eq $script:environmentId -and $Endpoint -eq [PPEndpoint]::usgovhigh -and $TenantId -eq $script:tenantId
        }
        Should -Invoke Send-Request -Times 1 -Exactly -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter {
            $Request.RequestUri.Query -eq "?region=eastus"
        }
    }

    It 'Does not authenticate or send a request with WhatIf when region is omitted' {
        Reset-EnvironmentDelegation -EnvironmentId $script:environmentId -WhatIf

        Should -Invoke Connect-Azure -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Should -Invoke Get-EnvironmentRegionFromCache -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Should -Invoke Send-Request -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    It 'Does not send the reset when region lookup fails' {
        Mock Get-EnvironmentRegionFromCache { throw "Region lookup failed" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

        { Reset-EnvironmentDelegation -EnvironmentId $script:environmentId } | Should -Throw "*Region lookup failed*"
        Should -Invoke Send-Request -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    It 'Does not send the reset when region lookup returns no region' {
        Mock Get-EnvironmentRegionFromCache { return "" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

        { Reset-EnvironmentDelegation -EnvironmentId $script:environmentId } | Should -Throw "*Failed to resolve the environment region*"
        Should -Invoke Send-Request -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    It 'Stops without sending a request when authentication fails' {
        Mock Connect-Azure { return $false } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

        { Reset-EnvironmentDelegation -EnvironmentId $script:environmentId -Region "westus" } | Should -Throw "*Failed to connect to Azure*"
        Should -Invoke Send-Request -Times 0 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    It 'Surfaces <Failure> without retrying' -ForEach @(
        @{ Failure = "service errors"; Message = "Reset delegation denied" }
        @{ Failure = "concurrent-usage guidance"; Message = "Failed to reset network for environment '3496a854-39b3-41bd-a783-1f2479ca3fbd' due to concurrent usage. Please retry. If this persists, pause calls to subnet delegation workloads." }
    ) {
        Mock Send-Request { throw $Message } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

        { Reset-EnvironmentDelegation -EnvironmentId $script:environmentId -Region "westus" } | Should -Throw -ExpectedMessage $Message
        Should -Invoke Send-Request -Times 1 -Exactly -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }
}
