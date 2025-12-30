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

    .PARAMETER Version
        Optional. The API version to use.

    .LINK
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/get
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/list

    #>
    [CmdletBinding(DefaultParameterSetName = 'ListProjects', SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'ByNameOrId')]
        [Alias('Id', 'ProjectId', 'ProjectName')]
        [string[]]$Name,

        [Parameter(ParameterSetName = 'ByNameOrId')]
        [switch]$IncludeCapabilities,

        [Parameter(ParameterSetName = 'ByNameOrId')]
        [switch]$IncludeHistory,

        [Parameter(ParameterSetName = 'ListProjects')]
        [int]$Skip = 0,

        [Parameter(ParameterSetName = 'ListProjects')]
        [int]$Top = 10,

        [Parameter(ParameterSetName = 'ListProjects')]
        [string]$ContinuationToken,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("Version: $Version")

        Confirm-Defaults -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })
    }

    process {
        try {
            $queryParameters = [System.Collections.Generic.List[string]]::new()

            if ($Name) {
                $uri = "$CollectionUri/_apis/projects/$Name"

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
            }

            $params = @{
                Uri             = $uri
                Version         = $Version
                QueryParameters = if ($queryParameters.Count -gt 0) { $queryParameters -join '&' } else { $null }
                Method          = 'GET'
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, $Name ? "Get Project '$($Name)'" : 'Get Projects')) {

                $response = Invoke-AdoRestMethod @params
                $projects = if ($Name) { $response } else { $response.value }

                # Output directly to pipeline
                foreach ($prj in $projects) {
                    $obj = [ordered]@{
                        name        = $prj.name
                        id          = $prj.id
                        description = $prj.description
                        visibility  = $prj.visibility
                        state       = $prj.state
                    }
                    if ($prj.capabilities) {
                        $obj['capabilities'] = $prj.capabilities
                    }
                    $obj['collectionUri'] = $CollectionUri
                    if ($response.continuationToken) {
                        $obj['continuationToken'] = $response.continuationToken
                    }
                    [PSCustomObject]$obj
                }

            } else {
                Write-Verbose "Calling Invoke-AdoRestMethod with $($params| ConvertTo-Json -Depth 10)"
            }

        } catch {
            throw $_
        }

    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
