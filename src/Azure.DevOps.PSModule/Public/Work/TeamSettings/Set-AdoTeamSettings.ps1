# cSpell: ignore teamsettings
function Set-AdoTeamSettings {
    <#
    .SYNOPSIS
        Updates the settings for a team in Azure DevOps.

    .DESCRIPTION
        This cmdlet updates the settings for a team in Azure DevOps by sending a PATCH request to the Azure DevOps REST API.
        You can update working days, bugs behavior, backlog iteration, and backlog visibilities.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The ID or name of the project. If not specified, the default project is used.

    .PARAMETER Name
        Mandatory. The ID or name of the team to update settings for.

    .PARAMETER BacklogIteration
        Optional. The id (uuid) of the iteration to use as the backlog iteration.

    .PARAMETER BacklogVisibilities
        Optional. Object of backlog level visibilities (e.g., @{'Microsoft.EpicCategory' = $true}).

    .PARAMETER BugsBehavior
        Optional. How bugs should behave. Valid values: 'off', 'asRequirements', 'asTasks'.

    .PARAMETER DefaultIteration
        Optional. The default iteration id (uuid) for the team. Cannot be used together with DefaultIterationMacro.

    .PARAMETER DefaultIterationMacro
        Optional. Default iteration macro (e.g., '@currentIteration'). Used to set the default iteration dynamically. Cannot be used together with DefaultIteration.

    .PARAMETER WorkingDays
        Optional. Array of working days for the team (e.g., 'monday', 'tuesday', 'wednesday').

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamsettings/update

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            Name          = 'my-team-1'
            BugsBehavior  = 'asRequirements'
            WorkingDays   = @('monday', 'tuesday', 'wednesday', 'thursday', 'friday')
        }
        Set-AdoTeamSettings @params

        Updates the team settings to treat bugs as requirements and set working days.

    .EXAMPLE
        $params = @{
            CollectionUri        = 'https://dev.azure.com/my-org'
            ProjectName          = 'my-project-1'
            Name                 = 'my-team-1'
            BacklogVisibilities  = @{
                'Microsoft.EpicCategory'        = $false
                'Microsoft.FeatureCategory'     = $true
                'Microsoft.RequirementCategory' = $true
            }
        }
        Set-AdoTeamSettings @params

        Updates the backlog visibilities for the team.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            BugsBehavior = 'asRequirements'
            WorkingDays  = @('monday', 'tuesday', 'wednesday')
        }
        @(
            'my-team-1',
            'my-team-2'
        ) | Set-AdoTeamSettings @params

        Updates multiple teams to treat bugs as requirements and set working days using pipeline input.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'DefaultIterationMacro', ConfirmImpact = 'High')]
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

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$BacklogIteration,

        [Parameter(ValueFromPipelineByPropertyName)]
        [object]$BacklogVisibilities,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('off', 'asRequirements', 'asTasks')]
        [string]$BugsBehavior,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'DefaultIteration')]
        [string]$DefaultIteration,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'DefaultIterationMacro')]
        [string]$DefaultIterationMacro,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday')]
        [string[]]$WorkingDays,

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
        Write-Debug ("WorkingDays: $($WorkingDays -join ',')")
        Write-Debug ("BugsBehavior: $BugsBehavior")
        Write-Debug ("BacklogIterationId: $BacklogIteration")
        Write-Debug ("DefaultIterationMacro: $DefaultIterationMacro")
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
                Method  = 'PATCH'
            }

            $body = [PSCustomObject]@{}

            if ($PSBoundParameters.ContainsKey('BacklogIteration')) {
                $body | Add-Member -NotePropertyName 'backlogIteration' -NotePropertyValue @{ id = $BacklogIteration }
            }
            if ($PSBoundParameters.ContainsKey('BacklogVisibilities')) {
                $body | Add-Member -NotePropertyName 'backlogVisibilities' -NotePropertyValue $BacklogVisibilities
            }
            if ($PSBoundParameters.ContainsKey('BugsBehavior')) {
                $body | Add-Member -NotePropertyName 'bugsBehavior' -NotePropertyValue $BugsBehavior
            }
            if ($PSBoundParameters.ContainsKey('DefaultIteration')) {
                $body | Add-Member -NotePropertyName 'defaultIteration' -NotePropertyValue $DefaultIteration
            }
            if ($PSBoundParameters.ContainsKey('DefaultIterationMacro')) {
                $body | Add-Member -NotePropertyName 'defaultIterationMacro' -NotePropertyValue $DefaultIterationMacro
            }
            if ($PSBoundParameters.ContainsKey('WorkingDays')) {
                $body | Add-Member -NotePropertyName 'workingDays' -NotePropertyValue $WorkingDays
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, "Update Team Settings for: $Name")) {
                try {
                    $results = $body | Invoke-AdoRestMethod @params

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
                $params += @{
                    Body = $body
                }
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
