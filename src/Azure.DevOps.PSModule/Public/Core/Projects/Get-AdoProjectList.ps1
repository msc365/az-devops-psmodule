function Get-AdoProjectList {
    <#
    .SYNOPSIS
        Get all projects.

    .DESCRIPTION
        This function retrieves all projects for a given Azure DevOps organization through REST API.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Object[]

        A list of project objects.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/list

    .EXAMPLE
        $projects = Get-AdoProjectList -ApiVersion '7.1'
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Skip = 0,

        [Parameter(Mandatory = $false)]
        [int]$Top = 10,

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command      : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  Skip       : {0}' -f $Skip)
        Write-Debug ('  Top        : {0}' -f $Top)
        Write-Debug ('  ApiVersion : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/_apis/projects?$skip={1}&$top={2}&api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), $Skip, $Top, $ApiVersion)

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
