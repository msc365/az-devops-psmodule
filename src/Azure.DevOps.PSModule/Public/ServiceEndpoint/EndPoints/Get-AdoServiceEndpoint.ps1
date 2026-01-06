function Get-AdoServiceEndpoint {
    <#
    .SYNOPSIS
        Retrieves Azure DevOps service endpoint details by name.

    .DESCRIPTION
        This cmdlet retrieves service endpoint details for one or more Azure DevOps service endpoints by their names within a specified project.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The ID or name of the project.

    .PARAMETER Ids
        Optional. The unique identifiers of the service endpoints to retrieve.

    .PARAMETER Names
        Optional. The names of the service endpoints to retrieve.

    .PARAMETER Owner
        Optional. Filter by service endpoint owner. Valid values are 'library' and 'agentcloud'.

    .PARAMETER Type
        Optional. Filter by service endpoint type, e.g., 'generic', 'azurerm', etc.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/get
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/get-service-endpoints
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/get-service-endpoints-by-names

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        Get-AdoServiceEndpoint @params -Name 'my-endpoint-1'

        Retrieves the service endpoint with the name 'my-endpoint-1' in the project 'my-project-1'.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        Get-AdoServiceEndpoint @params -Name 'my-endpoint-1', 'id-my-other-endpoint'

        Retrieves multiple service endpoints by their names in the project 'my-project-1'.

    .EXAMPLE
        'endpoint1', 'endpoint2' | Get-AdoServiceEndpoint -ProjectName 'my-project-1'

        Retrieves multiple service endpoints by piping their names to the cmdlet.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ByNames')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter( ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByIds')]
        [Alias('EndpointIds')]
        [string[]]$Ids,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByIds')]
        [ValidateSet('none', 'manage', 'use', 'view')]
        [string]$ActionFilter,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByNames', ValueFromPipeline)]
        [Alias('EndpointNames')]
        [string[]]$Names,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$AuthSchemes,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('library', 'agentcloud')]
        [string]$Owner,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Type,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$IncludeFailed,

        [Parameter()]
        [Alias('ApiVersion', 'Api')]
        [ValidateSet('7.1', '7.2-preview.4')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Ids: $($Ids -join ',')")
        Write-Debug ("Names: $($Names -join ',')")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $QueryParameters = [System.Collections.Generic.List[string]]::new()
            if ($PSCmdlet.ParameterSetName -eq 'ByIds') {
                if ($Ids) {
                    $QueryParameters.Add("endpointIds=$($Ids -join ',')")
                }
                if ($ActionFilter) {
                    $QueryParameters.Add("actionFilter=$ActionFilter")
                }
            }
            if ($PSCmdlet.ParameterSetName -eq 'ByNames') {
                if ($Names) {
                    $QueryParameters.Add("endpointNames=$($Names -join ',')")
                }
            }
            if ($AuthSchemes) {
                $QueryParameters.Add("authSchemes=$AuthSchemes")
            }
            if ($Owner) {
                $QueryParameters.Add("owner=$Owner")
            }
            if ($Type) {
                $QueryParameters.Add("type=$Type")
            }
            if ($IncludeFailed.IsPresent) {
                $QueryParameters.Add('includeFailed=true')
            }

            $params = @{
                Uri             = "$CollectionUri/$ProjectName/_apis/serviceendpoint/endpoints"
                Version         = $Version
                QueryParameters = if ($QueryParameters.Count -gt 0) { $QueryParameters -join '&' } else { $null }
                Method          = 'GET'
            }

            $shouldProcessOperation = if ($Names) {
                "Get service endpoint(s) '$($Names -join ', ')'"
            } elseif ($Ids) {
                "Get service endpoint(s) '$($Ids -join ', ')'"
            } else {
                'Get service endpoints'
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, $shouldProcessOperation)) {
                try {
                    $results = Invoke-AdoRestMethod @params
                    $items = $results.value

                    foreach ($i_ in $items) {
                        [PSCustomObject]@{
                            id                               = $i_.id
                            name                             = $i_.name
                            type                             = $i_.type
                            description                      = $i_.description
                            authorization                    = $i_.authorization
                            isShared                         = $i_.isShared
                            isReady                          = $i_.isReady
                            owner                            = $i_.owner
                            data                             = $i_.data
                            serviceEndpointProjectReferences = $i_.serviceEndpointProjectReferences
                            projectName                      = $ProjectName
                            collectionUri                    = $CollectionUri
                        }
                    }
                } catch {
                    if ($_.ErrorDetails.Message -match 'NotFoundException') {
                        if ($PSCmdlet.ParameterSetName -eq 'ByIds') {
                            Write-Warning "Service endpoint(s) with id(s) '$($Ids -join ', ')' do not exist in project $ProjectName, skipping."
                        } else {
                            Write-Warning "Service endpoint(s) with name(s) '$($Names -join ', ')' do not exist in project $ProjectName, skipping."
                        }
                    } else {
                        throw $_
                    }
                }
            } else {
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

