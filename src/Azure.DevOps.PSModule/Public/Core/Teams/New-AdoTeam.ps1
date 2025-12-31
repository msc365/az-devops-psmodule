function New-AdoTeam {
    <#
    .SYNOPSIS
        Creates a new team in an Azure DevOps project.

    .DESCRIPTION
        This cmdlet creates a new Azure DevOps team within a specified project.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/myorganization.

    .PARAMETER ProjectName
        Mandatory. The ID or name of the project.

    .PARAMETER Name
        Mandatory. The name of the team to create.

    .PARAMETER Description
        Optional. The description of the team.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.3'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/create

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
            Name          = 'my-team'
        }
        New-AdoTeam @params -Verbose

        Creates a new team in the specified project.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
        }
        @('team-1', 'team-2') | New-AdoTeam @params -Verbose

        Creates multiple teams demonstrating pipeline input.
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
        [Alias('TeamName')]
        [string[]]$Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Description,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('5.1', '7.1-preview.4', '7.2-preview.3')]
        [string]$Version = '7.2-preview.3'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Name: $Name")
        Write-Debug ("Description: $Description")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })
    }

    process {
        try {

            foreach ($n_ in $Name) {

                $params = @{
                    Uri     = "$CollectionUri/_apis/projects/$ProjectName/teams"
                    Version = $Version
                    Method  = 'POST'
                }

                $body = [PSCustomObject]@{
                    name        = $n_
                    description = $Description
                }

                if ($PSCmdlet.ShouldProcess($CollectionUri, "Create Team: $n_ in Project: $ProjectName")) {

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
