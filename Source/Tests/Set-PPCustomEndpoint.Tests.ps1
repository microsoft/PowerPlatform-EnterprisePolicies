BeforeDiscovery {
    . $PSScriptRoot\Shared.ps1
}

Describe 'Set-PPCustomEndpoint Tests' {
    InModuleScope 'Microsoft.PowerPlatform.EnterprisePolicies' {
        BeforeAll {
            $script:originalCacheData = $script:CacheData
            $script:originalAuthorizationServiceCache = $script:AuthorizationServiceCache
            $script:originalAuthorizationServiceCurrentKey = $script:AuthorizationServiceCurrentKey
        }

        AfterAll {
            $script:CacheData = $script:originalCacheData
            $script:AuthorizationServiceCache = $script:originalAuthorizationServiceCache
            $script:AuthorizationServiceCurrentKey = $script:originalAuthorizationServiceCurrentKey
        }

        BeforeEach {
            Mock Save-Cache {}
            $script:CacheData = Get-EmptyCache
            $script:AuthorizationServiceCache = @{}
            $script:AuthorizationServiceCurrentKey = $null
            $parameters = @{
                Name = "ussec"
                Authority = "https://login.sec.example"
                PPEndpoint = "https://bap.sec.example"
                PPResource = "https://apps.sec.example"
                PPAPI = "https://api.sec.example"
            }
        }

        It 'Adds a complete endpoint that the URL helpers can use' {
            Set-PPCustomEndpoint @parameters

            @(Get-CachedConfiguration -Name "CustomEndpoints").Count | Should -Be 1
            $endpoint = Get-CachedEndpoint -EndpointName "ussec"
            $endpoint.Authority | Should -Be $parameters.Authority
            Get-PPEndpointUrl -Endpoint ([PPEndpoint]::ussec) | Should -Be "$($parameters.PPEndpoint)/"
            Get-PPResourceUrl -Endpoint ([PPEndpoint]::ussec) | Should -Be "$($parameters.PPResource)/"
            Get-APIResourceUrl -Endpoint ([PPEndpoint]::ussec) | Should -Be "$($parameters.PPAPI)/"
            Should -Invoke Save-Cache -Times 1 -Exactly
        }

        It 'Replaces the named endpoint case-insensitively and preserves other entries' {
            Set-PPCustomEndpoint @parameters
            $parameters.Name = "usnat"
            Set-PPCustomEndpoint @parameters
            $parameters.Name = "USSEC"
            $parameters.Authority = "https://login.updated.example"

            Set-PPCustomEndpoint @parameters

            @(Get-CachedConfiguration -Name "CustomEndpoints").Count | Should -Be 2
            (Get-CachedEndpoint -EndpointName "ussec").Authority | Should -Be "https://login.updated.example"
            (Get-CachedEndpoint -EndpointName "usnat").Authority | Should -Be "https://login.sec.example"
        }

        It 'Clears only the updated endpoints cached authentication clients' {
            $script:AuthorizationServiceCache = @{
                'ussec|tenant|client' = @{}
                'ussec|other-tenant|client' = @{}
                'usnat|tenant|client' = @{}
            }
            $script:AuthorizationServiceCurrentKey = 'ussec|tenant|client'

            Set-PPCustomEndpoint @parameters

            $script:AuthorizationServiceCache.Count | Should -Be 1
            $script:AuthorizationServiceCache.ContainsKey('usnat|tenant|client') | Should -Be $true
            $script:AuthorizationServiceCurrentKey | Should -BeNullOrEmpty
        }

        It 'Rejects invalid <PropertyName> before changing cached configuration' -TestCases @(
            @{ PropertyName = 'Authority'; InvalidUrl = 'http://login.sec.example' }
            @{ PropertyName = 'PPEndpoint'; InvalidUrl = '/relative' }
            @{ PropertyName = 'PPResource'; InvalidUrl = 'https://user:password@apps.sec.example' }
            @{ PropertyName = 'PPAPI'; InvalidUrl = 'https://api.sec.example?query=1' }
            @{ PropertyName = 'PPAPI'; InvalidUrl = 'https://api.sec.example#fragment' }
        ) {
            param($PropertyName, $InvalidUrl)
            $parameters[$PropertyName] = $InvalidUrl

            { Set-PPCustomEndpoint @parameters } | Should -Throw "*$PropertyName must be an absolute HTTPS URL*"

            Get-CachedConfiguration -Name "CustomEndpoints" | Should -BeNullOrEmpty
            Should -Invoke Save-Cache -Times 0
        }

        It 'Rejects a name that is not a custom cloud endpoint' {
            $parameters.Name = "prod"

            { Set-PPCustomEndpoint @parameters } | Should -Throw

            Should -Invoke Save-Cache -Times 0
        }

        It 'Propagates persistence failures without clearing authentication clients' {
            Mock Save-Cache { throw "Cannot save configuration" }
            $script:AuthorizationServiceCache['ussec|tenant|client'] = @{}

            { Set-PPCustomEndpoint @parameters } | Should -Throw "*Cannot save configuration*"

            $script:AuthorizationServiceCache.ContainsKey('ussec|tenant|client') | Should -Be $true
        }
    }
}
