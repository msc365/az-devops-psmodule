function Get-AdoTeam {
    <#
    .SYNOPSIS
        Get teams or the team details for a given Azure DevOps project.

    .DESCRIPTION
        This function retrieves all teams or the team details for a given Azure DevOps project through REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the project.

    .PARAMETER TeamId
        Mandatory. The ID or name of the team.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Object

        The team details object.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/get

    .EXAMPLE
        $team = Get-AdoTeam -ProjectId 'my-project' -TeamId '00000000-0000-0000-0000-000000000000'
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
        [ValidateSet('5.1', '7.1-preview.4', '7.2-preview.3')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command       : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId   : {0}' -f $ProjectId)
        Write-Debug ('  TeamId      : {0}' -f $TeamId)
        Write-Debug ('  ApiVersion  : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/_apis/projects/{1}/teams/{2}?api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                $TeamId, $ApiVersion)

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
            if ($_.Exception.StatusCode -eq 'NotFound') {
                Write-Verbose 'Team not found.'
                return $null
            }
            throw $_
        }
    }

    end {
        Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
