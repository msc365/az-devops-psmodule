function Remove-AdoTeam {
    <#
    .SYNOPSIS
        Remove a team from an Azure DevOps project.

    .DESCRIPTION
        This function removes a team from an Azure DevOps project through REST API.

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
        $team = Get-AdoTeam -ProjectId 'my-project-001' -TeamId '00000000-0000-0000-0000-000000000000'
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
                Method  = 'DELETE'
                Uri     = $azDevOpsUri
                Headers = ((ConvertFrom-SecureString -SecureString $global:AzDevOpsHeaders -AsPlainText) | ConvertFrom-Json -AsHashtable)
            }

            $response = Invoke-RestMethod @params -Verbose:$VerbosePreference

            $status = $response.status

            while ($status -ne 'succeeded') {
                Write-Verbose 'Checking team deletion status...'
                Start-Sleep -Seconds 2

                $response = Invoke-RestMethod -Method GET -Uri $response.url -Headers $params.Headers -Verbose:$VerbosePreference
                $status = $response.status

                if ($status -eq 'failed') {
                    Write-Error -Message ('Team deletion failed {0}' -f $PSItem.Exception.Message)
                }
            }

            return ('Team {0} removed' -f $TeamId)

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
