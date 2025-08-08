<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS. MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
NO TECHNICAL SUPPORT IS PROVIDED. YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>

# Load the environment script
. "$PSScriptRoot\..\Common\EnterprisePolicyOperations.ps1"

function RemoveSubnetInjectionEnterprisePolicy
{
     param(
        [Parameter(
            Mandatory=$true,
            HelpMessage="The Policy Id"
        )]
        [string]$policyArmId
    )

    Write-Host "Logging In..." -ForegroundColor Green
    $connect = AzureLogin
    if ($false -eq $connect)
    {
        return
    }

    Write-Host "Logged In..." -ForegroundColor Green

    $policy = RemoveEnterprisePolicy $policyArmId
    if ($policy -eq "true")
    {
      Write-Host "Policy removed"  -ForegroundColor Green
      return
    }
    Write-Host "Policy not removed"  -ForegroundColor Red
}
RemoveSubnetInjectionEnterprisePolicy