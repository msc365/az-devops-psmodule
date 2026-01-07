# cSpell: ignore teamsettings
function Get-AdoTeamSettings {
    <#
    .SYNOPSIS
        Retrieves the settings for a team in an Azure DevOps project.

    .DESCRIPTION
        This cmdlet retrieves the settings for a specified team within an Azure DevOps project,
        including working days, backlog iteration, bugs behavior, and backlog visibilities.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The ID or name of the project. If not specified, the default project is used.

    .PARAMETER Name
        Mandatory. The ID or name of the team to retrieve settings for.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamsettings/get

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        Get-AdoTeamSettings @params -Name 'my-team-1'

        Retrieves the settings for the team "my-team-1" in the project "my-project-1".

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        'my-team-1' | Get-AdoTeamSettings @params

        Retrieves the team settings using pipeline input.
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

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('Team', 'TeamId', 'TeamName')]
        [string]$Name,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Name: $Name")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $params = @{
                Uri     = "$CollectionUri/$ProjectName/$Name/_apis/work/teamsettings"
                Version = $Version
                Method  = 'GET'
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, "Get Team Settings for: $Name")) {
                try {
                    $results = Invoke-AdoRestMethod @params

                    [PSCustomObject]@{
                        backlogIteration      = $results.backlogIteration
                        backlogVisibilities   = $results.backlogVisibilities
                        bugsBehavior          = $results.bugsBehavior
                        defaultIteration      = $results.defaultIteration
                        defaultIterationMacro = $results.defaultIterationMacro
                        workingDays           = $results.workingDays
                        url                   = $results.url
                        projectName           = $ProjectName
                        collectionUri         = $CollectionUri
                    }
                } catch {
                    if ($_.ErrorDetails.Message -match 'NotFoundException') {
                        Write-Warning "Team $Name does not exist in project $ProjectName, skipping."
                    } else {
                        throw $_
                    }
                }
            } else {
                Write-Verbose "Calling Invoke-AdoRestMethod with $($params | ConvertTo-Json -Depth 5)"
            }
        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
