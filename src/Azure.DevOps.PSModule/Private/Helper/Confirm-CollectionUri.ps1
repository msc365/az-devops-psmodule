function Confirm-CollectionUri {
    <#
    .SYNOPSIS
        Validates whether the provided URI is a valid Azure DevOps collection URI.

    .DESCRIPTION
        This function checks if the given URI matches the expected format for Azure DevOps collection URIs.

    .PARAMETER Uri
        The URI to validate.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string]$Uri
    )

    begin {
        Write-Debug ("Command: $($MyInvocation.MyCommand.Name)")
    }

    process {
        try {
            if ($Uri -notmatch '^https:\/\/dev\.azure\.com\/\w+') {
                Write-AdoError "CollectionUri must be a valid Azure DevOps collection URI starting with 'https://dev.azure.com/'"
            } else {
                $true
            }
        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
