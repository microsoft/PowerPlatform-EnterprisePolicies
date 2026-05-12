[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Test-AppInsightsConnection Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
        $secureString = (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force)
        Mock Get-PPAPIAccessToken { return $secureString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Warning {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

        $script:connectionString = "InstrumentationKey=00000000-0000-0000-0000-000000000000;IngestionEndpoint=https://westus-0.in.applicationinsights.azure.com/"
    }

    Context 'Testing Test-AppInsightsConnection' {
        It 'Returns ApplicationInsightsInformation when the test event is sent' {
            $stringResult = '{"ConnectionStringValid":true,"TestMessageSent":true,"ErrorMessage":null,"ContainerIpAddress":"10.1.2.3"}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")
            $region = "westus"

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-JsonRequestMessage -ParameterFilter { $Query.EndsWith($region) } { return "message" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-AppInsightsConnection -EnvironmentId $environmentId -ConnectionString $script:connectionString -Message "hello" -Endpoint $endpoint -Region $region

            $result | Should -BeOfType [ApplicationInsightsInformation]
            $result.ConnectionStringValid | Should -BeTrue
            $result.TestMessageSent | Should -BeTrue
            Should -Not -Invoke Write-Warning -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Warns when the connection string is invalid' {
            $stringResult = '{"ConnectionStringValid":false,"TestMessageSent":false,"ErrorMessage":"Malformed connection string","ContainerIpAddress":"10.1.2.3"}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")
            $region = "westus"

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-AppInsightsConnection -EnvironmentId $environmentId -ConnectionString "garbage" -Message "hello" -Endpoint $endpoint -Region $region

            $result | Should -BeOfType [ApplicationInsightsInformation]
            $result.ConnectionStringValid | Should -BeFalse
            Should -Invoke Write-Warning -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { $Message -like "*connection string is invalid*" }
        }

        It 'Warns when the test event cannot be sent despite a valid connection string' {
            $stringResult = '{"ConnectionStringValid":true,"TestMessageSent":false,"ErrorMessage":"Ingestion endpoint timed out","ContainerIpAddress":"10.1.2.3"}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")
            $region = "westus"

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-AppInsightsConnection -EnvironmentId $environmentId -ConnectionString $script:connectionString -Message "hello" -Endpoint $endpoint -Region $region

            $result | Should -BeOfType [ApplicationInsightsInformation]
            $result.ConnectionStringValid | Should -BeTrue
            $result.TestMessageSent | Should -BeFalse
            Should -Invoke Write-Warning -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { $Message -like "*could not be sent*" }
        }

        It 'Auto-resolves region when not provided' {
            $stringResult = '{"ConnectionStringValid":true,"TestMessageSent":true,"ErrorMessage":null,"ContainerIpAddress":"10.1.2.3"}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnvironmentRegionFromCache { return "westus" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $null = Test-AppInsightsConnection -EnvironmentId $environmentId -ConnectionString $script:connectionString -Message "hello" -Endpoint $endpoint

            Should -Invoke Get-EnvironmentRegionFromCache -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Returns raw string when JSON deserialization fails' {
            $stringResult = '{"unexpectedFormat": true}'
            $endpoint = [PPEndpoint]::prod
            $environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")
            $region = "westus"

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock ConvertFrom-JsonToClass { throw "Deserialization failed" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-AppInsightsConnection -EnvironmentId $environmentId -ConnectionString $script:connectionString -Message "hello" -Endpoint $endpoint -Region $region

            $result | Should -Be $stringResult
        }
    }
}
