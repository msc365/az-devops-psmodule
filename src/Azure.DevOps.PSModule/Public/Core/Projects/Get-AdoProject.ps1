function Get-AdoProject {
    <#
    .SYNOPSIS
        Retrieves Azure DevOps project details.

    .DESCRIPTION
        This cmdlet retrieves details of one or more Azure DevOps projects within a specified organization.
        You can retrieve all projects, a specific project by name or id, and control the amount of data returned using pagination parameters.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/myorganization.

    .PARAMETER Name
        Optional. The name or id of the project to retrieve. If not provided, retrieves all projects.

    .PARAMETER IncludeCapabilities
        Optional. Include capabilities (such as source control) in the team project result. Default is 'false'.

    .PARAMETER IncludeHistory
        Optional. Search within renamed projects (that had such name in the past). Default is 'false'.

    .PARAMETER Skip
        Optional. The number of projects to skip. Used for pagination when retrieving all projects.

    .PARAMETER Top
        Optional. The number of projects to retrieve. Used for pagination when retrieving all projects.

    .PARAMETER ContinuationToken
        Optional. An opaque data blob that allows the next page of data to resume immediately after where the previous page ended.
        The only reliable way to know if there is more data left is the presence of a continuation token.

    .PARAMETER StateFilter
        Optional. A filter for the project state. Possible values are 'deleting', 'new', 'wellFormed', 'createPending', 'all', 'unchanged', 'deleted'.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/get
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/list

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        Get-AdoProject @params -Top 5

        Retrieves the first 5 projects from the specified organization.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        Get-AdoProject @params -Name 'my-project'

        Retrieves the specified project by name.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        @('my-project-1', 'my-project-2') | Get-AdoProject @params -Verbose

        Retrieves multiple projects by name demonstrating pipeline input.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ListProjects', SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'ByNameOrId')]
        [Alias('Id', 'ProjectId', 'ProjectName')]
        [string[]]$Name,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByNameOrId')]
        [switch]$IncludeCapabilities,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByNameOrId')]
        [switch]$IncludeHistory,

        [Parameter(ParameterSetName = 'ListProjects')]
        [int]$Skip,

        [Parameter(ParameterSetName = 'ListProjects')]
        [int]$Top,

        [Parameter(ParameterSetName = 'ListProjects')]
        [string]$ContinuationToken,

        [Parameter(ParameterSetName = 'ListProjects')]
        [ValidateSet('deleting', 'new', 'wellFormed', 'createPending', 'all', 'unchanged', 'deleted')]
        [string]$StateFilter,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("Name: $Name")
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
                    $uri = "$CollectionUri/_apis/projects/$n_"

                    # Build query parameters
                    if ($IncludeCapabilities) {
                        $queryParameters.Add('includeCapabilities=true')
                    }
                    if ($IncludeHistory) {
                        $queryParameters.Add('includeHistory=true')
                    }
                } else {
                    $uri = "$CollectionUri/_apis/projects"

                    # Build query parameters
                    if ($Skip) {
                        $queryParameters.Add("`$skip=$Skip")
                    }
                    if ($Top) {
                        $queryParameters.Add("`$top=$Top")
                    }
                    if ($ContinuationToken) {
                        $queryParameters.Add("continuationToken=$ContinuationToken")
                    }
                    if ($StateFilter) {
                        $queryParameters.Add("stateFilter=$StateFilter")
                    }
                }

                $params = @{
                    Uri             = $uri
                    Version         = $Version
                    QueryParameters = if ($queryParameters.Count -gt 0) { $queryParameters -join '&' } else { $null }
                    Method          = 'GET'
                }

                if ($PSCmdlet.ShouldProcess($CollectionUri, $n_ ? "Get Project: $n_" : 'Get Projects')) {

                    $results = Invoke-AdoRestMethod @params
                    $projects = if ($n_) { @($results) } else { $results.value }

                    foreach ($p_ in $projects) {
                        [PSCustomObject]@{
                            id                = $p_.id
                            name              = $p_.name
                            description       = $p_.description
                            visibility        = $p_.visibility
                            state             = $p_.state
                            defaultTeam       = $p_.DefaultTeam
                            capabilities      = if ($p_.capabilities) { $p_.capabilities } else { $null }
                            collectionUri     = $CollectionUri
                            continuationToken = if ($results.continuationToken) { $results.continuationToken } else { $null }
                        }
                    }

                } else {
                    Write-Verbose "Calling Invoke-AdoRestMethod with $($params| ConvertTo-Json -Depth 10)"
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
