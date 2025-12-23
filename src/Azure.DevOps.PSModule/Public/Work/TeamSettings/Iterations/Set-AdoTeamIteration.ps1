# cSpell: ignore teamsettings
function Set-AdoTeamIteration {
    <#
    .SYNOPSIS
        Set a specific team iteration for a given project or team in Azure DevOps.

    .DESCRIPTION
        This cmdlet sets a specific team iteration by its ID for a specified project or team in Azure DevOps.

    .PARAMETER ProjectId
        The ID or name of the Azure DevOps project.

    .PARAMETER TeamId
        The ID or name of the Azure DevOps team. If not specified, the default team for the project will be used.

    .PARAMETER IterationId
        The ID of the iteration to set.

    .PARAMETER ApiVersion
        The API version to use for the request. Default is '7.1'.

    .NOTES
        Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/work/iterations/post-team-iteration

    .EXAMPLE
        Set-AdoTeamIteration -ProjectId -ProjectId 'my-project' -TeamId 'my-team' -IterationId $iterationId

        Sets the specified iteration for the given team in the specified project.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory = $false)]
        [string]$TeamId,

        [Parameter(Mandatory)]
        [string]$IterationId,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command       : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId   : {0}' -f $ProjectId)
        Write-Debug ('  TeamId      : {0}' -f $TeamId)
        Write-Debug ('  IterationId : {0}' -f $IterationId)
        Write-Debug ('  ApiVersion  : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/{2}/_apis/work/teamsettings/iterations/?api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                [uri]::EscapeUriString($TeamId), $ApiVersion)

            $params = @{
                Method      = 'POST'
                Uri         = $azDevOpsUri
                ContentType = 'application/json'
                Headers     = @{
                    'Accept'        = 'application/json'
                    'Authorization' = (ConvertFrom-SecureString -SecureString $AzDevOpsAuth -AsPlainText)
                }
                Body        = (@{ id = $IterationId } | ConvertTo-Json -Depth 3 -Compress)
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
