[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Test-DnsResolution Tests' {
    BeforeAll {
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Testing Test-DnsResolution' {
        It 'Returns true if wid is present' {
            $payload = [ordered]@{
                sub = "1234567890"
                name = "Test"
                iat = [int][double]::Parse((Get-Date -Date (Get-Date).ToUniversalTime() -UFormat %s))
                exp = [DateTimeOffset]::UtcNow.AddHours(1)
                iss = "https://issuer.example"
                aud = "api://your-audience"
                wids = @("11648597-926c-4cf3-9c36-bcebb0ba8dcc")
            }

            $token = "ey.$([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json))).TrimEnd('=') -replace '\+','-' -replace '/','_').ey"

            $secureString = (ConvertTo-SecureString $token -AsPlainText -Force)
            Mock Get-PPAPIAccessToken { return $secureString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            
            Test-AccountPermissions | Should -Be $true
        }

        It 'Returns false if wid is not present' {
            $payload = [ordered]@{
                sub = "1234567890"
                name = "Test"
                iat = [int][double]::Parse((Get-Date -Date (Get-Date).ToUniversalTime() -UFormat %s))
                exp = [DateTimeOffset]::UtcNow.AddHours(1)
                iss = "https://issuer.example"
                aud = "api://your-audience"
                wids = @("b79fbf4d-3ef9-4689-8143-76b194e85509")
            }

            $token = "ey.$([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json))).TrimEnd('=') -replace '\+','-' -replace '/','_').ey"

            $secureString = (ConvertTo-SecureString $token -AsPlainText -Force)
            Mock Get-PPAPIAccessToken { return $secureString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            
            Test-AccountPermissions | Should -Be $false
        }

        It 'Returns false if no wids are present' {
            $payload = [ordered]@{
                sub = "1234567890"
                name = "Test"
                iat = [int][double]::Parse((Get-Date -Date (Get-Date).ToUniversalTime() -UFormat %s))
                exp = [DateTimeOffset]::UtcNow.AddHours(1)
                iss = "https://issuer.example"
                aud = "api://your-audience"
            }

            $token = "ey.$([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json))).TrimEnd('=') -replace '\+','-' -replace '/','_').ey"

            $secureString = (ConvertTo-SecureString $token -AsPlainText -Force)
            Mock Get-PPAPIAccessToken { return $secureString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            
            Test-AccountPermissions | Should -Be $false
        }
    }
}
