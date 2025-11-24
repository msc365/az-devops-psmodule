function Get-AdoRepository {
    <#
    .SYNOPSIS
        Get the repository.

    .DESCRIPTION
        This function retrieves the repository details as GitRepository object for an Azure DevOps repository through REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the project.

    .PARAMETER Name
        Mandatory. The ID or name of the repository.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/git/repositories/get-repository

    .EXAMPLE
        Get-AdoRepository -ProjectId 'my-project' -Name 'my-repo-001'

        Retrieves the repository 'my-repo-001' from project 'my-project'.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command      : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId  : {0}' -f $ProjectId)
        Write-Debug ('  Name       : {0}' -f $Name)
        Write-Debug ('  ApiVersion : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/_apis/git/repositories/{2}?api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeDataString($ProjectId), [uri]::EscapeDataString($Name), $ApiVersion)

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
        Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
