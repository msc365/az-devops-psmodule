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
        PSCustomObject

        Object representing the feature states for the specified Azure DevOps project.

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
    [CmdletBinding(SupportsShouldProcess)]
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

            $body = @{
                featureIds    = @(
                    'ms.vss-work.agile'           # Boards
                    'ms.vss-code.version-control' # Repos
                    'ms.vss-build.pipelines'      # Pipelines
                    'ms.vss-test-web.test'        # Test Plans
                    'ms.azure-artifacts.feature'  # Artifacts
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
                Body    = ($body | ConvertTo-Json -Depth 3 -Compress)
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, "Get Feature States for project '$ProjectName'")) {
                $results = Invoke-AdoRestMethod @params

                # Process and enhance each feature state result
                foreach ($fs_ in $results.featureStates) {
                    $featureName = switch ($fs_.featureId) {
                        'ms.vss-work.agile' { 'Boards' }
                        'ms.vss-code.version-control' { 'Repos' }
                        'ms.vss-build.pipelines' { 'Pipelines' }
                        'ms.vss-test-web.test' { 'TestPlans' }
                        'ms.azure-artifacts.feature' { 'Artifacts' }
                        default { $_.featureId }
                    }

                    [PSCustomObject]@{
                        feature       = $featureName
                        featureId     = $fs_.featureId
                        state         = ($fs_.state -eq 1 ? 'enabled' : 'disabled')
                        projectName   = $ProjectName
                        projectId     = $projectId
                        collectionUri = $CollectionUri
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
