function Set-AdoFeatureState {
    <#
    .SYNOPSIS
        Set the feature state for an Azure DevOps project feature.

    .DESCRIPTION
        This function sets the feature state for an Azure DevOps project feature through REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the project.

    .PARAMETER Feature
        Mandatory. The feature to set the state for. Valid values are 'Boards', 'Repos', 'Pipelines', 'TestPlans', 'Artifacts'.

    .PARAMETER FeatureState
        Optional. The state to set the feature to. Default is 'Disabled'.

    .PARAMETER ApiVersion
        Optional. The API version to use. Default is '4.1-preview.1'.

    .OUTPUTS
        System.Object

        Object representing the response from the Azure DevOps REST API.

    .NOTES
        - Turning off a feature hides this service for all members of this project.
          If you choose to enable this service later, all your existing data will be available.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/feature-management/featurestatesquery

    .EXAMPLE
        Set-AdoFeatureState -ProjectId 'my-project-002' -Feature 'Boards' -FeatureState 'Disabled'

        Sets the feature state for Boards to Disabled for the specified project.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [ValidateSet('boards', 'repos', 'pipelines', 'testPlans', 'artifacts')]
        [string]$Feature,

        [Parameter(Mandatory = $false)]
        [ValidateSet('enabled', 'disabled')]
        [string]$FeatureState = 'disabled',

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('4.1-preview.1')]
        [string]$ApiVersion = '4.1-preview.1'
    )

    begin {
        Write-Debug ('Command        : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId    : {0}' -f $ProjectId)
        Write-Debug ('  Feature      : {0}' -f $Feature)
        Write-Debug ('  FeatureState : {0}' -f $FeatureState)
        Write-Debug ('  ApiVersion   : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            try {
                [System.Guid]::Parse($ProjectId) | Out-Null
            } catch {
                $ProjectId = (Get-AdoProject -ProjectName $ProjectId).Id
            }

            # Get the feature ID
            $featureId = switch ($Feature.ToLower()) {
                'boards' { 'ms.vss-work.agile' }
                'repos' { 'ms.vss-code.version-control' }
                'pipelines' { 'ms.vss-build.pipelines' }
                'testPlans' { 'ms.vss-test-web.test' }
                'artifacts' { 'ms.azure-artifacts.feature' }
            }

            $uriFormat = '{0}/_apis/FeatureManagement/FeatureStates/host/project/{1}/{2}?api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), $ProjectId, $featureId, $ApiVersion)

            $body = @{
                featureId = $featureId
                scope     = @{
                    settingScope = 'project'
                    userScoped   = $false
                }
                state     = ($FeatureState -eq 'enabled' ? 1 : 0)
            }

            $params = @{
                Method      = 'PATCH'
                Uri         = $azDevOpsUri
                ContentType = 'application/json'
                Headers     = @{
                    'Accept'        = 'application/json'
                    'Authorization' = (ConvertFrom-SecureString -SecureString $AzDevOpsAuth -AsPlainText)
                }
                Body        = ($body | ConvertTo-Json -Depth 3 -Compress)
            }

            $response = Invoke-RestMethod @params -Verbose:$VerbosePreference

            return $response

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
