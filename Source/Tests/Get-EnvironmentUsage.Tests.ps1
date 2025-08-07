BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-EnvironmentUsage Tests' {
    BeforeAll {
        Mock Write-Host {}
        Mock Connect-Azure { return $true }
        Mock Get-AccessToken { return "mocked_token" }
    }

    Context 'Testing Get-EnvironmentUsage' {
        It 'Returns usage data for a valid environment' {
            $stringResult = "0 IPs in use"
            $endpoint = [BAPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockClient = [HttpClientMock]::new()
            $mockResult = [HttpClientResultMock]::new($stringResult)
            Mock New-HttpClient { return $mockClient } -Verifiable
            Mock New-JsonRequestMessage { return "message" } -Verifiable
            Mock Get-AsyncResult { return $mockResult } -ParameterFilter { $task -eq "SendAsyncResult" } -Verifiable
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -Verifiable
            
            $result = & $PSScriptRoot\..\SubnetInjection\Diagnostics\Get-EnvironmentUsage.ps1 -Endpoint $endpoint -EnvironmentId $environmentId

            $result | Should -Be $stringResult
        }
    }
}