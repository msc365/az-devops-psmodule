function Get-AdoFeatureState {
    <#
    .SYNOPSIS
        Get the feature states for an Azure DevOps project.

    .DESCRIPTION
        This cmdlet retrieves the feature states for an Azure DevOps project through REST API.
        Returns the states for Boards, Repos, Pipelines, Test Plans, and Artifacts features.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The ID or name of the project. Defaults to the value of $env:DefaultAdoProject.

    .PARAMETER Version
        Optional. The API version to use. Default is '4.1-preview.1'.

    .OUTPUTS
        [PSCustomObject]@{
            feature       : Feature name (e.g., 'boards', 'repos', 'pipelines', 'testPlans', 'artifacts')
            state         : State of the feature (e.g., 'enabled', 'disabled')
            featureId     : Feature ID (e.g., 'ms.vss-code.version-control')
            projectName   : Name of the project
            collectionUri : Collection URI used
        }

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/feature-management/featurestatesquery

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        Get-AdoFeatureState @params

        Retrieves the feature states for the specified project.

    .EXAMPLE
        Get-AdoFeatureState -ProjectName 'my-project-1'

        Retrieves the feature states using the default collection URI from environment variable.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('4.1-preview.1')]
        [string]$Version = '4.1-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            # Get project ID if name was provided, id is required for the API call
            try {
                [System.Guid]::Parse($ProjectName) | Out-Null
                $projectId = $ProjectName
            } catch {
                $projectId = (Get-AdoProject -CollectionUri $CollectionUri -Name $ProjectName).id
                if (-not $projectId) { return }
            }

            $uri = "$CollectionUri/_apis/FeatureManagement/FeatureStatesQuery/host/project/$projectId"

            $body = [PSCustomObject]@{
                featureIds    = @(
                    'ms.vss-work.agile'           # boards
                    'ms.vss-code.version-control' # repos
                    'ms.vss-build.pipelines'      # pipelines
                    'ms.vss-test-web.test'        # testPlans
                    'ms.azure-artifacts.feature'  # artifacts
                )
                featureStates = @{}
                scopeValues   = @{
                    project = $projectId
                }
            }

            $params = @{
                Uri     = $uri
                Version = $Version
                Method  = 'POST'
                Body    = $body
            }

            $results = Invoke-AdoRestMethod @params

            foreach ($featureId in $results.featureStates.PSObject.Properties.Name) {
                # Get user-friendly feature name
                $feature = switch ($featureId) {
                    'ms.vss-work.agile' { 'boards' }
                    'ms.vss-code.version-control' { 'repos' }
                    'ms.vss-build.pipelines' { 'pipelines' }
                    'ms.vss-test-web.test' { 'testPlans' }
                    'ms.azure-artifacts.feature' { 'artifacts' }
                    default { $featureId }
                }
                # Get feature state
                $state = $results.featureStates.$featureId.state

                [PSCustomObject]@{
                    feature       = $feature
                    state         = $state
                    featureId     = $featureId
                    projectName   = $ProjectName
                    collectionUri = $CollectionUri
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
