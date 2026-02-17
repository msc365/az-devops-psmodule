# cSpell: words teamfieldvalues, teamsettings
function Set-AdoTeamFieldValue {
    <#
    .SYNOPSIS
        Updates the team field value settings for a team in an Azure DevOps project.

    .DESCRIPTION
        This cmdlet updates the team field value settings for a specified team in an Azure DevOps project.
        Team field values define which work items belong to a team based on the Area Path field.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The ID or name of the project. If not specified, the default project is used.

    .PARAMETER TeamName
        Optional. The ID or name of the team within the project. If not specified, the default team is used.

    .PARAMETER DefaultValue
        Optional. The default team field value for the team.

    .PARAMETER Values
        Optional. An array of team field values to set for the team. Each value should have a 'value' and 'includeChildren' property.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .OUTPUTS
        PSCustomObject

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamfieldvalues/update

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            DefaultValue  = 'my-project-1'
            Values        = @(
                @{
                    value           = 'my-project-1\my-team-1'
                    includeChildren = $false
                }
                @{
                    value           = 'my-project-1\my-team-2'
                    includeChildren = $false
                }
            )
        }
        Set-AdoTeamFieldValue @params

        Updates the team field values for the default team in the specified project.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            TeamName      = 'my-team-1'
            DefaultValue  = 'my-project-1\my-team-1'
            Values        = @(
                @{
                    value           = 'my-project-1\my-team-1'
                    includeChildren = $false
                }
            )
        }
        Set-AdoTeamFieldValue @params

        Updates the team field value for team 'my-team-1' in the specified project.

    .EXAMPLE
        $params = @{
            TeamName     = 'my-team-1'
            DefaultValue = 'my-project-1'
            Values       = @(
                @{
                    value           = 'my-project-1'
                    includeChildren = $true
                }
            )
        }
        Set-AdoTeamFieldValue @params

        Updates the team field values for team 'my-team-1' in project 'my-project-1' sub-areas are included.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('TeamId')]
        [string]$TeamName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$DefaultValue,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [hashtable[]]$Values,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("TeamName: $TeamName")
        Write-Debug ("DefaultValue: $DefaultValue")
        Write-Debug ("Values Count: $($Values.Count)")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            # Validate input values
            foreach ($v_ in $Values) {
                if ([string]::IsNullOrWhiteSpace($v_.value)) {
                    throw "The 'value' property is required for each field value."
                }
                if ($null -eq $v_.includeChildren -or $v_.includeChildren -isnot [bool]) {
                    throw "The 'includeChildren' property must be of type bool and cannot be null."
                }
            }

            $uri = if ($TeamName) {
                "$CollectionUri/$ProjectName/$TeamName/_apis/work/teamsettings/teamfieldvalues"
            } else {
                "$CollectionUri/$ProjectName/_apis/work/teamsettings/teamfieldvalues"
            }

            $params = @{
                Uri     = $uri
                Version = $Version
                Method  = 'PATCH'
            }

            $body = [PSCustomObject]@{
                defaultValue = $DefaultValue
                values       = @(
                    foreach ($v_ in $Values) {
                        @{
                            value           = $v_.value
                            includeChildren = $v_.includeChildren
                        }
                    }
                )
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, $TeamName ? "Update team field values for $TeamName" : 'Update team field values for Default Team')) {
                try {
                    $results = $body | Invoke-AdoRestMethod @params

                    [PSCustomObject]@{
                        defaultValue  = $results.defaultValue
                        field         = $results.field
                        values        = $results.values
                        projectName   = $ProjectName
                        collectionUri = $CollectionUri
                    }
                } catch {
                    if ($_.ErrorDetails.Message -match 'NotFoundException') {
                        Write-Warning 'Team or field value does not exist, skipping.'
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
