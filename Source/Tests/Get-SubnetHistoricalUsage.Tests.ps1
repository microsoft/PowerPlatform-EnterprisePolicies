[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-SubnetHistoricalUsage Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
        $secureString = (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force)
        Mock Get-PPAPIAccessToken { return $secureString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {}
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Testing Get-SubnetHistoricalUsage' {
        It 'Returns usage data for a valid subnet based on enterprise policy' {
            $resultClass = [SubnetUsageDocument]::new()
            $resultClass.AzureRegion = "EastUs"
            $resultClass.SubnetName = "default"
            $resultJsonString = ($resultClass | ConvertTo-Json)
            $endpoint = [PPEndpoint]::prod
            $tenantId = "e9651b85-8b04-482f-a1e2-3e03421b4398"
            $region = "EastUs"
            $enterprisePolicyId = "d82eb721-3a0d-4c06-bf60-28075e0e9682"
            $mockResult = [HttpClientResultMock]::new($resultJsonString)

            Mock Send-RequestWithRetries { return $mockResult } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-JsonRequestMessage -ParameterFilter { $Query.EndsWith($region) } { return "message" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $mockResult } -ParameterFilter { $task -eq "SendAsyncResult" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $resultJsonString } -ParameterFilter { $task -eq $resultJsonString } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Get-SubnetHistoricalUsage -Endpoint $endpoint -TenantId $tenantId -EnterprisePolicyId $enterprisePolicyId -Region $region

            $result.AzureRegion | Should -Be $resultClass.AzureRegion
            $result.SubnetName | Should -Be $resultClass.SubnetName
        }
    }
}
