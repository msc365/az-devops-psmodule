function Confirm-Defaults {
    <#
    .SYNOPSIS
        Confirms that required default parameters are set.

    .DESCRIPTION
        This function checks if the required default parameters are set in the provided hashtable.
        If any required parameter is missing or empty, it throws an error prompting the user to set a default value.

    .PARAMETER Defaults
        A hashtable containing the default parameters to be checked.
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', 'Confirm-Defaults')]
    param (
        [Parameter(Mandatory)]
        [hashtable]$Defaults
    )

    begin {
        Write-Debug ("Command: $($MyInvocation.MyCommand.Name)")
    }

    process {
        try {

            foreach ($key in $Defaults.Keys) {
                $DefaultValue = $Defaults[$key]

                if ([string]::IsNullOrEmpty($DefaultValue)) {
                    throw "Parameter '$key' is required. Please set defaults using 'Set-AdoDefaults' or specify it directly."
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
