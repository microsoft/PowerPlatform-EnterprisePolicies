<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

function New-RoleAssignment {
    [CmdletBinding(DefaultParameterSetName = 'TenantScope')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PrincipalObjectId,

        [Parameter(Mandatory)]
        [AuthorizationPrincipalType]$PrincipalType,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RoleDefinitionId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory, ParameterSetName = 'EnvironmentScope')]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory, ParameterSetName = 'EnvironmentGroupScope')]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentGroupId,

        [Parameter(Mandatory=$false)]
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod
    )

    # Build the scope and path based on parameter set
    $scope = switch ($PSCmdlet.ParameterSetName) {
        'EnvironmentScope' {
            "/tenants/$TenantId/environments/$EnvironmentId"
        }
        'EnvironmentGroupScope' {
            "/tenants/$TenantId/environmentGroups/$EnvironmentGroupId"
        }
        default {
            "/tenants/$TenantId"
        }
    }

    $path = switch ($PSCmdlet.ParameterSetName) {
        'EnvironmentScope' {
            "authorization/environments/$EnvironmentId/roleAssignments"
        }
        'EnvironmentGroupScope' {
            "authorization/environmentGroups/$EnvironmentGroupId/roleAssignments"
        }
        default {
            "authorization/roleAssignments"
        }
    }

    $query = "api-version=1"

    # Build the request body
    $body = @{
        principalObjectId = $PrincipalObjectId
        principalType = $PrincipalType.ToString()
        scope = $scope
        roleDefinitionId = $RoleDefinitionId
    } | ConvertTo-Json

    Write-Verbose "Creating role assignment at path: $path"
    Write-Verbose "Request body: $body"

    # Build the full URI using global API endpoint
    $baseUrl = Get-APIResourceUrl -Endpoint $Endpoint
    $uri = "$baseUrl$path`?$query"

    Write-Verbose "Request URI: $uri"

    # Get authorization service token
    $accessToken = Get-AuthorizationServiceToken -Endpoint $Endpoint

    # Create and send the request
    $result = Send-RequestWithRetries -MaxRetries 1 -DelaySeconds 5 -RequestFactory {
        New-JsonRequestMessage -Uri $uri -AccessToken $accessToken -Content $body -HttpMethod ([System.Net.Http.HttpMethod]::Post)
    }

    Assert-Result -Result $result

    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()

    if ($contentString) {
        return ($contentString | ConvertFrom-Json)
    }

    return $null
}

function Get-RoleAssignments {
    [CmdletBinding(DefaultParameterSetName = 'TenantScope')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory, ParameterSetName = 'EnvironmentScope')]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory=$false)]
        [bool]$IncludeParentScopes = $false,

        [Parameter(Mandatory=$false)]
        [bool]$ExpandSecurityGroups = $false,

        [Parameter(Mandatory=$false)]
        [bool]$ExpandEnvironmentGroups = $false,

        [Parameter(Mandatory=$false)]
        [bool]$IncludeNestedScopes = $false,

        [Parameter(Mandatory=$false)]
        [AuthorizationPrincipalType]$PrincipalType,

        [Parameter(Mandatory=$false)]
        [string]$PrincipalObjectId,

        [Parameter(Mandatory=$false)]
        [string]$Permission,

        [Parameter(Mandatory=$false)]
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod
    )

    # Build the scope and path based on parameter set
    $scope = switch ($PSCmdlet.ParameterSetName) {
        'EnvironmentScope' {
            "/tenants/$TenantId/environments/$EnvironmentId"
        }
        default {
            "/tenants/$TenantId"
        }
    }

    $path = switch ($PSCmdlet.ParameterSetName) {
        'EnvironmentScope' {
            "authorization/environments/$EnvironmentId/listRoleAssignments"
        }
        default {
            "authorization/listRoleAssignments"
        }
    }

    $query = "api-version=1"

    # Build the request body
    $bodyHash = @{
        Scope = $scope
        IncludeParentScopes = $IncludeParentScopes
        ExpandSecurityGroups = $ExpandSecurityGroups
        ExpandEnvironmentGroups = $ExpandEnvironmentGroups
        IncludeNestedScopes = $IncludeNestedScopes
    }

    if ($PSBoundParameters.ContainsKey('PrincipalType')) {
        $bodyHash['PrincipalType'] = $PrincipalType.ToString()
    }

    if (-not [string]::IsNullOrWhiteSpace($PrincipalObjectId)) {
        $bodyHash['PrincipalObjectId'] = $PrincipalObjectId
    }

    if (-not [string]::IsNullOrWhiteSpace($Permission)) {
        $bodyHash['Permission'] = $Permission
    }

    $body = $bodyHash | ConvertTo-Json

    Write-Verbose "Getting role assignments at path: $path"
    Write-Verbose "Request body: $body"

    # Build the full URI using global API endpoint
    $baseUrl = Get-APIResourceUrl -Endpoint $Endpoint
    $uri = "$baseUrl$path`?$query"

    Write-Verbose "Request URI: $uri"

    # Get authorization service token
    $accessToken = Get-AuthorizationServiceToken -Endpoint $Endpoint

    # Create and send the initial request (POST with body)
    $httpMethod = [System.Net.Http.HttpMethod]::Post
    $result = Send-RequestWithRetries -MaxRetries 1 -DelaySeconds 5 -RequestFactory {
        New-JsonRequestMessage -Uri $uri -AccessToken $accessToken -Content $body -HttpMethod $httpMethod
    }

    Assert-Result -Result $result

    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()

    if (-not $contentString) {
        return $null
    }

    $response = $contentString | ConvertFrom-Json
    $allResults = @()

    # Collect results from first page
    if ($null -ne $response.value) {
        $allResults += $response.value
    }

    # Handle OData pagination - use same HTTP method as original request
    while ($null -ne $response.'@odata.nextLink') {
        $nextLink = $response.'@odata.nextLink'
        Write-Verbose "Fetching next page: $nextLink"

        $result = Send-RequestWithRetries -MaxRetries 1 -DelaySeconds 5 -RequestFactory {
            New-JsonRequestMessage -Uri $nextLink -AccessToken $accessToken -Content $body -HttpMethod $httpMethod
        }

        Assert-Result -Result $result

        $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()

        if (-not $contentString) {
            break
        }

        $response = $contentString | ConvertFrom-Json

        if ($null -ne $response.value) {
            $allResults += $response.value
        }
    }

    return $allResults
}

