function Set-AdoTeam {
    <#
    .SYNOPSIS
        Updates an existing Azure DevOps team.

    .DESCRIPTION
        This cmdlet updates an existing Azure DevOps team within a specified project.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/myorganization.

    .PARAMETER ProjectName
        Mandatory. The ID or name of the project.

    .PARAMETER Id
        Mandatory. The ID or name of the team to update.

    .PARAMETER Name
        Optional. The new name of the team.

    .PARAMETER Description
        Optional. The new description of the team.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.3'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/update

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
            Id            = 'my-team'
            Name          = 'my-team-updated'
        }
        Set-AdoTeam @params -Verbose

        Updates the name of the specified team.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
        }
        [PSCustomObject]@{
            Id          = 'my-team'
            Name        = 'my-team-updated'
            Description = 'Updated description'
        } | Set-AdoTeam @params -Verbose

        Updates the team using pipeline input.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('Team', 'TeamId', 'TeamName')]
        [string[]]$Id,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Description,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.3')]
        [string]$Version = '7.2-preview.3'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Id: $Id")
        Write-Debug ("Name: $Name")
        Write-Debug ("Description: $Description")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })
    }

    process {
        try {

            foreach ($t_ in $Id) {

                $params = @{
                    Uri     = "$CollectionUri/_apis/projects/$ProjectName/teams/$t_"
                    Version = $Version
                    Method  = 'PATCH'
                }

                $body = [PSCustomObject]@{}

                if ($PSBoundParameters.ContainsKey('Name')) {
                    $body | Add-Member -NotePropertyName 'name' -NotePropertyValue $Name
                }
                if ($PSBoundParameters.ContainsKey('Description')) {
                    $body | Add-Member -NotePropertyName 'description' -NotePropertyValue $Description
                }

                if ($PSCmdlet.ShouldProcess($CollectionUri, "Update Team: $t_ in Project: $ProjectName")) {

                    $results = $body | Invoke-AdoRestMethod @params

                    [PSCustomObject]@{
                        id            = $results.id
                        name          = $results.name
                        description   = $results.description
                        url           = $results.url
                        identityUrl   = $results.identityUrl
                        projectId     = $results.projectId
                        projectName   = $results.projectName
                        collectionUri = $CollectionUri
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
