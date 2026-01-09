# cSpell: words classificationnodes
function Get-AdoClassificationNode {
    <#
    .SYNOPSIS
        Gets classification nodes for a project in Azure DevOps.

    .DESCRIPTION
        This cmdlet retrieves classification nodes for a specified project in Azure DevOps.
        You can retrieve the root node or specific nodes by path with optional depth control.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The ID or name of the Azure DevOps project.

    .PARAMETER StructureGroup
        Optional. The structure group of the classification node. Valid values are 'areas' or 'iterations'.

    .PARAMETER Path
        Optional. The path of the classification node to retrieve. If not specified, the root classification node is returned.

    .PARAMETER Ids
        Optional. The unique identifiers of the classification nodes to retrieve.

    .PARAMETER ErrorPolicy
        Optional. The error policy to apply when retrieving multiple nodes by IDs. Valid values are 'fail' and 'omit'.

    .PARAMETER Depth
        Optional. The depth of the classification nodes to retrieve. If not specified, only the specified node is returned.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/get
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/get-root-nodes
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/get-classification-nodes

    .EXAMPLE
        $params = @{
            CollectionUri  = 'https://dev.azure.com/my-org'
            ProjectName    = 'my-project-1'
            StructureGroup = 'Areas'
        }
        Get-AdoClassificationNode @params

        Retrieves the root area for the specified project.

    .EXAMPLE
        $params = @{
            CollectionUri  = 'https://dev.azure.com/my-org'
            ProjectName    = 'my-project-1'
            StructureGroup = 'Areas'
            Path           = 'my-team-1/my-subarea-1'
            Depth          = 2
        }
        Get-AdoClassificationNode @params

        Retrieves the area at the specified path with a depth of 2.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            Ids           = 1, 2, 3
            ErrorPolicy   = 'omit'
        }
        Get-AdoClassificationNode @params

        Retrieves multiple classification nodes by their IDs, omitting any not found.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            Ids           = 1, 2, 3
            ErrorPolicy   = 'fail'
        }
        Get-AdoClassificationNode @params

        Retrieves multiple classification nodes by their IDs, failing if any are not found.

    .EXAMPLE
        $params = @{
            StructureGroup = 'Iterations'
            Path           = 'Sprint 1'
        }
        Get-AdoClassificationNode @params

        Retrieves the iteration node at the specified path from the default project and collection.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'GetAll', ConfirmImpact = 'None')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'GetAll')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByPath')]
        [ValidateSet('Areas', 'Iterations')]
        [string]$StructureGroup,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByPath')]
        [string]$Path,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByNodesIds')]
        [string[]]$Ids,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByNodesIds')]
        [ValidateSet('fail', 'omit')]
        [string]$ErrorPolicy,

        [Parameter(ValueFromPipelineByPropertyName)]
        [int32]$Depth,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.2')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("StructureType: $StructureType")
        Write-Debug ("Path: $Path")
        Write-Debug ("Depth: $Depth")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $QueryParameters = [System.Collections.Generic.List[string]]::new()

            $uri = "$CollectionUri/$ProjectName/_apis/wit/classificationnodes"

            # Adjust URI based on parameter set
            if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
                if ($StructureGroup -and $Path) {
                    $uri = "$CollectionUri/$ProjectName/_apis/wit/classificationnodes/$StructureGroup/$Path"
                } elseif ($StructureGroup) {
                    $uri = "$CollectionUri/$ProjectName/_apis/wit/classificationnodes/$StructureGroup"
                }
            } elseif ($PSCmdlet.ParameterSetName -eq 'GetAll' -and $StructureGroup) {
                $uri = "$CollectionUri/$ProjectName/_apis/wit/classificationnodes/$StructureGroup"
            }

            # Build query parameters
            if ($PSCmdlet.ParameterSetName -eq 'ByNodesIds') {
                if ($Ids) {
                    $QueryParameters.Add("ids=$($Ids -join ',')")
                }
                if ($ErrorPolicy) {
                    $QueryParameters.Add("errorPolicy=$ErrorPolicy")
                }
            }
            if ($Depth) {
                $QueryParameters.Add("`$depth=$Depth")
            }

            $params = @{
                Uri             = $uri
                Version         = $Version
                QueryParameters = if ($QueryParameters.Count -gt 0) { $QueryParameters -join '&' } else { $null }
                Method          = 'GET'
            }

            $shouldProcessOperation = if ($PSCmdlet.ParameterSetName -eq 'GetAll') {
                if ($StructureGroup) {
                    "Get root classification node '$StructureGroup'"
                } else {
                    'Get all root classification nodes'
                }
            } elseif ($PSCmdlet.ParameterSetName -eq 'ByPath') {
                if ($Path) {
                    "Get classification node '$StructureGroup/$Path'"
                } else {
                    "Get root classification node '$StructureGroup'"
                }
            } elseif ($PSCmdlet.ParameterSetName -eq 'ByNodesIds') {
                "Get classification node '$($Ids -join ', ')'"
            } else {
                'Get classification nodes'
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, $shouldProcessOperation)) {
                try {
                    $results = (Invoke-AdoRestMethod @params)

                    $items = if (($PSCmdlet.ParameterSetName -eq 'GetAll' -and $StructureGroup) -or
                        $PSCmdlet.ParameterSetName -eq 'ByPath') {
                        # Use array for single node response
                        @( $results )
                    } else {
                        # Use value array for multiple nodes response
                        $results.value
                    }

                    foreach ($i_ in $items) {
                        $obj = [ordered]@{
                            id            = $i_.id
                            identifier    = $i_.identifier
                            name          = $i_.name
                            structureType = $i_.structureType
                            path          = $i_.path
                            hasChildren   = $i_.hasChildren
                        }
                        if ($i_.children) {
                            $obj['children'] = $i_.children
                        }
                        if ($i_.attributes) {
                            $obj['attributes'] = $i_.attributes
                        }
                        $obj['projectName'] = $ProjectName
                        $obj['collectionUri'] = $CollectionUri
                        [PSCustomObject]$obj
                    }
                } catch {
                    if ($_.ErrorDetails.Message -match 'NotFoundException') {
                        Write-Warning "Classification node(s) not found in project '$ProjectName', skipping."
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
