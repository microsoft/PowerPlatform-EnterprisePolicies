param()

BeforeDiscovery{
    . $PSScriptRoot\Shared.ps1
}

Describe 'Set-PPServicePrincipalAuth Tests' {
    BeforeAll {
        Mock Write-Verbose {}
        Mock Set-CachedConfiguration {} -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies"
    }

    It 'Stores a managed identity configuration' {
        Set-PPServicePrincipalAuth -ClientId "mi-client-id" -TenantId "tenant-id"

        Should -Invoke Set-CachedConfiguration -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter {
            $Name -eq "ServicePrincipalAuth" -and $Value.Method -eq "ManagedIdentity" -and $Value.ClientId -eq "mi-client-id" -and $Value.TenantId -eq "tenant-id"
        }
    }

    It 'Stores a certificate configuration using a thumbprint' {
        Set-PPServicePrincipalAuth -ClientId "app-id" -TenantId "tenant-id" -CertificateThumbprint "THUMB123"

        Should -Invoke Set-CachedConfiguration -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter {
            $Name -eq "ServicePrincipalAuth" -and $Value.Method -eq "Certificate" -and $Value.CertificateThumbprint -eq "THUMB123" -and $Value.TenantId -eq "tenant-id"
        }
    }

    It 'Stores a certificate configuration using a subject name' {
        Set-PPServicePrincipalAuth -ClientId "app-id" -TenantId "tenant-id" -CertificateSubjectName "CN=MyCert"

        Should -Invoke Set-CachedConfiguration -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter {
            $Name -eq "ServicePrincipalAuth" -and $Value.Method -eq "Certificate" -and $Value.CertificateSubjectName -eq "CN=MyCert"
        }
    }

    It 'Clears the configuration with -Clear' {
        Set-PPServicePrincipalAuth -Clear

        Should -Invoke Set-CachedConfiguration -Times 1 -ModuleName "Microsoft.PowerPlatform.EnterprisePolicies" -ParameterFilter { $Name -eq "ServicePrincipalAuth" -and $null -eq $Value }
    }

    It 'Requires a client id' {
        { Set-PPServicePrincipalAuth -TenantId "tenant-id" -CertificateThumbprint "THUMB123" } | Should -Throw
    }

    It 'Requires a tenant id for a certificate configuration' {
        { Set-PPServicePrincipalAuth -ClientId "app-id" -CertificateThumbprint "THUMB123" -TenantId "" } | Should -Throw
    }

    It 'Does not allow both a thumbprint and a subject name' {
        { Set-PPServicePrincipalAuth -ClientId "app-id" -TenantId "tenant-id" -CertificateThumbprint "THUMB123" -CertificateSubjectName "CN=MyCert" } | Should -Throw
    }
}
