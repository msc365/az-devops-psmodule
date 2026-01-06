function New-AdoServiceEndpoint {
    <#
    .SYNOPSIS
        Creates a new service endpoint in an Azure DevOps project.

    .DESCRIPTION
        This cmdlet creates a new service endpoint in an Azure DevOps project. Service endpoints provide connection details
        for external services like Azure subscriptions, GitHub, Docker registries, etc.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER Configuration
        Mandatory. The configuration for the service endpoint as a PSCustomObject.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/create

    .EXAMPLE
        $config = [PSCustomObject]@{
            data                 = [PSCustomObject]@{
                creationMode     = 'Manual'
                environment      = 'AzureCloud'
                scopeLevel       = 'Subscription'
                subscriptionId   = '00000000-0000-0000-0000-000000000000'
                subscriptionName = 'my-subscription-1'
            }
            name                             = 'my-endpoint-1'
            type                             = 'AzureRM'
            url                              = 'https://management.azure.com/'
            authorization                    = [PSCustomObject]@{
                parameters = [PSCustomObject]@{
                    serviceprincipalid = '11111111-1111-1111-1111-111111111111'
                    tenantid           = '22222222-2222-2222-2222-222222222222'
                    scope              = '/subscriptions/00000000-0000-0000-0000-000000000000'
                }
                scheme     = 'WorkloadIdentityFederation'
            }
            isShared                         = $false
            serviceEndpointProjectReferences = [PSCustomObject[]]@(
                [PSCustomObject]@{
                    name             = 'my-endpoint-1'
                    projectReference = [PSCustomObject]@{
                        id   = '33333333-3333-3333-3333-333333333333'
                        name = 'my-project-1'
                    }
                }
            )
        }

        New-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Configuration $config

        Creates an Azure Resource Manager service endpoint with workload identity federation.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [PSCustomObject]$Configuration,

        [Parameter()]
        [Alias('ApiVersion', 'Api')]
        [ValidateSet('7.1', '7.2-preview.4')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("Configuration: $($Configuration | ConvertTo-Json -Depth 10)")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })
    }

    process {
        try {
            $endpointName = $Configuration.name
            $projectName = $Configuration.serviceEndpointProjectReferences[0].projectReference.name

            $params = @{
                Uri     = "$CollectionUri/_apis/serviceendpoint/endpoints"
                Version = $Version
                Method  = 'POST'
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, "Create service endpoint: $endpointName")) {
                try {
                    $results = $Configuration | Invoke-AdoRestMethod @params

                    [PSCustomObject]@{
                        id                               = $results.id
                        name                             = $results.name
                        type                             = $results.type
                        description                      = $results.description
                        authorization                    = $results.authorization
                        url                              = $results.url
                        isShared                         = $results.isShared
                        isReady                          = $results.isReady
                        owner                            = $results.owner
                        data                             = $results.data
                        serviceEndpointProjectReferences = $results.serviceEndpointProjectReferences
                        projectName                      = $projectName
                        collectionUri                    = $CollectionUri
                    }
                } catch {
                    if ($_.ErrorDetails.Message -match 'DuplicateServiceConnectionException') {
                        Write-Warning "Service endpoint '$endpointName' already exists, trying to get it."

                        $params.Method = 'GET'
                        $params.Uri = "$CollectionUri/$projectName/_apis/serviceendpoint/endpoints"
                        $params.QueryParameters = "endpointNames=$endpointName"

                        $results = (Invoke-AdoRestMethod @params).value

                        [PSCustomObject]@{
                            id                               = $results.id
                            name                             = $results.name
                            type                             = $results.type
                            description                      = $results.description
                            authorization                    = $results.authorization
                            isShared                         = $results.isShared
                            url                              = $results.url
                            isReady                          = $results.isReady
                            owner                            = $results.owner
                            data                             = $results.data
                            serviceEndpointProjectReferences = $results.serviceEndpointProjectReferences
                            projectName                      = $projectName
                            collectionUri                    = $CollectionUri
                        }
                    } else {
                        throw $_
                    }
                }
            } else {
                $params.Body = $Configuration
                Write-Verbose "Calling Invoke-AdoRestMethod with $($params | ConvertTo-Json -Depth 10)"
            }
        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
