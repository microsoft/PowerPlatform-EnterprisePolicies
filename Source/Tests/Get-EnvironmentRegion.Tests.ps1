BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-EnvironmentRegion Tests' {
    BeforeAll {
        Mock Write-Host {}
        Mock Connect-Azure { return $true } -ModuleName "EnterprisePolicies"
        Mock Get-AccessToken { return (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force) } -ModuleName "EnterprisePolicies"
    }

    Context 'Testing Get-EnvironmentRegion' {
        It 'Returns region for a valid environment' {
            $resultClass = [NetworkUsage]::new()
            $resultClass.AzureRegion = "Central US"
            $resultJsonString = ($resultClass | ConvertTo-Json)
            $endpoint = [BAPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockClient = [HttpClientMock]::new()
            $mockResult = [HttpClientResultMock]::new($resultJsonString)
            Mock New-HttpClient { return $mockClient } -Verifiable -ModuleName "EnterprisePolicies"
            Mock New-JsonRequestMessage { return "message" } -Verifiable -ModuleName "EnterprisePolicies"
            Mock Get-AsyncResult { return $mockResult } -ParameterFilter { $task -eq "SendAsyncResult" } -Verifiable -ModuleName "EnterprisePolicies"
            Mock Get-AsyncResult { return $resultJsonString } -ParameterFilter { $task -eq $resultJsonString } -Verifiable -ModuleName "EnterprisePolicies"
            
            $result = Get-EnvironmentRegion -Endpoint $endpoint -EnvironmentId $environmentId

            $result | Should -Be $resultClass.AzureRegion
        }
    }
}