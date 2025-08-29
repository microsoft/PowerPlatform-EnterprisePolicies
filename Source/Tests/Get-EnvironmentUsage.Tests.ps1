[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-EnvironmentUsage Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
        $secureString = (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force)
        Mock Get-AccessToken { return $secureString } -ModuleName "EnterprisePolicies"
        Mock Write-Host {}
        Mock Connect-Azure { return $true } -ModuleName "EnterprisePolicies"
    }

    Context 'Testing Get-EnvironmentUsage' {
        It 'Returns usage data for a valid environment' {
            $resultClass = [NetworkUsage]::new()
            $resultClass.AzureRegion = "EastUs"
            $resultJsonString = ($resultClass | ConvertTo-Json)
            $endpoint = [BAPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockClient = [HttpClientMock]::new()
            $mockResult = [HttpClientResultMock]::new($resultJsonString)
            Mock New-HttpClient { return $mockClient } -Verifiable -ModuleName "EnterprisePolicies"
            Mock New-JsonRequestMessage { return "message" } -Verifiable -ModuleName "EnterprisePolicies"
            Mock Get-AsyncResult { return $mockResult } -ParameterFilter { $task -eq "SendAsyncResult" } -Verifiable -ModuleName "EnterprisePolicies"
            Mock Get-AsyncResult { return $resultJsonString } -ParameterFilter { $task -eq $resultJsonString } -Verifiable -ModuleName "EnterprisePolicies"
            
            $result = Get-EnvironmentUsage -Endpoint $endpoint -EnvironmentId $environmentId

            $result.AzureRegion | Should -Be $resultClass.AzureRegion
        }
    }
}