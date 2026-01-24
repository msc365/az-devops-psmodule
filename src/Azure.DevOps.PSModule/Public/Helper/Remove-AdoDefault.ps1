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
    [CmdletBinding()]
    param ()

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
    }

    process {
        Set-AdoDefault -Organization $null -Project $null
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
