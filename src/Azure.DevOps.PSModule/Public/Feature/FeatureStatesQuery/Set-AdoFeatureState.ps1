function Set-AdoFeatureState {
    <#
    .SYNOPSIS
        Set the feature state for an Azure DevOps project feature.

    .DESCRIPTION
        This cmdlet sets the feature state for an Azure DevOps project feature through REST API.
        Controls whether features like Boards, Repos, Pipelines, Test Plans, and Artifacts are enabled or disabled.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The ID or name of the project. Defaults to the value of $env:DefaultAdoProject.

    .PARAMETER Feature
        Mandatory. The feature to set the state for. Valid values are 'Boards', 'Repos', 'Pipelines', 'TestPlans', 'Artifacts'.

    .PARAMETER FeatureState
        Optional. The state to set the feature to. Valid values are 'Enabled' or 'Disabled'. Default is 'Disabled'.

    .PARAMETER Version
        Optional. The API version to use. Default is '4.1-preview.1'.

    .OUTPUTS
        PSCustomObject

        Object representing the updated feature state for the specified Azure DevOps project.

    .NOTES
        - Turning off a feature hides this service for all members of this project.
          If you choose to enable this service later, all your existing data will be available.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/feature-management/featurestatesquery

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            Feature       = 'boards'
            FeatureState  = 'disabled'
        }
        Set-AdoFeatureState @params

        Sets the feature state for Boards to disabled for the specified project.

    .EXAMPLE
        Set-AdoFeatureState -ProjectName 'my-project-1' -Feature 'repos' -FeatureState 'enabled'

        Enables the Repos feature for the specified project using the default collection URI.
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

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('boards', 'repos', 'pipelines', 'testPlans', 'artifacts')]
        [string]$Feature,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('enabled', 'disabled')]
        [string]$FeatureState = 'disabled',

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('4.1-preview.1')]
        [string]$Version = '4.1-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Feature: $Feature")
        Write-Debug ("FeatureState: $FeatureState")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            # Get project ID if name was provided
            try {
                [System.Guid]::Parse($ProjectName) | Out-Null
                $projectId = $ProjectName
            } catch {
                $projectId = (Get-AdoProject -CollectionUri $CollectionUri -Name $ProjectName).id
                if (-not $projectId) { return }
            }

            # Get the feature ID
            $featureId = switch ($Feature.ToLower()) {
                'boards' { 'ms.vss-work.agile' }
                'repos' { 'ms.vss-code.version-control' }
                'pipelines' { 'ms.vss-build.pipelines' }
                'testPlans' { 'ms.vss-test-web.test' }
                'artifacts' { 'ms.azure-artifacts.feature' }
            }

            $uri = "$CollectionUri/_apis/FeatureManagement/FeatureStates/host/project/$projectId/$featureId"

            $body = @{
                featureId = $featureId
                scope     = @{
                    settingScope = 'project'
                    userScoped   = $false
                }
                state     = ($FeatureState -eq 'enabled' ? 1 : 0)
            }

            $params = @{
                Uri         = $uri
                Version     = $Version
                Method      = 'PATCH'
                Body        = ($body | ConvertTo-Json -Depth 3 -Compress)
                ContentType = 'application/json'
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, "Set Feature State: $Feature to $FeatureState for Project: $ProjectName")) {
                $results = Invoke-AdoRestMethod @params

                # Add additional context to the output
                [PSCustomObject]@{
                    featureId     = $results.featureId
                    state         = ($results.state -eq 1 ? 'enabled' : 'disabled')
                    feature       = $Feature
                    projectName   = $ProjectName
                    projectId     = $projectId
                    collectionUri = $CollectionUri
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
