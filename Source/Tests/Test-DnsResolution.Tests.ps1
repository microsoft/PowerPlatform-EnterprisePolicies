[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Test-DnsResolution Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
        $secureString = (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force)
        Mock Get-PPAPIAccessToken { return $secureString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {}
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Testing Test-DnsResolution' {
        It 'Returns string with the DNS resolution result' {
            $stringResult = "Some string"
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $region = "westus"
            $mockResult = [HttpClientResultMock]::new($stringResult)

            Mock Send-RequestWithRetries { return $mockResult } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-JsonRequestMessage -ParameterFilter { $Query.EndsWith($region) } { return "message" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $mockResult } -ParameterFilter { $task -eq "SendAsyncResult" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            
            $result = Test-DnsResolution -EnvironmentId $environmentId -HostName "bing.com" -Endpoint $endpoint -Region $region

            $result | Should -Be $stringResult
        }

        It 'Returns string with the DNS resolution with json result' {
            $stringResult = '"Some json string"'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $region = "westus"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")

            Mock Send-RequestWithRetries { return $mockResult } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-JsonRequestMessage -ParameterFilter { $Query.EndsWith($region) } { return "message" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $mockResult } -ParameterFilter { $task -eq "SendAsyncResult" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            
            $result = Test-DnsResolution -EnvironmentId $environmentId -HostName "bing.com" -Endpoint $endpoint -Region $region

            $result | Should -Be "Some json string"
        }
    }
}
