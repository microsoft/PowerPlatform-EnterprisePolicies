[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Test-NetworkConnectivity Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
        $secureString = (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force)
        Mock Get-PPAPIAccessToken { return $secureString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {}
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Testing Test-NetworkConnectivity' {
        It 'Returns string with the result of the resolution' {
            $stringResult = "Some string"
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult)
            $region = "westus"

            Mock Send-RequestWithRetries { return $mockResult } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-JsonRequestMessage -ParameterFilter { $Query.EndsWith($region) } { return "message" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $mockResult } -ParameterFilter { $task -eq "SendAsyncResult" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            
            $result = Test-NetworkConnectivity -EnvironmentId $environmentId -Destination "bing.com" -Port 443 -TenantId "0123" -Endpoint $endpoint -Region $region

            $result | Should -Be $stringResult
        }

        It 'Returns string with the json result of the resolution' {
            $stringResult = '"Some json string"'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")
            $region = "westus"

            Mock Send-RequestWithRetries { return $mockResult } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-JsonRequestMessage -ParameterFilter { $Query.EndsWith($region) } { return "message" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $mockResult } -ParameterFilter { $task -eq "SendAsyncResult" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            
            $result = Test-NetworkConnectivity -EnvironmentId $environmentId -Destination "bing.com" -Port 443 -TenantId "0123" -Endpoint $endpoint -Region $region

            $result | Should -Be 'Some json string'
        }
    }
}
