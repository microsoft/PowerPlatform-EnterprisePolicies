BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1 -Module
}

Describe 'RESTHelpers Tests' {
    InModuleScope 'Microsoft.PowerPlatform.EnterprisePolicies'{
        BeforeAll{
            Mock Write-Host {}
        }
        
        Context 'Testing Get-APIResourceUrl' {
            It 'Throws an error for unsupported endpoint' {
                { Get-APIResourceUrl -Endpoint ([BAPEndpoint]::unknown) } | Should -Throw "Unsupported BAP endpoint: unknown"
            }
    
            It 'Returns the correct resource URL for a valid endpoint' {
                $result = Get-APIResourceUrl -Endpoint ([BAPEndpoint]::prod)
                $result | Should -Be "https://api.powerplatform.com/"
            }
        }
    
        Context 'Testing Get-EnvironmentRoute' {
            It 'Returns the correct route for TIP1 endpoint' {
                $result = Get-EnvironmentRoute -EnvironmentId "12345678-1234-1234-1234-123456789012" -Endpoint ([BAPEndpoint]::tip1)
                $result | Should -Be "https://1234567812341234123412345678901.2.environment.api.preprod.powerplatform.com"
            }
    
            It 'Returns the correct route for PROD endpoint' {
                $result = Get-EnvironmentRoute -EnvironmentId "3496a854-39b3-41bd-a783-1f2479ca3fbd" -Endpoint ([BAPEndpoint]::prod)
                $result | Should -Be "https://3496a85439b341bda7831f2479ca3f.bd.environment.api.powerplatform.com"
            }
    
            It 'Returns the correct route when EnvironmentId is not a Guid' {
                $result = Get-EnvironmentRoute -EnvironmentId "Default3496a854-39b3-41bd-a783-1f2479ca3fbd" -Endpoint ([BAPEndpoint]::prod)
                $result | Should -Be "https://Default3496a85439b341bda7831f2479ca3f.bd.environment.api.powerplatform.com"
            }
        }
    }
}