[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-EnvironmentHistoricalUsage Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
        $secureString = (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force)
        Mock Get-AccessToken { return $secureString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {}
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Testing Get-EnvironmentHistoricalUsage' {
        It 'Returns usage data for a valid environment' {
            $resultClass = [EnvironmentNetworkUsageDocument]::new()
            $resultClass.AzureRegion = "EastUs"
            $resultClass.SubnetName = "default"
            $resultJsonString = ($resultClass | ConvertTo-Json)
            $endpoint = [BAPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $region = "EastUs"
            $mockClient = [HttpClientMock]::new()
            $mockResult = [HttpClientResultMock]::new($resultJsonString)
            Mock New-HttpClient { return $mockClient } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-JsonRequestMessage { return "message" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $mockResult } -ParameterFilter { $task -eq "SendAsyncResult" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $resultJsonString } -ParameterFilter { $task -eq $resultJsonString } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            
            $result = Get-EnvironmentHistoricalUsage -Endpoint $endpoint -EnvironmentId $environmentId -Region $region

            $result.AzureRegion | Should -Be $resultClass.AzureRegion
            $result.SubnetName | Should -Be $resultClass.SubnetName
        }
    }
}