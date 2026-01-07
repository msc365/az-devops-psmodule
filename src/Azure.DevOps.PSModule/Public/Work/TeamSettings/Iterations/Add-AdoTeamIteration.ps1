# cSpell: ignore teamsettings
function Add-AdoTeamIteration {
    <#
    .SYNOPSIS
        Adds an iteration to a team in Azure DevOps.

    .DESCRIPTION
        This cmdlet adds a specific iteration to a team for a specified project in Azure DevOps.
        The iteration must already exist in the project's classification nodes.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Mandatory. The ID or name of the project.

    .PARAMETER TeamName
        Mandatory. The ID or name of the team.

    .PARAMETER Id
        Mandatory. The ID of the iteration to add to the team.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/work/iterations/post-team-iteration

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName = 'my-project'
            TeamName = 'my-team'
            Id = $iterationId
        }
        Add-AdoTeamIteration @params

        Adds the specified iteration to the team.

    .EXAMPLE
        $params = @{
            ProjectName = 'my-project'
            TeamName = 'my-team'
            Id = $iterationId
        }
        Add-AdoTeamIteration @params

        Adds the iteration using the default CollectionUri from context.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Team', 'TeamId')]
        [string]$TeamName,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('IterationId')]
        [string]$Id,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('api', 'ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("TeamName: $TeamName")
        Write-Debug ("Id: $Id")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $params = @{
                Uri     = "$CollectionUri/$ProjectName/$TeamName/_apis/work/teamsettings/iterations"
                Version = $Version
                Method  = 'POST'
            }

            $body = [PSCustomObject]@{
                id = $Id
            }

            if ($PSCmdlet.ShouldProcess($TeamName, "Add iteration: $Id ")) {
                try {
                    $results = $body | Invoke-AdoRestMethod @params

                    [PSCustomObject]@{
                        id            = $results.id
                        name          = $results.name
                        attributes    = $results.attributes
                        team          = $TeamName    # TeamName or TeamId
                        project       = $ProjectName # ProjectName or ProjectId
                        collectionUri = $CollectionUri
                    }

                } catch {
                    if ($_.ErrorDetails.Message -match 'InvalidTeamSettingsIterationException') {
                        Write-Warning "Iteration with ID $Id does not exist, skipping."
                    } else {
                        throw $_
                    }
                }
            } else {
                Write-Verbose "Calling Invoke-AdoRestMethod with $($params | ConvertTo-Json -Depth 10)"
            }
        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
