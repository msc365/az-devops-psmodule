function Get-AdoDefaults {
    <#
    .SYNOPSIS
        Get default Azure DevOps environment variables.

    .DESCRIPTION
        This function gets the default Azure DevOps environment variables from the current session.

    .EXAMPLE
        Get-AdoDefaults

        Gets the default Azure DevOps organization and project context.
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', 'Get-AdoDefaults')]
    [CmdletBinding()]
    param (
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")

        $result = @{}
    }

    process {
        try {
            # Get environment variables
            $result.Organization = $env:DefaultAdoOrganization
            $result.CollectionUri = $env:DefaultAdoCollectionUri
            $result.Project = $env:DefaultAdoProject

        } catch {
            throw $_
        }
    }

    end {

        if ($result) {
            [PSCustomObject]@{
                Organization  = $result.Organization
                CollectionUri = $result.CollectionUri
                ProjectName   = $result.Project
            }
        }

        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
