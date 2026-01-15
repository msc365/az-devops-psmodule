# cSpell: words teamfieldvalues, teamsettings
function Get-AdoTeamFieldValue {
    <#
    .SYNOPSIS
        Retrieves the team field value settings for a team in an Azure DevOps project.

    .DESCRIPTION
        This cmdlet retrieves the team field value settings for a specified team in an Azure DevOps project.
        Team field values define which work items belong to a team based on the Area Path field.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The ID or name of the project. If not specified, the default project is used.

    .PARAMETER TeamName
        Optional. The ID or name of the team within the project. If not specified, the default team is used.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamfieldvalues/get

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'e2egov-fantastic-four'
        }
        Get-AdoTeamFieldValue @params

        Retrieves the team field values for the default team in the specified project.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'e2egov-fantastic-four'
            TeamId        = 'Mister Fantastic'
        }
        Get-AdoTeamFieldValue @params

        Retrieves the team field values for the specified team in the specified project.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        [PSCustomObject]@{
            ProjectName = 'e2egov-fantastic-four'
            TeamId      = 'Mister Fantastic'
        } | Get-AdoTeamFieldValue @params

        Retrieves team field values using pipeline input.
    #>
    [CmdletBinding()]
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
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $uri = if ($TeamName) {
                "$CollectionUri/$ProjectName/$TeamName/_apis/work/teamsettings/teamfieldvalues"
            } else {
                "$CollectionUri/$ProjectName/_apis/work/teamsettings/teamfieldvalues"
            }

            $params = @{
                Uri     = $uri
                Version = $Version
                Method  = 'GET'
            }

            try {
                $results = Invoke-AdoRestMethod @params

                [PSCustomObject]@{
                    defaultValue  = $results.defaultValue
                    field         = $results.field
                    values        = $results.values
                    projectName   = $ProjectName
                    collectionUri = $CollectionUri
                }
            } catch {
                if ($_.ErrorDetails.Message -match 'NotFoundException') {
                    Write-Warning 'Team field value(s) does not exist, skipping.'
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
