function Get-AdoFeatureState {
    <#
    .SYNOPSIS
        Get the feature states for an Azure DevOps project.

    .DESCRIPTION
        This function retrieves the feature states for an Azure DevOps project through REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the project.

    .PARAMETER ApiVersion
        The API version to use. Default is '4.1-preview.1'.

    .OUTPUTS
        System.Object

        An object representing the feature states.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/feature-management/featurestatesquery

    .EXAMPLE
        $featureState = Get-AdoFeatureState -ProjectName 'my-project-002'
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('4.1-preview.1')]
        [string]$ApiVersion = '4.1-preview.1'
    )

    begin {
        Write-Debug ('Command      : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  Projectid  : {0}' -f $ProjectId)
        Write-Debug ('  ApiVersion : {0}' -f $ApiVersion)
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
                $ProjectId = (Get-AdoProject -ProjectId $ProjectId).Id
            }

            $uriFormat = '{0}/_apis/FeatureManagement/FeatureStatesQuery/host/project/{1}?api-version={2}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), $ProjectId, $ApiVersion)

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
                    project = $ProjectId
                }
            }

            $params = @{
                Method      = 'POST'
                Uri         = $azDevOpsUri
                ContentType = 'application/json'
                Headers     = @{
                    'Accept'        = 'application/json'
                    'Authorization' = (ConvertFrom-SecureString -SecureString $AzDevOpsAuth -AsPlainText)
                }
                Body        = ($body | ConvertTo-Json -Depth 3 -Compress)
            }

            $featureStates = Invoke-RestMethod @params -Verbose:$VerbosePreference

            return $featureStates

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
