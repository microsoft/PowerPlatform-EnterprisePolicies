<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

function Get-CustomEndpointConfiguration {
    if ($null -ne $script:CustomEndpointConfiguration) {
        return $script:CustomEndpointConfiguration
    }

    $configurationJson = $env:PP_ENTERPRISE_POLICIES_ENDPOINTS
    if ([string]::IsNullOrWhiteSpace($configurationJson)) {
        throw "Custom endpoint configuration is required. Set the PP_ENTERPRISE_POLICIES_ENDPOINTS environment variable."
    }

    try {
        $configuration = $configurationJson | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Custom endpoint configuration is invalid JSON: $($_.Exception.Message)"
    }

    foreach ($propertyName in @("Authority", "Bap", "PowerApps", "Api")) {
        $propertyValue = $configuration.$propertyName
        $uri = $null
        if ([string]::IsNullOrWhiteSpace($propertyValue) -or
            -not [System.Uri]::TryCreate($propertyValue, [System.UriKind]::Absolute, [ref]$uri) -or
            $uri.Scheme -ne [System.Uri]::UriSchemeHttps) {
            throw "Custom endpoint configuration property '$propertyName' must be an absolute HTTPS URL."
        }
    }

    if ($configuration.PSObject.Properties.Name -notcontains "IsSingleCharEndpoint" -or
        $configuration.IsSingleCharEndpoint -isnot [bool]) {
        throw "Custom endpoint configuration property 'IsSingleCharEndpoint' must be a boolean."
    }

    $configuration.Authority = $configuration.Authority.TrimEnd("/")
    foreach ($propertyName in @("Bap", "PowerApps", "Api")) {
        $configuration.$propertyName = "$($configuration.$propertyName.TrimEnd('/'))/"
    }

    $script:CustomEndpointConfiguration = $configuration
    return $script:CustomEndpointConfiguration
}
