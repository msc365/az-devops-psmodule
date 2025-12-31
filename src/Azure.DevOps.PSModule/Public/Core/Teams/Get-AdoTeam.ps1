function Get-AdoTeam {
    <#
    .SYNOPSIS
        Retrieves Azure DevOps team details.

    .DESCRIPTION
        This cmdlet retrieves details of one or more Azure DevOps teams within a given project.
        You can retrieve all teams in a project, or specific teams by name or ID.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/myorganization.

    .PARAMETER ProjectName
        Mandatory. The ID or name of the project.

    .PARAMETER Name
        Optional. The ID or name of the team(s) to retrieve. If not provided, retrieves all teams.

    .PARAMETER Skip
        Optional. The number of teams to skip. Used for pagination when retrieving all teams.

    .PARAMETER Top
        Optional. The number of teams to retrieve. Used for pagination when retrieving all teams

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.3'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/get
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/get-teams

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
        }
        Get-AdoTeam @params

        Retrieves all teams from the specified project.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
        }
        Get-AdoTeam @params -Name 'my-team'

        Retrieves the specified team from the project.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
        }
        @('team-1', 'team-2') | Get-AdoTeam @params -Verbose

        Retrieves multiple teams demonstrating pipeline input.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
        }
        Get-AdoTeam @params -Top 5

        Retrieves the first 5 teams from the specified project.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ListTeams', SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'ByName')]
        [Alias('Team', 'TeamId', 'TeamName')]
        [string[]]$Name,

        [Parameter(ParameterSetName = 'ListTeams')]
        [int]$Skip,

        [Parameter(ParameterSetName = 'ListTeams')]
        [int]$Top,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('5.1', '7.1-preview.4', '7.2-preview.3')]
        [string]$Version = '7.2-preview.3'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Name: $($Name -join ',')")
        Write-Debug ("Skip: $Skip")
        Write-Debug ("Top: $Top")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })
    }

    process {
        try {

            foreach ($n_ in $Name) {
                $queryParameters = [System.Collections.Generic.List[string]]::new()

                if ($n_) {
                    $uri = "$CollectionUri/_apis/projects/$ProjectName/teams/$n_"
                } else {
                    $uri = "$CollectionUri/_apis/projects/$ProjectName/teams"

                    # Build query parameters
                    if ($Skip) {
                        $queryParameters.Add("`$skip=$Skip")
                    }
                    if ($Top) {
                        $queryParameters.Add("`$top=$Top")
                    }
                }

                $params = @{
                    Uri             = $uri
                    Version         = $Version
                    QueryParameters = if ($queryParameters.Count -gt 0) { $queryParameters -join '&' } else { $null }
                    Method          = 'GET'
                }

                if ($PSCmdlet.ShouldProcess($CollectionUri, $n_ ? "Get Team: $n_ in Project: $ProjectName" : "Get Teams for Project: $ProjectName")) {

                    try {
                        $results = Invoke-AdoRestMethod @params
                        $teams = if ($n_) { @($results) } else { $results.value }

                        foreach ($t_ in $teams) {
                            [PSCustomObject]@{
                                id            = $t_.id
                                name          = $t_.name
                                description   = $t_.description
                                url           = $t_.url
                                identityUrl   = $t_.identityUrl
                                projectId     = $t_.projectId
                                projectName   = $t_.projectName
                                collectionUri = $CollectionUri
                            }
                        }

                    } catch {
                        if ($_ -match 'does not exist') {
                            Write-Warning "Team with ID $n_ does not exist in project $ProjectName, skipping."
                        } else {
                            throw $_
                        }
                    }

                } else {
                    Write-Verbose "Calling Invoke-AdoRestMethod with $($params | ConvertTo-Json -Depth 10)"
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
