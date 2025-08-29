[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Test-NetworkConnectivity Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
        $secureString = (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force)
        Mock Get-AccessToken { return $secureString } -ModuleName "EnterprisePolicies"
        Mock Write-Host {}
        Mock Connect-Azure { return $true } -ModuleName "EnterprisePolicies"
    }

    Context 'Testing Test-NetworkConnectivity' {
        It 'Returns string with the result of the resolution' {
            $stringResult = "Some string"
            $endpoint = [BAPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockClient = [HttpClientMock]::new()
            $mockResult = [HttpClientResultMock]::new($stringResult)
            Mock New-HttpClient { return $mockClient } -Verifiable -ModuleName "EnterprisePolicies"
            Mock New-JsonRequestMessage { return "message" } -Verifiable -ModuleName "EnterprisePolicies"
            Mock Get-AsyncResult { return $mockResult } -ParameterFilter { $task -eq "SendAsyncResult" } -Verifiable -ModuleName "EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -Verifiable -ModuleName "EnterprisePolicies"
            
            $result = Test-NetworkConnectivity -EnvironmentId $environmentId -Destination "bing.com" -Port 443 -TenantId "0123" -Endpoint $endpoint

            $result | Should -Be $stringResult
        }
    }
}
