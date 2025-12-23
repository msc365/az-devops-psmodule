function Get-AdoEnvironmentList {
    <#
    .SYNOPSIS
        Get a list of Azure DevOps Pipeline Environments within a specified project.

    .DESCRIPTION
        This cmdlet retrieves a list of Azure DevOps Pipeline Environments for a given project, with optional filtering by environment name and pagination support.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the project.

    .PARAMETER Name
        Optional. The name of the environment to filter the results.

    .PARAMETER Skip
        Optional. The number of environments to skip for pagination. Default is 0.

    .PARAMETER Top
        Optional. The maximum number of environments to return. Default is 10.

    .PARAMETER ApiVersion
        Optional. The API version to use for the request. Default is '7.2-preview.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/environments/environments/list

    .EXAMPLE
        Get-AdoEnvironmentList -ProjectId "MyProject" -Top 5

        Retrieves the first 5 environments from the project "MyProject".

    .NOTES
        This cmdlet requires an active connection to an Azure DevOps organization established via Connect-AdoOrganization.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [int]$Skip = 0,

        [Parameter(Mandatory = $false)]
        [int]$Top = 10,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.2-preview.1')]
        [string]$ApiVersion = '7.2-preview.1'
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

            if (-not [string]::IsNullOrEmpty($Name)) {
                $uriFormat = '{0}/{1}/_apis/pipelines/environments?name={2}&$top={3}&api-version={4}'
                $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                    [uri]::EscapeUriString($Name), $Top, $ApiVersion)
            } else {
                $uriFormat = '{0}/{1}/_apis/pipelines/environments?$skip={2}&$top={3}&api-version={4}'
                $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                    $Skip, $Top, $ApiVersion)
            }

            $params = @{
                Method  = 'GET'
                Uri     = $azDevOpsUri
                Headers = @{
                    'Accept'        = 'application/json'
                    'Authorization' = (ConvertFrom-SecureString -SecureString $AzDevOpsAuth -AsPlainText)
                }
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
