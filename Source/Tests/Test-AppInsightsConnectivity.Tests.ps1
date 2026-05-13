[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Unit test code")]
param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Test-AppInsightsConnectivity Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
        $secureString = (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force)
        Mock Get-PPAPIAccessToken { return $secureString } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Host {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Write-Warning {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        Mock Connect-Azure { return $true } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

        $script:connectionString = "InstrumentationKey=00000000-0000-0000-0000-000000000000;IngestionEndpoint=https://westus-0.in.applicationinsights.azure.com/"
        $script:environmentId = "3496a854-39b3-41bd-a783-1f2479ca3fbd"
        $script:endpoint = [PPEndpoint]::prod
        $script:region = "westus"
    }

    Context 'Testing Test-AppInsightsConnectivity' {
        It 'Returns ApplicationInsightsInformation when connectivity succeeds without a message' {
            $stringResult = '{"ConnectionStringValid":true,"TestMessageSent":false,"ErrorMessage":null,"ContainerIpAddress":"10.1.2.3"}'
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-AppInsightsConnectivity -EnvironmentId $script:environmentId -ConnectionString $script:connectionString -Endpoint $script:endpoint -Region $script:region

            $result | Should -BeOfType [ApplicationInsightsInformation]
            $result.ConnectionStringValid | Should -BeTrue
            Should -Not -Invoke Write-Warning -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }

        It 'Sends Message in the request body when supplied' {
            $stringResult = '{"ConnectionStringValid":true,"TestMessageSent":true,"ErrorMessage":null,"ContainerIpAddress":"10.1.2.3"}'
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")
            $script:capturedContent = $null

            Mock Send-RequestWithRetries {
                $null = & $RequestFactory
                return $mockResult
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-EnvironmentRouteRequest {
                $script:capturedContent = $Content
                return "request"
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $null = Test-AppInsightsConnectivity -EnvironmentId $script:environmentId -ConnectionString $script:connectionString -Message "hello" -Endpoint $script:endpoint -Region $script:region

            $script:capturedContent | Should -Match '"Message"\s*:\s*"hello"'
        }

        It 'Sends an empty Message in the request body when not supplied' {
            $stringResult = '{"ConnectionStringValid":true,"TestMessageSent":false,"ErrorMessage":null,"ContainerIpAddress":"10.1.2.3"}'
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")
            $script:capturedContent = $null

            Mock Send-RequestWithRetries {
                $null = & $RequestFactory
                return $mockResult
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock New-EnvironmentRouteRequest {
                $script:capturedContent = $Content
                return "request"
            } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $null = Test-AppInsightsConnectivity -EnvironmentId $script:environmentId -ConnectionString $script:connectionString -Endpoint $script:endpoint -Region $script:region

            $script:capturedContent | Should -Match '"Message"\s*:\s*""'
        }

        It 'Warns when the connection string is invalid' {
            $stringResult = '{"ConnectionStringValid":false,"TestMessageSent":false,"ErrorMessage":"Malformed connection string","ContainerIpAddress":"10.1.2.3"}'
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $result = Test-AppInsightsConnectivity -EnvironmentId $script:environmentId -ConnectionString "garbage" -Endpoint $script:endpoint -Region $script:region

            $result.ConnectionStringValid | Should -BeFalse
            Should -Invoke Write-Warning -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { $Message -like "*connection string is invalid*" }
        }

        It 'Auto-resolves region when not provided' {
            $stringResult = '{"ConnectionStringValid":true,"TestMessageSent":false,"ErrorMessage":null,"ContainerIpAddress":"10.1.2.3"}'
            $mockResult = [HttpClientResultMock]::new($stringResult, "application/json")

            Mock Send-RequestWithRetries { return $mockResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-AsyncResult { return $stringResult } -ParameterFilter { $task -eq $stringResult } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
            Mock Get-EnvironmentRegionFromCache { return "westus" } -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"

            $null = Test-AppInsightsConnectivity -EnvironmentId $script:environmentId -ConnectionString $script:connectionString -Endpoint $script:endpoint

            Should -Invoke Get-EnvironmentRegionFromCache -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
        }
    }
}
