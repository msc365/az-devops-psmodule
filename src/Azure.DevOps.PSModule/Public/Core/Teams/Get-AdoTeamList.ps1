function Get-AdoTeamList {
    <#
    .SYNOPSIS
        Get all teams for a given Azure DevOps project.

    .DESCRIPTION
        This function retrieves all teams for a given Azure DevOps project through REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the project.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Object[]

        A list of team objects.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/get-teams

    .EXAMPLE
        $teams = Get-AdoTeamList -ProjectId 'my-project'
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory = $false)]
        [int]$Skip = 0,

        [Parameter(Mandatory = $false)]
        [int]$Top = 10,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('5.1', '7.1-preview.4', '7.2-preview.3')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command       : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId   : {0}' -f $ProjectId)
        Write-Debug ('  Skip        : {0}' -f $Skip)
        Write-Debug ('  Top         : {0}' -f $Top)
        Write-Debug ('  ApiVersion  : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/_apis/projects/{1}/teams?$skip={2}&$top={3}&api-version={4}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                $Skip, $Top, $ApiVersion)

            $params = @{
                Method  = 'GET'
                Uri     = $azDevOpsUri
                Headers = ((ConvertFrom-SecureString -SecureString $global:AzDevOpsHeaders -AsPlainText) | ConvertFrom-Json -AsHashtable)
            }

            $response = Invoke-RestMethod @params -Verbose:$VerbosePreference

            return $response.value

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
