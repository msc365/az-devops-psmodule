function Remove-AdoRepository {
    <#
    .SYNOPSIS
        Remove a repository from an Azure DevOps project.

    .DESCRIPTION
        This function removes a repository from an Azure DevOps project through REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the project.

    .PARAMETER RepoId
        Mandatory. The repository ID or name.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Boolean

        Boolean indicating success.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/git/repositories/delete?view=azure-devops

    .EXAMPLE
        Remove-AdoRepository -ProjectName 'my-project' -RepositoryId $repo.id
    #>
    [CmdletBinding()]
    [OutputType([boolean])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [string]$RepositoryId,

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('7.1', '7.2-preview.2')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command      : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId  : {0}' -f $ProjectId)
        Write-Debug ('  RepoId     : {0}' -f $RepositoryId)
        Write-Debug ('  ApiVersion : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/_apis/git/repositories/{2}?api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($ProjectId), $RepositoryId, $ApiVersion)

            $params = @{
                Method  = 'DELETE'
                Uri     = $azDevOpsUri
                Headers = ((ConvertFrom-SecureString -SecureString $global:AzDevOpsHeaders -AsPlainText) | ConvertFrom-Json -AsHashtable)
            }

            Invoke-RestMethod @params -Verbose:$VerbosePreference | Out-Null
            return $true

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
