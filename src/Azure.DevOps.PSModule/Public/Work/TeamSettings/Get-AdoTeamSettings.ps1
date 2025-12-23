# cSpell: ignore teamsettings
function Get-AdoTeamSettings {
    <#
    .SYNOPSIS
        Gets the settings for a team in an Azure DevOps project.

    .DESCRIPTION
        The Get-AdoTeamSettings cmdlet retrieves the settings for a specified team within an Azure DevOps project.

    .PARAMETER ProjectId
        The ID or name of the Azure DevOps project.

    .PARAMETER TeamId
        The ID or name of the team within the specified project.

    .PARAMETER ApiVersion
        The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamsettings/get

    .EXAMPLE
        Get-AdoTeamSettings -ProjectId "my-project" -TeamId "my-team"

        Retrieves the settings for the team "my-team" in the project "my-project".
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [string]$TeamId,

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

            $uriFormat = '{0}/{1}/{2}/_apis/work/teamsettings?api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                [uri]::EscapeUriString($TeamId), $ApiVersion)

            $params = @{
                Method  = 'GET'
                Uri     = $azDevOpsUri
                Headers = @{
                    'Accept'        = 'application/json'
                    'Authorization' = (ConvertFrom-SecureString -SecureString $AzDevOpsAuth -AsPlainText)
                }
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
