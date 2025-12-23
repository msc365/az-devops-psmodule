function Set-AdoTeam {
    <#
    .SYNOPSIS
        Update a team in an Azure DevOps project.

    .DESCRIPTION
        This function updates a team in an Azure DevOps project through REST API.

    .PARAMETER ProjectId
        Mandatory. The unique identifier or name of the project.

    .PARAMETER TeamId
        Mandatory. The unique identifier of the team.

    .PARAMETER Name
        Mandatory. The name of the team.

    .PARAMETER Description
        Optional. The description of the team.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Object

        The updated team object.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/update

    .EXAMPLE
        Set-AdoTeam -ProjectId 'my-project' -TeamId '00000000-0000-0000-0000-000000000000' -Name 'my-team'

        Update the team with the specified TeamId in the given project to have the name 'my-team'.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [string]$TeamId,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('7.1', '7.2-preview.3')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command       : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId   : {0}' -f $ProjectId)
        Write-Debug ('  TeamId      : {0}' -f $TeamId)
        Write-Debug ('  Name        : {0}' -f $Name)
        Write-Debug ('  Description : {0}' -f $Description)
        Write-Debug ('  ApiVersion  : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/_apis/projects/{1}/teams/{2}?api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), $ProjectId, $TeamId, $ApiVersion)

            $body = @{
                name = $Name
            }

            if (-not [string]::IsNullOrEmpty($Description)) {
                $body.Description = $Description
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
