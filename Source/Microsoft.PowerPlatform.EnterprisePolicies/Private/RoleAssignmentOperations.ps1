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
        [BAPEndpoint]$Endpoint = [BAPEndpoint]::Prod
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

    # Determine the scope for token acquisition based on endpoint
    $resourceUrl = Get-APIResourceUrl -Endpoint $Endpoint
    $tokenScopes = @("$resourceUrl.default")

    # Get authorization service token
    $accessToken = Get-AuthorizationServiceToken -Scopes $tokenScopes

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
