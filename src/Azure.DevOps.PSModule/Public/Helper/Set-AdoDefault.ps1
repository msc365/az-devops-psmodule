function Set-AdoDefault {
    <#
    .SYNOPSIS
        Set default Azure DevOps environment variables.

    .DESCRIPTION
        This function sets the default Azure DevOps environment variables for the current session.

    .EXAMPLE
        Set-AdoDefault -Organization 'my-org' -Project 'my-project-1'

        Sets the default Azure DevOps default Organization to 'my-org', CollectionUri to "https://dev.azure.com/my-org" and Project to 'my-project-1'.

    .EXAMPLE
        Set-AdoDefault -Organization $null -Project $null

        Removes the default Azure DevOps environment variables from the current session.
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [AllowNull()]
        [string]$Organization,

        [Parameter()]
        [AllowNull()]
        [string]$Project
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("Organization: $Organization")
        Write-Debug ("Project: $Project")

        $result = @{
            Organization  = $null
            CollectionUri = $null
            ProjectName   = $null
        }
    }

    process {
        # Set for current session environment variables
        $env:DefaultAdoOrganization = $Organization
        $result.Organization = $env:DefaultAdoOrganization

        $env:DefaultAdoCollectionUri = if (-not [string]::IsNullOrEmpty($Organization)) { "https://dev.azure.com/$Organization" } else { $null }
        $result.CollectionUri = $env:DefaultAdoCollectionUri

        $env:DefaultAdoProject = $Project
        $result.ProjectName = $env:DefaultAdoProject
    }

    end {
        [PSCustomObject]$result

        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
