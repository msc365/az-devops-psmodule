function Get-AdoCheckConfiguration {
    <#
    .SYNOPSIS
        Get a check configuration by ID.

    .DESCRIPTION
        This function retrieves a check configuration by its ID within an Azure DevOps project.

    .PARAMETER ProjectId
        The ID or name of the project.

    .PARAMETER Id
        The ID of the resource to retrieve the results.

    .PARAMETER Expands
        Specifies additional details to include in the response. Default is 'none'.

        Valid values are 'none' and 'settings'.

    .PARAMETER ApiVersion
        The API version to use for the request. Default is '7.2-preview.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/get

    .EXAMPLE
        Get-AdoCheckConfiguration -ProjectId "MyProject" -Id 1 -Expands "settings"

        Retrieves the check configurations for the specified resource in the project "MyProject".

    .NOTES
        This cmdlet requires an active connection to an Azure DevOps organization established via Connect-AdoOrganization.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [int32]$Id,

        [Parameter(Mandatory = $false)]
        [ValidateSet('none', 'settings')]
        [string]$Expands = 'none',

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.2-preview.1')]
        [string]$ApiVersion = '7.2-preview.1'
    )

    begin {
        Write-Debug ('Command      : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId  : {0}' -f $ProjectId)
        Write-Debug ('  Id         : {0}' -f $Id)
        Write-Debug ('  Expands    : {0}' -f $Expands)
        Write-Debug ('  ApiVersion : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/_apis/pipelines/checks/configurations/{2}?$expand={3}&api-version={4}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                $Id, $Expands, $ApiVersion)

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
