BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1 -Module
}

Describe 'EndpointConfiguration Tests' {
    InModuleScope 'Microsoft.PowerPlatform.EnterprisePolicies' {
        BeforeEach {
            $script:CustomEndpointConfiguration = $null
            Remove-Item Env:PP_ENTERPRISE_POLICIES_ENDPOINTS -ErrorAction SilentlyContinue
        }

        AfterAll {
            $script:CustomEndpointConfiguration = $null
            Remove-Item Env:PP_ENTERPRISE_POLICIES_ENDPOINTS -ErrorAction SilentlyContinue
        }

        It 'Loads and normalizes valid custom endpoint configuration' {
            $env:PP_ENTERPRISE_POLICIES_ENDPOINTS = @{
                Authority = "https://login.example.test/"
                Bap = "https://bap.example.test"
                PowerApps = "https://service.example.test"
                Api = "https://api.example.test"
                IsSingleCharEndpoint = $true
            } | ConvertTo-Json -Compress

            $result = Get-CustomEndpointConfiguration

            $result.Authority | Should -Be "https://login.example.test"
            $result.Bap | Should -Be "https://bap.example.test/"
            $result.PowerApps | Should -Be "https://service.example.test/"
            $result.Api | Should -Be "https://api.example.test/"
            $result.IsSingleCharEndpoint | Should -BeTrue
        }

        It 'Throws when custom endpoint configuration is missing' {
            { Get-CustomEndpointConfiguration } |
                Should -Throw "*PP_ENTERPRISE_POLICIES_ENDPOINTS*"
        }

        It 'Rejects non-HTTPS custom endpoint URLs' {
            $env:PP_ENTERPRISE_POLICIES_ENDPOINTS = @{
                Authority = "https://login.example.test"
                Bap = "https://bap.example.test"
                PowerApps = "https://service.example.test"
                Api = "http://api.example.test"
                IsSingleCharEndpoint = $true
            } | ConvertTo-Json -Compress

            { Get-CustomEndpointConfiguration } |
                Should -Throw "*'Api' must be an absolute HTTPS URL*"
        }

        It 'Requires the route partition setting' {
            $env:PP_ENTERPRISE_POLICIES_ENDPOINTS = @{
                Authority = "https://login.example.test"
                Bap = "https://bap.example.test"
                PowerApps = "https://service.example.test"
                Api = "https://api.example.test"
            } | ConvertTo-Json -Compress

            { Get-CustomEndpointConfiguration } |
                Should -Throw "*'IsSingleCharEndpoint' must be a boolean*"
        }
    }
}
