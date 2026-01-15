function Get-AdoRepository {
    <#
    .SYNOPSIS
        Retrieves Azure DevOps repository details.

    .DESCRIPTION
        This cmdlet retrieves details of one or more Azure DevOps repositories within a specified project.
        You can retrieve all repositories, or specific repositories by name or ID.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Mandatory. The ID or name of the project.

    .PARAMETER Name
        Optional. The ID or name of the repository(s) to retrieve. If not provided, retrieves all repositories.

    .PARAMETER Skip
        Optional. The number of repositories to skip. Used for pagination.

    .PARAMETER Top
        Optional. The number of repositories to retrieve. Used for pagination. Default is 100.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/git/repositories/get-repository

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        Get-AdoRepository @params

        Retrieves all repositories from the specified project.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        Get-AdoRepository @params -Name 'my-repository-1'

        Retrieves the specified repository from the project.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ListRepositories')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'ByNameOrId')]
        [Alias('Repository', 'RepositoryId', 'RepositoryName')]
        [string]$Name,

        [Parameter(ParameterSetName = 'ListRepositories')]
        [switch]$IncludeLinks,

        [Parameter(ParameterSetName = 'ListRepositories')]
        [switch]$IncludeHidden,

        [Parameter(ParameterSetName = 'ListRepositories')]
        [switch]$IncludeAllUrls,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.2')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Name: $($Name -join ',')")
        Write-Debug ("IncludeLinks: $IncludeLinks")
        Write-Debug ("IncludeHidden: $IncludeHidden")
        Write-Debug ("IncludeAllUrls: $IncludeAllUrls")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $queryParameters = [System.Collections.Generic.List[string]]::new()

            if ($Name) {
                $uri = "$CollectionUri/$ProjectName/_apis/git/repositories/$Name"
            } else {
                $uri = "$CollectionUri/$ProjectName/_apis/git/repositories"

                # Build query parameters
                if ($IncludeLinks) {
                    $queryParameters.Add("includeLinks=$true")
                }
                if ($IncludeHidden) {
                    $queryParameters.Add("includeHidden=$true")
                }
                if ($IncludeAllUrls) {
                    $queryParameters.Add("includeAllUrls=$true")
                }
            }

            $params = @{
                Uri             = $uri
                Version         = $Version
                QueryParameters = if ($queryParameters.Count -gt 0) { $queryParameters -join '&' } else { $null }
                Method          = 'GET'
            }

            try {
                $results = Invoke-AdoRestMethod @params
                $repos = if ($Name) { @($results) } else { $results.value }
                foreach ($r_ in $repos) {
                    [PSCustomObject]@{
                        id            = $r_.id
                        name          = $r_.name
                        project       = $r_.project
                        defaultBranch = $r_.defaultBranch
                        url           = $r_.url
                        remoteUrl     = $r_.remoteUrl
                        projectName   = $ProjectName
                        collectionUri = $CollectionUri
                    }
                }
            } catch {
                if ($_.ErrorDetails.Message -match 'NotFoundException') {
                    Write-Warning "Repository with ID $Name does not exist in project $ProjectName, skipping."
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
