# cSpell: ignore teamsettings
function Get-AdoTeamIteration {
    <#
    .SYNOPSIS
        Retrieves Azure DevOps team iteration details.

    .DESCRIPTION
        This cmdlet retrieves details of one or more Azure DevOps team iterations within a specified project and team.
        You can retrieve all iterations, filter by timeframe, or retrieve specific iterations by ID.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Mandatory. The ID or name of the project.

    .PARAMETER TeamName
        Mandatory. The ID or name of the team.

    .PARAMETER Id
        Optional. The ID of the iteration(s) to retrieve. If not provided, retrieves all iterations.

    .PARAMETER TimeFrame
        Optional. The timeframe to filter iterations. Valid values are 'past', 'current', and 'future'.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/work/iterations/get
        https://learn.microsoft.com/en-us/rest/api/azure/devops/work/iterations/list

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName = 'my-project'
            TeamName = 'my-team'
        }
        Get-AdoTeamIteration @params

        Retrieves all iterations for the specified team.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName = 'my-project'
            TeamName = 'my-team'
            TimeFrame = 'current'
        }
        Get-AdoTeamIteration @params

        Retrieves current iterations for the specified team.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName = 'my-project'
            TeamName = 'my-team'
            Id = '00000000-0000-0000-0000-000000000000'
        }
        Get-AdoTeamIteration @params

        Retrieves the specified iteration by ID.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ListIterations')]
    [OutputType([object])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('TeamId')]
        [string]$TeamName,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ById')]
        [Alias('IterationId')]
        [string]$Id,

        [Parameter(HelpMessage = "Only 'current' is supported currently.", ValueFromPipelineByPropertyName, ParameterSetName = 'ListIterations')]
        [ValidateSet('past', 'current', 'future')]
        [string]$TimeFrame,

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
        Write-Debug ("TimeFrame: $TimeFrame")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $QueryParameters = [System.Collections.Generic.List[string]]::new()

            if ($Id) {
                # Get specific iteration by ID
                $uri = "$CollectionUri/$ProjectName/$TeamName/_apis/work/teamsettings/iterations/$Id"
            } else {
                # List all iterations
                $uri = "$CollectionUri/$ProjectName/$TeamName/_apis/work/teamsettings/iterations"

                # Build query parameters
                if ($TimeFrame) {
                    $QueryParameters.Add("`$timeframe=$TimeFrame")
                }
            }

            $params = @{
                Uri             = $uri
                Version         = $Version
                QueryParameters = if ($QueryParameters.Count -gt 0) { $QueryParameters -join '&' } else { $null }
                Method          = 'GET'
            }

            try {
                $results = Invoke-AdoRestMethod @params
                $items = if ($Id) { @($results) } else { $results.value }

                # Build output objects
                foreach ($i_ in $items) {
                    [PSCustomObject]@{
                        id            = $i_.id
                        name          = $i_.name
                        attributes    = $i_.attributes
                        teamName      = $TeamName
                        projectName   = $ProjectName
                        collectionUri = $CollectionUri
                    }
                }
            } catch {
                if ($_.ErrorDetails.Message -match 'NotFoundException') {
                    Write-Warning "Iteration with ID $Id does not exist, skipping."
                } else {
                    throw $_
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
