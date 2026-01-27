---
document type: module
Help Version: 1.0.0.0
HelpInfoUri: 
Locale: en-US
Module Guid: fce8ece4-09c1-4455-9253-c68b6c2ea4d6
Module Name: Microsoft.PowerPlatform.EnterprisePolicies
ms.date: 01/26/2026
PlatyPS schema version: 2024-05-01
title: Microsoft.PowerPlatform.EnterprisePolicies Module
---

# Microsoft.PowerPlatform.EnterprisePolicies Module

## Description

Microsoft PowerPlatform Enterprise policies module

## Microsoft.PowerPlatform.EnterprisePolicies

### [Get-EnvironmentHistoricalUsage](Get-EnvironmentHistoricalUsage.md)

Retrieves the historical network usage of the specified environment.

### [Get-EnvironmentRegion](Get-EnvironmentRegion.md)

Retrieves the region that the specified environment is deployed in.

### [Get-EnvironmentUsage](Get-EnvironmentUsage.md)

Retrieves the current usage of the specified environment.

### [Get-SubnetInjectionEnterprisePolicy](Get-SubnetInjectionEnterprisePolicy.md)

Retrieves Subnet Injection Enterprise Policies for Power Platform.

### [New-SubnetInjectionEnterprisePolicy](New-SubnetInjectionEnterprisePolicy.md)

Creates a new Subnet Injection Enterprise Policy for Power Platform.

### [New-VnetForSubnetDelegation](New-VnetForSubnetDelegation.md)

Creates a new virtual network and subnet with Microsoft.PowerPlatform/enterprisePolicies delegation, or configures an existing VNet/subnet.

### [Test-AccountPermissions](Test-AccountPermissions.md)

Validates that the account has the correct permissions to run diagnostic commands.

### [Test-DnsResolution](Test-DnsResolution.md)

Tests the DNS resolution for a given hostname in a specified environment.

### [Test-NetworkConnectivity](Test-NetworkConnectivity.md)

Tests the connectivity to a given service in a specified environment.

### [Test-TLSHandshake](Test-TLSHandshake.md)

Attempts to establish a TLS handshake with the provided destination and port.

## Types

### Classes

#### [EnvironmentNetworkUsageDocument](EnvironmentNetworkUsageDocument.md)

The EnvironmentNetworkUsageDocument class represents historical network usage information and network usage metadata about the delegated network of a Power Platform environment.

#### [NetworkUsage](NetworkUsage.md)

The NetworkUsage class represents metadata about the network configuration of a Power Platform environment.

#### [TLSConnectivityInformation](TLSConnectivityInformation.md)

A class representing the result of the TLS handshake.

#### [SSLInformation](SSLInformation.md)

The SSLInformation class contains detailed information on the TLS handshake attempt.

#### [CertificateInformation](CertificateInformation.md)

The CertificateInformation class contains detailed information about the certificate presented during the TLS handshake.

#### [NetworkUsageData](NetworkUsageData.md)

The NetworkUsageData class represents historical network usage information about the network configuration of a Power Platform environment.

#### [SubnetUsageDocument](SubnetUsageDocument.md)

The SubnetUsageDocument class represents historical network usage information and network usage metadata of a subnet delegated to one or more power platform environments.

#### [EnterprisePolicy](EnterprisePolicy-Types.md)

The EnterprisePolicy class represents an Azure ARM Enterprise Policy resource returned by cmdlets like Get-SubnetInjectionEnterprisePolicy.

#### [EnterprisePolicyProperties](EnterprisePolicy-Types.md)

The EnterprisePolicyProperties class contains policy-specific properties including system ID, health status, and network injection configuration.

#### [NetworkInjectionProperties](EnterprisePolicy-Types.md)

The NetworkInjectionProperties class contains the virtual network configuration for Network Injection Enterprise Policies.

#### [VirtualNetworkReference](EnterprisePolicy-Types.md)

The VirtualNetworkReference class represents a reference to an Azure Virtual Network and its delegated subnet.

#### [SubnetReference](EnterprisePolicy-Types.md)

The SubnetReference class represents a reference to a subnet within a virtual network.

### Enums

#### [AzureEnvironment](AzureEnvironment.md)

Represents the different Azure environments that can be used to connect to Azure services. Only environments that are currently supported are included.

#### [BAPEndpoint](BAPEndpoint.md)

Represents the different BAP endpoints that can be used to connect to Power Platform services. Only endpoints that are currently supported are included.
