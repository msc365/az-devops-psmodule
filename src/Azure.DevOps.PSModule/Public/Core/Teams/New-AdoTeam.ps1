function New-AdoTeam {
    <#
    .SYNOPSIS
        Creates a new team in an Azure DevOps project.

    .DESCRIPTION
        This cmdlet creates a new Azure DevOps team within a specified project.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The ID or name of the project. If not specified, the default project is used.

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
            ProjectName   = 'my-project-1'
            Name          = 'my-team'
        }
        New-AdoTeam @params -Verbose

        Creates a new team in the specified project.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        @('team-1', 'team-2') | New-AdoTeam @params -Verbose

        Creates multiple teams demonstrating pipeline input.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('TeamName')]
        [string]$Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Description,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.3')]
        [string]$Version = '7.1'
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
            $params = @{
                Uri     = "$CollectionUri/_apis/projects/$ProjectName/teams"
                Version = $Version
                Method  = 'POST'
            }

            $body = [PSCustomObject]@{
                name        = $Name
                description = $Description
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, "Create Team: $Name in Project: $ProjectName")) {
                try {
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
                } catch {
                    if ($_.ErrorDetails.Message -match 'TeamAlreadyExistsException') {
                        Write-Warning "Team $Name already exists, trying to get it."

                        $results = Get-AdoTeam -CollectionUri $CollectionUri -ProjectName $ProjectName -Name $Name

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
