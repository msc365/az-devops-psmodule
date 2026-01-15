function New-AdoAuthHeader {
    <#
    .SYNOPSIS
        Create a new Azure DevOps authentication header.

    .DESCRIPTION
        This function creates a new authentication header for Azure DevOps REST API calls using either
        a personal access token (PAT) or a service principal when no PAT is provided.

    .PARAMETER PAT
        The personal access token (PAT) to use for the authentication. If not provided, the token is retrieved using Get-AzAccessToken.
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]$PAT
    )

    begin {
        Write-Debug ("Command: $($MyInvocation.MyCommand.Name)")
        $principalAppId = '499b84ac-1321-427f-aa17-267ca6975798'
    }

    process {
        try {
            if ($PAT -eq '') {
                Write-Verbose 'Using access token'

                try {
                    if ($null -eq (Get-AzContext).Account) {
                        Write-Error 'Please login to Azure PowerShell first'
                        $PSCmdlet.ThrowTerminatingError($PSItem)
                    }

                    $token = (Get-AzAccessToken -Resource $principalAppId -AsSecureString).token
                    $script:header = @{
                        Authorization = 'Bearer {0}' -f ($token | ConvertFrom-SecureString -AsPlainText)
                    }
                } catch {
                    throw 'Please login to Azure PowerShell first'
                }
            } else {
                Write-Verbose 'Using PAT'

                $script:header = @{
                    Authorization = 'Basic {0}' -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)"))
                }
            }
        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
