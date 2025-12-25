function Get-AdoCheckConfigurationList {
    <#
    .SYNOPSIS
        Get a list of check configurations for a specific resource.

    .DESCRIPTION
        This function retrieves check configurations for a specified resource within an Azure DevOps project.
        You need to provide the resource type and resource ID to filter the results.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the project.

    .PARAMETER ResourceType
        Mandatory. The type of the resource to filter the results. E.g., 'environment'.

    .PARAMETER ResourceId
        Mandatory. The ID of the resource to filter the results.

    .PARAMETER Expands
        Optional. Specifies additional details to include in the response. Default is 'none'.

        Valid values are 'none' and 'settings'.

    .PARAMETER ApiVersion
        Optional. The API version to use for the request. Default is '7.2-preview.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/list

    .EXAMPLE
        Get-AdoCheckConfigurationList -ProjectId "MyProject" -ResourceType "environment" -ResourceId "1" -Expands "settings"

        Retrieves the check configurations for the specified environment resource in the project "MyProject".

    .NOTES
        This cmdlet requires an active connection to an Azure DevOps organization established via Connect-AdoOrganization.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [string]$ResourceType,

        [Parameter(Mandatory)]
        [string]$ResourceId,

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
        Write-Debug ('  ResourceType : {0}' -f $ResourceType)
        Write-Debug ('  ResourceId   : {0}' -f $ResourceId)
        Write-Debug ('  Expands      : {0}' -f $Expands)
        Write-Debug ('  ApiVersion   : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/_apis/pipelines/checks/configurations?resourceType={2}&resourceId={3}&$expand={4}&api-version={5}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                [uri]::EscapeUriString($ResourceType), [uri]::EscapeUriString($ResourceId), $Expands, $ApiVersion)

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
