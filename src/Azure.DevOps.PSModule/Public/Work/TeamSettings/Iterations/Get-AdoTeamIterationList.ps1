# cSpell: ignore teamsettings
function Get-AdoTeamIterationList {
    <#
    .SYNOPSIS
        Get the list of team iterations for a given project or team in Azure DevOps.

    .DESCRIPTION
        This cmdlet retrieves the list of team iterations for a specified project or team in Azure DevOps.

        You can filter the iterations by timeframe (past, current, future).

    .PARAMETER ProjectId
        The ID or name of the Azure DevOps project.

    .PARAMETER TeamId
        The ID or name of the Azure DevOps team. If not specified, the default team for the project will be used.

    .PARAMETER TimeFrame
        The timeframe to filter iterations. Valid values are 'past', 'current', and 'future

    .PARAMETER ApiVersion
        The API version to use for the request. Default is '7.1'.

    .NOTES
        Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/work/iterations/list

    .EXAMPLE
        Get-AdoTeamIterationList -ProjectId 'my-project' -TeamId 'my-team' -TimeFrame 'current'

        Retrieves the current iterations for the specified team in the given project.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory = $false)]
        [string]$TeamId,

        [Parameter(Mandatory = $false)]
        [ValidateSet('past', 'current', 'future')]
        [TimeFrame]$TimeFrame,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command      : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId  : {0}' -f $ProjectId)
        Write-Debug ('  TeamId     : {0}' -f $TeamId)
        Write-Debug ('  TimeFrame  : {0}' -f $TimeFrame)
        Write-Debug ('  ApiVersion : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/{2}/_apis/work/teamsettings/iterations?$timeframe={3}&api-version={4}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                [uri]::EscapeUriString($TeamId), $TimeFrame, $ApiVersion)

            $params = @{
                Method  = 'GET'
                Uri     = $azDevOpsUri
                Headers = ((ConvertFrom-SecureString -SecureString $global:AzDevOpsHeaders -AsPlainText) | ConvertFrom-Json -AsHashtable)
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
