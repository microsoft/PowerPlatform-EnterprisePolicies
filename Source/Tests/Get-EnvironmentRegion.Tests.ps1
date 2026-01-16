[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-EnvironmentRegion Tests' {
    BeforeAll {
        $secureString = (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force)
        Mock Get-AccessToken { return $secureString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {}
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    Context 'Testing Get-EnvironmentRegion' {
        It 'Returns region for a valid environment' {
            $regionString = '"Central US"'
            $endpoint = [BAPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($regionString)
            $httpClientMock = [HttpClientMock]::new()

            Mock Get-HttpClient { return $httpClientMock } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $mockResult } -ParameterFilter { $task -eq "SendAsyncResult" } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $regionString } -ParameterFilter { $task -eq $regionString } -Verifiable -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Get-EnvironmentRegion -Endpoint $endpoint -EnvironmentId $environmentId

            $result | Should -Be "Central US"
        }
    }
}