function Remove-RoleAssignment {
    [CmdletBinding(DefaultParameterSetName = 'TenantScope')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RoleAssignmentId,

        [Parameter(Mandatory, ParameterSetName = 'EnvironmentScope')]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory, ParameterSetName = 'EnvironmentGroupScope')]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentGroupId,

        [Parameter(Mandatory=$false)]
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod
    )

    # Build the path based on parameter set
    $path = switch ($PSCmdlet.ParameterSetName) {
        'EnvironmentScope' {
            "authorization/environments/$EnvironmentId/roleAssignments/$RoleAssignmentId"
        }
        'EnvironmentGroupScope' {
            "authorization/environmentGroups/$EnvironmentGroupId/roleAssignments/$RoleAssignmentId"
        }
        default {
            "authorization/roleAssignments/$RoleAssignmentId"
        }
    }

    $query = "api-version=1"

    Write-Verbose "Removing role assignment at path: $path"

    # Build the full URI using global API endpoint
    $baseUrl = Get-APIResourceUrl -Endpoint $Endpoint
    $uri = "$baseUrl$path`?$query"

    Write-Verbose "Request URI: $uri"

    # Get authorization service token
    $accessToken = Get-AuthorizationServiceToken -Endpoint $Endpoint

    # Create and send the request
    $result = Send-RequestWithRetries -MaxRetries 1 -DelaySeconds 5 -RequestFactory {
        New-JsonRequestMessage -Uri $uri -AccessToken $accessToken -HttpMethod ([System.Net.Http.HttpMethod]::Delete)
    }

    # 200 = deleted, 404 = not found
    if ($result.StatusCode -eq 200) {
        return $true
    }
    elseif ($result.StatusCode -eq 404) {
        return $false
    }

    Assert-Result -Result $result
    return $false
}

function Test-PrincipalPermission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PrincipalObjectId,

        [Parameter(Mandatory)]
        [AuthorizationPrincipalType]$PrincipalType,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Permissions,

        [Parameter(Mandatory=$false)]
        [PPEndpoint]$Endpoint = [PPEndpoint]::Prod
    )

    $scope = "/tenants/$TenantId/environments/$EnvironmentId"
    $path = "authorization/environments/$EnvironmentId/checkPrincipalPermissionForScope"
    $query = "api-version=1"

    # Build the request body
    $body = @{
        PrincipalObjectId = $PrincipalObjectId
        PrincipalType = $PrincipalType.ToString()
        Permissions = $Permissions
        Scope = $scope
    } | ConvertTo-Json

    Write-Verbose "Checking permissions at path: $path"
    Write-Verbose "Request body: $body"

    # Build the full URI using global API endpoint
    $baseUrl = Get-APIResourceUrl -Endpoint $Endpoint
    $uri = "$baseUrl$path`?$query"

    Write-Verbose "Request URI: $uri"

    # Get authorization service token
    $accessToken = Get-AuthorizationServiceToken -Endpoint $Endpoint

    # Create and send the request
    $result = Send-RequestWithRetries -MaxRetries 1 -DelaySeconds 5 -RequestFactory {
        New-JsonRequestMessage -Uri $uri -AccessToken $accessToken -Content $body -HttpMethod ([System.Net.Http.HttpMethod]::Post)
    }

    Assert-Result -Result $result

    $contentString = Get-AsyncResult -Task $result.Content.ReadAsStringAsync()

    if ($contentString) {
        return ($contentString | ConvertFrom-Json)
    }

    return $null
}
