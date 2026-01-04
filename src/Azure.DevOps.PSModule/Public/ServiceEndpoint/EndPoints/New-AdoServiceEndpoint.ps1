function New-AdoServiceEndpoint {
    <#
    .SYNOPSIS
        Create a new service endpoint in an Azure DevOps project.

    .DESCRIPTION
        This function creates a new service endpoint in an Azure DevOps project through REST API.

    .PARAMETER Configuration
        Mandatory. The configuration JSON for the service endpoint.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Object

        The created service endpoint object.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/create?view=azure-devops

    .EXAMPLE
        $config = [ordered]@{
            data                 = [ordered]@{
                creationMode     = 'Manual'
                environment      = 'AzureCloud'
                scopeLevel       = 'Subscription'
                subscriptionId   = '00000000-0000-0000-0000-000000000000'
                subscriptionName = 'sub-alz-workload-dev-weu'
                # scopeLevel          = 'ManagementGroup'
                # managementGroupId   = '11111111-1111-1111-1111-111111111111'
                # managementGroupName = 'Tenant Root Group'
            }
            name                             = 'id-msc-adortagnt-prd'
            type                             = 'AzureRM'
            url                              = 'https://management.azure.com/'
            authorization                    = [ordered]@{
                parameters = [ordered]@{
                    serviceprincipalid = '22222222-2222-2222-2222-222222222222'
                    tenantid           = '11111111-1111-1111-1111-111111111111'
                    scope              = '/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/rg-my-avengers-weu'
                }
                scheme     = 'WorkloadIdentityFederation'
            }
            isShared                         = $false
            serviceEndpointProjectReferences = @(
                [ordered]@{
                    name             = 'id-msc-adortagnt-prd'
                    projectReference = [ordered]@{
                        id   = '33333333-3333-3333-3333-333333333333'
                        name = 'my-project-1'
                    }
                }
            )
        } | ConvertTo-Json -Depth 5 -Compress

        New-AdoServiceEndpoint -Configuration $objConfig

        This example demonstrates how to create a new Azure Resource Manager service endpoint in an Azure DevOps project using a configuration object.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$Configuration,

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('7.1', '7.2-preview.4')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command         : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  Configuration : {0}' -f $Configuration)
        Write-Debug ('  ApiVersion    : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            if (-not (Test-Json $Configuration)) {
                throw 'Invalid JSON for service endpoint configuration object.'
            }

            $uriFormat = '{0}/_apis/serviceendpoint/endpoints?api-version={1}'
            $azDevopsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), $ApiVersion)

            $params = @{
                Method      = 'POST'
                Uri         = $azDevopsUri
                ContentType = 'application/json'
                Headers     = @{
                    'Accept'        = 'application/json'
                    'Authorization' = (ConvertFrom-SecureString -SecureString $AzDevOpsAuth -AsPlainText)
                }
                Body        = $Configuration
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
