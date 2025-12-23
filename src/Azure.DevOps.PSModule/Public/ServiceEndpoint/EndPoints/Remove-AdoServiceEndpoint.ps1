function Remove-AdoServiceEndpoint {
    <#
    .SYNOPSIS
        Remove a service endpoint from an Azure DevOps project.

    .DESCRIPTION
        This function removes a service endpoint from an Azure DevOps project through REST API.

    .PARAMETER EndpointId
        Mandatory. The unique identifier of the service endpoint.

    .PARAMETER ProjectIds
        Mandatory. The project Ids from which endpoint needs to be deleted.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Boolean

        Boolean indicating success or failure.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/delete?view=azure-devops

    .EXAMPLE
        Remove-AdoServiceEndpoint -EndPointId $endpoint.id -ProjectIds $project.id

        Removes the specified service endpoint from the given project.
    #>
    [CmdletBinding()]
    [OutputType([boolean])]
    param (
        [Parameter(Mandatory)]
        [string]$EndpointId,

        [Parameter(Mandatory)]
        [string[]]$ProjectIds,

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('7.1', '7.2-preview.4')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command      : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  EndpointId : {0}' -f $EndpointId)
        Write-Debug ('  ProjectIds : {0}' -f ($ProjectIds -join ','))
        Write-Debug ('  ApiVersion : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/_apis/serviceendpoint/endpoints/{1}?projectIds={2}&api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), $EndpointId, ($ProjectIds -join ',') , $ApiVersion)

            $params = @{
                Method  = 'DELETE'
                Uri     = $azDevOpsUri
                Headers = @{
                    'Accept'        = 'application/json'
                    'Authorization' = (ConvertFrom-SecureString -SecureString $AzDevOpsAuth -AsPlainText)
                }
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
