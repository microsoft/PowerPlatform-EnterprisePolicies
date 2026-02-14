<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

function Get-RoleDefinitions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod,

        [Parameter(Mandatory=$false)]
        [switch]$RefreshRoles
    )

    # Check shared cache unless refresh is forced
    if (-not $RefreshRoles) {
        $cached = Get-CachedRoleDefinitions -Endpoint $Endpoint.ToString()
        if ($null -ne $cached) {
            Write-Verbose "Returning cached role definitions for endpoint: $Endpoint"
            return $cached
        }
    }

    # Fetch from API
    $baseUrl = Get-APIResourceUrl -Endpoint $Endpoint
    $uri = "${baseUrl}authorization/roleDefinitions?api-version=1"

    Write-Verbose "Fetching role definitions from: $uri"

    $resourceUrl = Get-APIResourceUrl -Endpoint $Endpoint
    $tokenScopes = @("$resourceUrl.default")
    $accessToken = Get-AuthorizationServiceToken -Scopes $tokenScopes

    $result = Send-RequestWithRetries -MaxRetries 1 -DelaySeconds 5 -RequestFactory {
        New-JsonRequestMessage -Uri $uri -AccessToken $accessToken -HttpMethod ([System.Net.Http.HttpMethod]::Get)
    }

    Assert-Result -Result $result

    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()

    if (-not $contentString) {
        throw "Failed to retrieve role definitions from the API."
    }

    $response = $contentString | ConvertFrom-Json
    $roleDefinitions = $response.value

    # Store in shared cache
    Set-CachedRoleDefinitions -Endpoint $Endpoint.ToString() -RoleDefinitions $roleDefinitions

    return $roleDefinitions
}

function Resolve-RoleDefinitionId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RoleName,

        [Parameter(Mandatory=$false)]
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod,

        [Parameter(Mandatory=$false)]
        [switch]$RefreshRoles
    )

    $roleDefinitions = Get-RoleDefinitions -Endpoint $Endpoint -RefreshRoles:$RefreshRoles

    $matchingRole = $roleDefinitions | Where-Object { $_.roleDefinitionName -eq $RoleName }

    if ($null -eq $matchingRole) {
        $availableRoles = ($roleDefinitions | ForEach-Object { $_.roleDefinitionName }) -join ", "
        throw "Role '$RoleName' not found. Available roles: $availableRoles"
    }

    return $matchingRole.roleDefinitionId
}
