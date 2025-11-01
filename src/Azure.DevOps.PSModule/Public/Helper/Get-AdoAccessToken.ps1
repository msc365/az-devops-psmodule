function Get-AdoAccessToken {
    <#
    .SYNOPSIS
        Get secure access token for Azure DevOps service principal.

    .DESCRIPTION
        The function gets an access token for the Azure DevOps service principal using the current Azure context or a specified tenant ID.

    .PARAMETER TenantId
        The tenant ID to use for retrieving the access token. If not specified, the tenant ID from the current Azure context is used.

    .OUTPUTS
        System.Security.SecureString

    .EXAMPLE
        Get-AdoAccessToken

        This example retrieves an access token for Azure DevOps using the tenant ID from the current Azure context.

    .EXAMPLE
        Get-AdoAccessToken -TenantId "00000000-0000-0000-0000-000000000000"

        This example retrieves an access token for Azure DevOps using the specified tenant ID.

    .NOTES
        Please make sure the context matches the current Azure environment. You may refer to the value of `(Get-AzContext).Environment`.
    #>
    [CmdletBinding()]
    [OutputType([System.Security.SecureString])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Converting Azure API token response to SecureString for secure handling')]
    param (
        [Parameter()]
        [string]$TenantId = ''
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)
    }

    process {
        try {
            if (-not $TenantId) {
                # Get the current Azure context
                $ctx = Get-AzContext

                if ($null -eq $ctx) {
                    throw 'Azure context is not available.'
                } else {
                    $TenantId = $ctx.Tenant.Id
                }
            }
            Write-Verbose ('Using TenantId: {0}' -f $TenantId)

            # Don't change this. This is the immutable application ID of the Azure DevOps service principal.
            $principalAppId = '499b84ac-1321-427f-aa17-267ca6975798'
            Write-Verbose ('Using Azure DevOps AppId: {0}' -f $principalAppId)

            # Get the access token for the Azure DevOps service principal
            $azAccessToken = Get-AzAccessToken -ResourceUrl $principalAppId -TenantId ($TenantId)

            if ($null -eq $azAccessToken) { return $null }

            # Convert token part to SecureString
            $tokenAsSecureString = $azAccessToken.Token | ConvertTo-SecureString -AsPlainText -Force
            Write-Verbose ('Retrieved access token successfully.')

            return $tokenAsSecureString

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
