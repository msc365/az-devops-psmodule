# cSpell: ignore teamsettings
function Set-AdoTeamSettings {
    <#
    .SYNOPSIS
        Update the settings for a team in Azure DevOps.

    .DESCRIPTION
        Update the settings for a team in Azure DevOps by sending a PATCH request to the Azure DevOps REST API.

    .PARAMETER ProjectId
        The ID or name of the project containing the team.

    .PARAMETER TeamId
        The ID or name of the team to update.

    .PARAMETER TeamSettings
        A string representing the team settings to be updated in JSON format.

    .PARAMETER ApiVersion
        The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamsettings/update

        .EXAMPLE
        $params = @{
            bugsBehavior          = 'asRequirements'
            backlogVisibilities   = @{
                'Microsoft.EpicCategory'        = $false
                'Microsoft.FeatureCategory'     = $true
                'Microsoft.RequirementCategory' = $true
            }
            defaultIterationMacro = '@currentIteration'
            workingDays           = @(
                'monday'
                'tuesday'
                'wednesday'
                'thursday'
                'friday'
            )
        } | ConvertTo-Json -Depth 5 -Compress

        Set-AdoTeamSettings -ProjectId 'my-project-1' -TeamId 'my-other-team' -TeamSettings $params

        Updates the settings for the team "my-other-team" in the project "my-project" with the specified parameters.

        The backlogIteration is set to the root iteration, bugs are treated as requirements, and working days are set to Monday through Friday.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [string]$TeamId,

        [Parameter(Mandatory)]
        [string]$TeamSettings,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command        : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId    : {0}' -f $ProjectId)
        Write-Debug ('  TeamId       : {0}' -f $TeamId)
        Write-Debug ('  ApiVersion   : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            if (-not (Test-Json $TeamSettings)) {
                throw 'Invalid JSON for team settings string.'
            }

            $uriFormat = '{0}/{1}/{2}/_apis/work/teamsettings?api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                [uri]::EscapeUriString($TeamId), $ApiVersion)

            $params = @{
                Method      = 'PATCH'
                Uri         = $azDevOpsUri
                ContentType = 'application/json'
                Headers     = @{
                    'Accept'        = 'application/json'
                    'Authorization' = (ConvertFrom-SecureString -SecureString $AzDevOpsAuth -AsPlainText)
                }
                Body        = $TeamSettings
            }

            $response = Invoke-RestMethod @params -Verbose:$VerbosePreference

            return $response

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
