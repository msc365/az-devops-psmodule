# cSpell: words classificationnodes
function New-AdoClassificationNode {
    <#
    .SYNOPSIS
        Creates a new classification node for a project in Azure DevOps.

    .DESCRIPTION
        This cmdlet creates a new classification node under a specified path for a project in Azure DevOps.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Mandatory. The ID or name of the Azure DevOps project.

    .PARAMETER StructureGroup
        Mandatory. The type of classification node to create. Valid values are 'Areas' or 'Iterations'.

    .PARAMETER Path
        Optional. The path under which to create the new classification node. If not specified, the node is created at the root level.

    .PARAMETER Name
        Mandatory. The name of the new classification node to create.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/create-or-update

    .EXAMPLE
        $params = @{
            CollectionUri  = 'https://dev.azure.com/my-org'
            ProjectName    = 'my-project-1'
            StructureGroup = 'Areas'
            Name           = 'my-team-1'
        }
        New-AdoClassificationNode @params

        Creates a new area node named 'my-team-1' at the root level of the specified project.

    .EXAMPLE
        $params = @{
            CollectionUri  = 'https://dev.azure.com/my-org'
            ProjectName    = 'my-project-1'
            StructureGroup = 'Areas'
            Path           = 'my-team-1'
            Name           = 'my-subarea-1'
        }
        New-AdoClassificationNode @params

        Creates a new area node named 'my-subarea-1' under the existing area node 'my-team-1' in the specified project.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('Areas', 'Iterations')]
        [string]$StructureGroup,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Path,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.2')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Name: $Name")
        Write-Debug ("StructureGroup: $StructureGroup")
        Write-Debug ("Path: $Path")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            if ($Path) {
                $uri = "$CollectionUri/$ProjectName/_apis/wit/classificationnodes/$StructureGroup/$Path"
            } else {
                $uri = "$CollectionUri/$ProjectName/_apis/wit/classificationnodes/$StructureGroup"
            }

            $params = @{
                Uri     = $uri
                Version = $Version
                Method  = 'POST'
            }

            $body = [PSCustomObject]@{
                name = $Name
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, "Create classification node: $Name under $($Path ? "$StructureGroup/$Path" : $StructureGroup)")) {
                try {
                    $results = $body | Invoke-AdoRestMethod @params

                    $obj = [ordered]@{
                        id            = $results.id
                        identifier    = $results.identifier
                        name          = $results.name
                        structureType = $results.structureType
                        path          = $results.path
                        hasChildren   = $results.hasChildren
                    }
                    if ($results.children) {
                        $obj['children'] = $results.children
                    }
                    if ($results.attributes) {
                        $obj['attributes'] = $results.attributes
                    }
                    $obj['projectName'] = $ProjectName
                    $obj['collectionUri'] = $CollectionUri
                    [PSCustomObject]$obj

                } catch {
                    if ($_.ErrorDetails.Message -match 'DuplicateNameException') {
                        Write-Warning "Classification node '$Name' already exists under $($Path ? "$StructureGroup/$Path" : $StructureGroup), skipping."
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
