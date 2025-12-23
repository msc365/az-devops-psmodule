function New-AdoTeam {
    <#
    .SYNOPSIS
        Create a new team in an Azure DevOps project.

    .DESCRIPTION
        This function creates a new team in an Azure DevOps project through REST API.

    .PARAMETER Name
        Mandatory. The name of the team to create.

    .PARAMETER Description
        Optional. The description of the team.

    .PARAMETER ProjectId
        Mandatory. The unique identifier or name of the project.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Object

        The created team object.

    .NOTES
        - The team name must be unique within the project.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/create

    .EXAMPLE
        New-AdoTeam -ProjectId 'my-project' -Name 'my-team'

        Creates a new team named 'my-team' in the project with ID 'my-project'.

    .EXAMPLE
        New-AdoTeam -ProjectId 'my-project' -Name 'my-team' -Description 'My new team'

        Creates a new team named 'my-team' with the description 'My new team' in the project with ID 'my-project'.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('5.1', '7.1-preview.4', '7.2-preview.3')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command      : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId  : {0}' -f $ProjectId)
        Write-Debug ('  Name       : {0}' -f $Name)
        Write-Debug ('  Description: {0}' -f $Description)
        Write-Debug ('  ApiVersion : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/_apis/projects/{1}/teams?api-version={2}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                $ApiVersion)

            $body = @{
                name        = $Name
                description = $Description
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
