# cSpell: words classificationnodes
function Remove-AdoClassificationNode {
    <#
    .SYNOPSIS
        Removes a classification node from a project in Azure DevOps.

    .DESCRIPTION
        This cmdlet removes a classification node from a specified project in Azure DevOps.
        Optionally reclassifies work items to another node instead of leaving them orphaned.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Mandatory. The ID or name of the Azure DevOps project.

    .PARAMETER StructureType
        Mandatory. The type of the classification node structure (Areas or Iterations).

    .PARAMETER Path
        Mandatory. The path of the classification node to remove. The root classification node cannot be removed.

    .PARAMETER ReclassifyId
        Optional. The ID of the target classification node for reclassification of work items associated with the node being removed.
        If specified, work items associated with the removed node will be reassigned to this node. If not specified, work items may become orphaned or unclassified.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/delete

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            StructureType = 'Areas'
            Path          = 'my-team-1/my-subarea-1'
        }
        Remove-AdoClassificationNode @params

        Removes the area node at the specified path from the specified project.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            StructureType = 'Areas'
            Path          = 'my-team-1'
        }
        Remove-AdoClassificationNode @params

        Removes the area node named 'my-team-1' from the specified project including its 'my-subarea-1' child node.
    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            StructureType = 'Areas'
            Path          = 'my-team-1/my-subarea-1'
            ReclassifyId  = 658
        }
        Remove-AdoClassificationNode @params

        Removes the area node at the specified path and reassigns (reclassifies) the work items that were associated with that node to another existing node, the node with ID 658.
        Without ReclassifyId, deleting a node could leave work items orphaned or unclassified. This parameter ensures a smooth transition by automatically moving them to a valid node.
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

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Path,

        [Parameter(ValueFromPipelineByPropertyName)]
        [int32]$ReclassifyId,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.2')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("StructureGroup: $StructureGroup")
        Write-Debug ("Path: $Path")
        Write-Debug ("ReclassifyId: $ReclassifyId")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $QueryParameters = [System.Collections.Generic.List[string]]::new()

            if ($ReclassifyId) {
                $QueryParameters.Add("`$reclassifyId=$ReclassifyId")
            }

            $params = @{
                Uri             = "$CollectionUri/$ProjectName/_apis/wit/classificationnodes/$StructureGroup/$Path"
                Version         = $Version
                QueryParameters = if ($QueryParameters.Count -gt 0) { $QueryParameters -join '&' } else { $null }
                Method          = 'DELETE'
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, "Remove classification node $StructureGroup/$Path")) {
                try {
                    Invoke-AdoRestMethod @params | Out-Null
                } catch {
                    if ($_.ErrorDetails.Message -match 'NotFoundException') {
                        Write-Warning "Classification node '$StructureGroup/$Path' not found, skipping."
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
