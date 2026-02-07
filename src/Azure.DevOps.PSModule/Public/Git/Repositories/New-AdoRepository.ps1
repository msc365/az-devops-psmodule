function New-AdoRepository {
    <#
    .SYNOPSIS
        Create a new repository in an Azure DevOps project.

    .DESCRIPTION
        This cmdlet creates a new repository in an Azure DevOps project through REST API.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Mandatory. The ID or name of the project.

    .PARAMETER Name
        Mandatory. The name of the repository.

    .PARAMETER SourceRef
        Optional. Specify the source refs to use while creating a fork repo.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/git/repositories/create

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            Name          = 'my-repository-1'
        }
        New-AdoRepository @params

        Creates a new repository named 'my-repository-1' in the specified project.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('RepositoryName')]
        [string]$Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$SourceRef,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.2')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Name: $Name")
        Write-Debug ("SourceRef: $SourceRef")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            # Get id when name was provided, id is required for body
            try {
                [System.Guid]::Parse($ProjectName) | Out-Null
                $projectId = $ProjectName
            } catch {
                $projectId = (Get-AdoProject -CollectionUri $CollectionUri -Name $ProjectName).id
                if (-not $projectId) { continue }
            }

            $queryParameters = [List[string]]::new()

            if ($SourceRef) {
                $queryParameters.Add("sourceRef=$SourceRef")
            }

            $uri = "$CollectionUri/$ProjectName/_apis/git/repositories"

            $body = [PSCustomObject]@{
                name    = $Name
                project = @{
                    id = $projectId
                }
            }

            $params = @{
                Uri             = $uri
                Version         = $Version
                QueryParameters = if ($queryParameters.Count -gt 0) { $queryParameters -join '&' } else { $null }
                Method          = 'POST'
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, "Create Repository '$($Name)' in project '$($ProjectName)'")) {
                try {
                    $results = $body | Invoke-AdoRestMethod @params

                    [PSCustomObject]@{
                        id            = $results.id
                        name          = $results.name
                        project       = $results.project
                        defaultBranch = $results.defaultBranch
                        url           = $results.url
                        remoteUrl     = $results.remoteUrl
                        projectName   = $ProjectName
                        collectionUri = $CollectionUri
                    }

                } catch {
                    if ($_.ErrorDetails.Message -match 'RepositoryAlreadyExists') {
                        Write-Warning "Repository $Name already exists, trying to get it"

                        $results = Get-AdoRepository -CollectionUri $CollectionUri -ProjectName $ProjectName -Name $Name

                        [PSCustomObject]@{
                            id            = $results.id
                            name          = $results.name
                            project       = $results.project
                            defaultBranch = $results.defaultBranch
                            url           = $results.url
                            remoteUrl     = $results.remoteUrl
                            projectName   = $ProjectName
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
