function Get-AdoCheckConfigurationQuery {
    <#
    .SYNOPSIS
        Retrieves a list of check configurations for specified resources.

    .DESCRIPTION
        This function retrieves check configurations for the specified resources within an Azure DevOps project.
        You can specify multiple resources by providing their IDs and types.

    .PARAMETER ProjectId
        The ID or name of the project.

    .PARAMETER Resources
        A string representing the resources to query in JSON format.

    .PARAMETER Expands
        Specifies additional details to include in the response. Default is 'none'.

        Valid values are 'none' and 'settings'.

    .PARAMETER ApiVersion
        The API version to use for the request. Default is '7.2-preview.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/query

    .EXAMPLE
        Get-AdoCheckConfigurationQuery -ProjectId "MyProject" -Resources '[{"id":"1","type":"queue"},{"id":"2","type":"environment"}]' -Expands "settings"

        Retrieves the check configurations for the specified environment resource in the project "MyProject".

    .NOTES
        This cmdlet requires an active connection to an Azure DevOps organization established via Connect-AdoOrganization.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [string]$Resources,

        [Parameter(Mandatory = $false)]
        [ValidateSet('none', 'settings')]
        [string]$Expands = 'none',

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.2-preview.1')]
        [string]$ApiVersion = '7.2-preview.1'
    )

    begin {
        Write-Debug ('Command        : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId    : {0}' -f $ProjectId)
        Write-Debug ('  Expands      : {0}' -f $Expands)
        Write-Debug ('  ApiVersion   : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            if (-not (Test-Json $Resources -ErrorAction SilentlyContinue)) {
                throw 'Invalid JSON for resources string.'
            }

            $uriFormat = '{0}/{1}/_apis/pipelines/checks/queryconfigurations?$expand={2}&api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                $Expands, $ApiVersion)

            $params = @{
                Method      = 'POST'
                Uri         = $azDevOpsUri
                ContentType = 'application/json'
                Headers     = @{
                    'Accept'        = 'application/json'
                    'Authorization' = (ConvertFrom-SecureString -SecureString $AzDevOpsAuth -AsPlainText)
                }
                Body        = $Resources
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
