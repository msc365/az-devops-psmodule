function Get-AdoEnvironment {
    <#
    .SYNOPSIS
        Get a list of Azure DevOps Pipeline Environments within a specified project.

    .DESCRIPTION
        This cmdlet retrieves a list of Azure DevOps Pipeline Environments for a given project, with optional filtering by environment name and pagination support.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER Name
        Optional. The name of the environment to filter the results.

    .PARAMETER Top
        Optional. The maximum number of environments to return.

    .PARAMETER Id
        Optional. The ID of a specific environment to retrieve.

    .PARAMETER Expands
        Optional. Include additional details in the returned objects. Valid values are 'none' and 'resourceReferences'. Default is 'none'.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.
        The -preview flag must be supplied in the api-version for such requests.

    .LINK
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/environments/environments/get
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/environments/environments/list

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }

        Get-AdoEnvironment @params -Top 2
        Get-AdoEnvironment @params -Name 'my-environment-tst'
        Get-AdoEnvironment @params -Name '*environment*'
        Get-AdoEnvironment @params -Name 'my-env*' -Top 2

        Retrieves environments from the specified project with various filtering and pagination options.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        @(
            'my-environment-tst',
            'my-environment-dev'
        ) | Get-AdoEnvironment @params -Verbose

        Retrieves the specified environments from the project, demonstrating pipeline input.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ListEnvironments')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ListEnvironments')]
        [string]$Name,

        [Parameter(ParameterSetName = 'ListEnvironments')]
        [string]$ContinuationToken,

        [Parameter(ParameterSetName = 'ListEnvironments')]
        [int32]$Top,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'ByEnvironmentId')]
        [int32]$Id,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByEnvironmentId')]
        [ValidateSet('none', 'resourceReferences')]
        [string]$Expands = 'none',

        [Parameter(HelpMessage = 'The -preview flag must be supplied in the api-version for such requests.')]
        [Alias('ApiVersion')]
        [ValidateSet('7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Name: $Name")
        Write-Debug ("Top: $Top")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $QueryParameters = [system.Collections.Generic.List[string]]::new()

            if ($Id) {
                $uri = "$CollectionUri/$ProjectName/_apis/pipelines/environments/$Id"

                if ($Expands) {
                    $QueryParameters.Add("expands=$Expands")
                }
            } else {
                $uri = "$CollectionUri/$ProjectName/_apis/pipelines/environments"

                # Build query parameters
                if ($Name) {
                    $QueryParameters.Add("name=$Name")
                }
                if ($ContinuationToken) {
                    $QueryParameters.Add("continuationToken=$ContinuationToken")
                }
                if ($Top) {
                    $QueryParameters.Add("`$top=$Top")
                }
            }

            $params = @{
                Uri             = $uri
                Version         = $Version
                QueryParameters = if ($queryParameters.Count -gt 0) { $queryParameters -join '&' } else { $null }
                Method          = 'GET'
            }

            try {
                $results = (Invoke-AdoRestMethod @params)
                $environments = if ($Id) { @($results) } else { $results.value }

                foreach ($e_ in $environments) {
                    $obj = [ordered]@{
                        id          = $e_.id
                        name        = $e_.name
                        description = $e_.description
                    }
                    if ($Expands -eq 'resourceReferences') {
                        $obj['resources'] = $e_.resources
                    }
                    $obj['createdBy'] = $e_.createdBy
                    $obj['createdOn'] = $e_.createdOn
                    $obj['lastModifiedBy'] = $e_.lastModifiedBy
                    $obj['lastModifiedOn'] = $e_.lastModifiedOn
                    $obj['projectName'] = $ProjectName
                    $obj['collectionUri'] = $CollectionUri
                    if ($e_.continuationToken) {
                        $obj['continuationToken'] = $e_.continuationToken
                    }
                    # Output the environment object
                    [PSCustomObject]$obj
                }
            } catch {
                if ($_.ErrorDetails.Message -match 'EnvironmentNotFoundException') {
                    Write-Warning "Environment with ID $Id does not exist, skipping."
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
