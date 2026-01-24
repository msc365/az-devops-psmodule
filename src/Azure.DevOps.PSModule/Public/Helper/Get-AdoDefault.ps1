function Get-AdoDefault {
    <#
    .SYNOPSIS
        Get default Azure DevOps environment variables.

    .DESCRIPTION
        This function gets the default Azure DevOps environment variables from the current session.

    .EXAMPLE
        Get-AdoDefault

        Gets the default Azure DevOps organization and project context.
    #>
    [CmdletBinding()]
    param ()

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
    }

    process {
        [PSCustomObject]@{
            Organization  = $env:DefaultAdoOrganization
            CollectionUri = $env:DefaultAdoCollectionUri
            ProjectName   = $env:DefaultAdoProject
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
