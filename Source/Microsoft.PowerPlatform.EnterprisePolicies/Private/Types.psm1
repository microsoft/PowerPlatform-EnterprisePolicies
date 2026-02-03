<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>
class CertificateInformation{
    [string] $Issuer
    [string] $Subject
    [string] $SignatureAlgorithm
    [bool] $IsExpired
}

class SSLInformation{
    [string] $Protocols
    [bool] $Success
    [string] $SslErrors
    [string] $CipherSuite
}

class TLSConnectivityInformation{
    [bool] $TCPConnectivity
    [CertificateInformation] $Certificate
    [SSLInformation] $SSLWithoutCRL
    [SSLInformation] $SSLWithCRL
}

class VnetInformation{
    [object] $VnetResource
    [string] $SubnetName

    VnetInformation([object]$VnetResource, [string]$SubnetName) {
        $this.VnetResource = $VnetResource
        $this.SubnetName = $SubnetName
    }
}

class NetworkUsage{
    [string] $AzureRegion
    [string] $EnvironmentId
    [string] $VnetId
    [string] $SubnetName
    [string] $SubnetIpRange
    [string] $ContainerReservedIpCount
    [string[]] $DnsServers
}

class NetworkUsageData{
    [string] $TimeStamp
    [string] $NormalizedTimestamp
    [int] $TotalIpUsage
    [hashtable] $IpAllocations
}

class EnvironmentNetworkUsageDocument{
    [string] $Id
    [string] $EnvironmentId
    [string] $TenantId
    [string] $EnterprisePolicyId
    [string] $VnetId
    [string] $SubnetName
    [int] $SubnetSize
    [string] $AzureRegion
    [NetworkUsageData[]] $NetworkUsageData
}

class SubnetUsageDocument{
    [string] $TenantId
    [string] $EnterprisePolicyId
    [string] $VnetId
    [string] $SubnetName
    [int] $SubnetSize
    [string] $AzureRegion
    [NetworkUsageData[]] $NetworkUsageDataByWorkload
    [NetworkUsageData[]] $NetworkUsageDataByEnvironment
}

enum PolicyType{
    Encryption
    NetworkInjection
    Identity
}

enum BAPEndpoint{
    unknown # Used for defaulting to this value, not meant to be used.
    tip1
    tip2
    prod
    usgovhigh
    dod
    china
}

enum LinkOperation{
    link
    unlink
}

enum AzureEnvironment{
    AzureCloud
    AzureChinaCloud
    AzureUSGovernment
    EastUs2Euap
    CentralUSEuap
}

enum AuthorizationPrincipalType{
    User
    Group
    ApplicationUser
}

enum SubnetInjectionDiagnosticsRole{
    Administrator
    Operator
    Reader
}

enum AuthorizationRole{
    Administrator
    Reader
    Contributor
    Owner
}

# Define the types to export with type accelerators.
$ExportableTypes = @(
    [TLSConnectivityInformation]
    [SSLInformation]
    [CertificateInformation]
    [VnetInformation]
    [PolicyType]
    [BAPEndpoint]
    [LinkOperation]
    [NetworkUsage]
    [AzureEnvironment]
    [NetworkUsageData]
    [EnvironmentNetworkUsageDocument]
    [SubnetUsageDocument]
    [AuthorizationPrincipalType]
    [SubnetInjectionDiagnosticsRole]
    [AuthorizationRole]
)

# Get the internal TypeAccelerators class to use its static methods.
$TypeAcceleratorsClass = [psobject].Assembly.GetType(
    'System.Management.Automation.TypeAccelerators'
)

# Ensure none of the types would clobber an existing type accelerator.
# If a type accelerator with the same name exists, throw an exception.
$ExistingTypeAccelerators = $TypeAcceleratorsClass::Get

foreach ($Type in $ExportableTypes) {
    if($Type.FullName -in $global:ImportedTypes) {
        continue
    }
    if ($Type.FullName -in $ExistingTypeAccelerators.Keys) {
        $Message = @(
            "Unable to register type accelerator '$($Type.FullName)'"
            'Accelerator already exists.'
        ) -join ' - '

        throw [System.Management.Automation.ErrorRecord]::new(
            [System.InvalidOperationException]::new($Message),
            'TypeAcceleratorAlreadyExists',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $Type.FullName
        )
    }
}
# Add type accelerators for every exportable type.
foreach ($Type in $ExportableTypes) {
    if($Type.FullName -in $global:ImportedTypes) {
        continue
    }
    $TypeAcceleratorsClass::Add($Type.FullName, $Type)
    [string[]]$global:ImportedTypes += $Type
}

# Remove type accelerators when the module is removed.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    foreach($Type in $ExportableTypes) {
        $TypeAcceleratorsClass::Remove($Type.FullName)
    }
}.GetNewClosure()