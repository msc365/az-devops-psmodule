function Confirm-Default {
    <#
    .SYNOPSIS
        Confirms that required default parameters are set.

    .DESCRIPTION
        This function checks if the required default parameters are set in the provided hashtable.
        If any required parameter is missing or empty, it throws an error prompting the user to set a default value.

    .PARAMETER Defaults
        A hashtable containing the default parameters to be checked.

    .EXAMPLE
        $defaults = @{
            Organization = 'my-org'
            Project      = ''
        }
        Confirm-Default -Defaults $defaults

        This will throw an error indicating that the 'Project' parameter is required.

    .EXAMPLE
        $defaults = @{
            Organization = 'my-org'
            Project      = 'my-project'
        }
        Confirm-Default -Defaults $defaults

        This will pass without errors as all required parameters are set.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable]$Defaults
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
    }

    process {
        try {

            foreach ($key in $Defaults.Keys) {
                $DefaultValue = $Defaults[$key]

                if ([string]::IsNullOrEmpty($DefaultValue)) {
                    throw "Parameter '$key' is required. Please set defaults using 'Set-AdoDefault' or specify it directly."
                }
            }

        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
