function Get-AdoServiceEndpointByName {
    <#
    .SYNOPSIS
        Get the service endpoint details for an Azure DevOps service endpoint.

    .DESCRIPTION
        This function retrieves the service endpoint details for an Azure DevOps service endpoint through REST API.

    .PARAMETER ProjectId
        Mandatory. The unique identifier or name of the project.

    .PARAMETER EndpointNames
        Mandatory. The names of the service endpoints.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Object[]

        Objects representing the service endpoints.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/get-service-endpoints-by-names

    .EXAMPLE
        $endpoint = Get-AdoServiceEndpoint -ProjectId 'my-project' -EndpointNames 'id-my-adortagent'

        Retrieves the service endpoint with the name 'id-my-adortagent' in the project 'my-project'.

    .EXAMPLE
        $endpoints = Get-AdoServiceEndpoint -ProjectId 'my-project' -EndpointNames 'id-my-adortagent', 'id-my-other-endpoint'

        Retrieves the service endpoints with the names 'id-my-adortagent' and 'id-my-other-endpoint' in the project 'my-project'.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [string[]]$EndpointNames,

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('7.1', '7.2-preview.4')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command         : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId     : {0}' -f $ProjectId)
        Write-Debug ('  EndpointNames : {0}' -f ($EndpointNames -join ','))
        Write-Debug ('  ApiVersion    : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/_apis/serviceendpoint/endpoints?endpointNames={2}&api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeDataString($ProjectId),
                ($EndpointNames -join ','), $ApiVersion)

            $params = @{
                Method  = 'GET'
                Uri     = $azDevOpsUri
                Headers = ((ConvertFrom-SecureString -SecureString $global:AzDevOpsHeaders -AsPlainText) | ConvertFrom-Json -AsHashtable)
            }

            $response = (Invoke-RestMethod @params -Verbose:$VerbosePreference )

            return $response.value

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
