function Set-AdoDefault {
    <#
    .SYNOPSIS
        Set default Azure DevOps environment variables.

    .DESCRIPTION
        This function sets the default Azure DevOps environment variables for the current session.

    .EXAMPLE
        Set-AdoDefault -Organization 'my-org' -Project 'my-project-1'

        Sets the default Azure DevOps default Organization to 'my-org', CollectionUri to "https://dev.azure.com/my-org" and Project to 'my-project-1'.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$Organization,

        [Parameter()]
        [string]$Project
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("Organization: $Organization")
        Write-Debug ("Project: $Project")

        $result = @{}
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess('Default Azure DevOps environment variables', 'Set')) {

                # Set for current session environment variables
                $env:DefaultAdoOrganization = $Organization
                $result.Organization = $env:DefaultAdoOrganization

                $env:DefaultAdoCollectionUri = "https://dev.azure.com/$Organization"
                $result.CollectionUri = $env:DefaultAdoCollectionUri

                $env:DefaultAdoProject = $Project
                $result.Project = $env:DefaultAdoProject

            } else {
                Write-Verbose "Settings default session environment variables to: $($result | ConvertTo-Json -Depth 10)"
            }
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
