BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Test-DnsResolution Tests' {
    BeforeAll {
        Mock Write-Host {}
        Mock Connect-Azure { return $true } -ModuleName "EnterprisePolicies"
        Mock Get-AccessToken { return "mocked_token" } -ModuleName "EnterprisePolicies"
    }

    Context 'Testing Test-DnsResolution' {
        It 'Returns string with the DNS resolution result' {
            $stringResult = "0 IPs in use"
            $endpoint = [BAPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockClient = [HttpClientMock]::new()
            $mockResult = [HttpClientResultMock]::new($stringResult)
            Mock New-HttpClient { return $mockClient } -Verifiable -ModuleName "EnterprisePolicies"
            Mock New-JsonRequestMessage { return "message" } -Verifiable -ModuleName "EnterprisePolicies"
            Mock Get-AsyncResult { return $mockResult } -ParameterFilter { $task -eq "SendAsyncResult" } -Verifiable -ModuleName "EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -Verifiable -ModuleName "EnterprisePolicies"
            
            $result = Get-EnvironmentUsage -Endpoint $endpoint -EnvironmentId $environmentId

            $result | Should -Be $stringResult
        }
    }
}
