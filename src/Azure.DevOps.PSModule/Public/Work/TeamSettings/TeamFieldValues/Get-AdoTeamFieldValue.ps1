# cSpell: words teamfieldvalues, teamsettings
function Get-AdoTeamFieldValue {
    <#
    .SYNOPSIS
        Gets the team field value settings for a team in an Azure DevOps project.

    .DESCRIPTION
        This function retrieves the team field value settings for a specified team in an Azure DevOps project using the REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the Azure DevOps project.

    .PARAMETER TeamId
        Optional. The ID or name of the team within the project. If not specified, the default team is used.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Object

        The team field value settings for the specified team.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamfieldvalues/get

    .NOTES
        - Requires an active connection to Azure DevOps using Connect-AdoOrganization.

    .EXAMPLE
        Get-AdoTeamFieldValue -ProjectId 'e2egov-fantastic-four

        This example retrieves the team field values for the default team in the specified project.

    .EXAMPLE
        Get-AdoTeamFieldValue -ProjectId 'e2egov-fantastic-four' -TeamId 'Mister Fantastic'

        This example retrieves the team field values for the specified team in the specified project.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory = $false)]
        [string]$TeamId,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command      : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId  : {0}' -f $ProjectId)
        Write-Debug ('  TeamId     : {0}' -f $TeamId)
        Write-Debug ('  ApiVersion : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/{2}/_apis/work/teamsettings/teamfieldvalues?api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                [uri]::EscapeUriString($TeamId), $ApiVersion)

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
