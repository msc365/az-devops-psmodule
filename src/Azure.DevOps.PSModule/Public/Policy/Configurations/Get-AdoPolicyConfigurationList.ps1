function Get-AdoPolicyConfigurationList {
    <#
    .SYNOPSIS
        Gets policy configurations for an Azure DevOps project.

    .DESCRIPTION
        This function retrieves a list of policy configurations for an Azure DevOps project through REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the project.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/configurations/get

    .EXAMPLE
        $configurations = Get-AdoPolicyConfiguration -ProjectId 'my-project-1'
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command       : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId   : {0}' -f $ProjectId)
        Write-Debug ('  ApiVersion  : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/_apis/policy/configurations?api-version={2}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), $ProjectId, $ApiVersion)

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
            throw $_
        }
    }

    end {
        Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
