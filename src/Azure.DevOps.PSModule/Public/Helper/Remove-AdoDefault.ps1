function Remove-AdoDefault {
    <#
    .SYNOPSIS
        Remove default Azure DevOps environment variables.

    .DESCRIPTION
        This function removes the default Azure DevOps environment variables from both the current session.

    .EXAMPLE
        Remove-AdoDefault

        Removes the default Azure DevOps environment variables from both the current session.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess('Default Azure DevOps environment variables', 'Remove')) {

                # Remove from current session environment variables
                $env:DefaultAdoOrganization = $null
                $env:DefaultAdoCollectionUri = $null
                $env:DefaultAdoProject = $null

                Write-Verbose 'Removed default Azure DevOps environment variables from current session.'

            } else {
                Write-Verbose 'Would remove default Azure DevOps environment variables from current session.'
            }
        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
