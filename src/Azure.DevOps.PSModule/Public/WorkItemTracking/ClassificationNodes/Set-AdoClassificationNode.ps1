# cSpell: words classificationnodes
function Set-AdoClassificationNode {
    <#
    .SYNOPSIS
        Updates a classification node for a project in Azure DevOps.

    .DESCRIPTION
        This cmdlet updates the name of a classification node for a specified project in Azure DevOps.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Mandatory. The ID or name of the Azure DevOps project.

    .PARAMETER StructureGroup
        Mandatory. The type of classification node to update. Valid values are 'Areas' or 'Iterations'.

    .PARAMETER Path
        Optional. The path of the classification node to update.

    .PARAMETER Name
        Mandatory. The new name for the classification node.

    .PARAMETER StartDate
        Optional. The start date for the iteration node. Must be used only when StructureType is 'Iterations'.

    .PARAMETER FinishDate
        Optional. The finish date for the iteration node. Must be used only when StructureType is 'Iterations'.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/update

    .EXAMPLE
        $params = @{
            CollectionUri  = 'https://dev.azure.com/my-org'
            ProjectName    = 'my-project-1'
            StructureGroup = 'Areas'
            Path           = 'my-team-1/my-subarea-1'
            Name           = 'my-renamed-subarea-1'
        }
        Set-AdoClassificationNode @params

        Updates the name of the specified area node.
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
        [string]$Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [datetime]$StartDate,

        [Parameter(ValueFromPipelineByPropertyName)]
        [datetime]$FinishDate,

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
        Write-Debug ("Name: $Name")
        Write-Debug ("StartDate: $StartDate")
        Write-Debug ("FinishDate: $FinishDate")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $body = [PSCustomObject]@{}
            if ($Name) {
                $body | Add-Member -MemberType NoteProperty -Name 'name' -Value $Name
            }
            if ($StartDate) {
                if ($StructureGroup -ne 'Iterations') {
                    throw 'StartDate can only be set for Iteration nodes.'
                }
                if (-not $body.attributes) {
                    $body | Add-Member -MemberType NoteProperty -Name 'attributes' -Value ([PSCustomObject]@{})
                }
                $body.attributes | Add-Member -MemberType NoteProperty -Name 'startDate' -Value $StartDate.ToString('o')
            }
            if ($FinishDate) {
                if ($StructureGroup -ne 'Iterations') {
                    throw 'FinishDate can only be set for Iteration nodes.'
                }
                if (-not $body.attributes) {
                    $body | Add-Member -MemberType NoteProperty -Name 'attributes' -Value ([PSCustomObject]@{})
                }
                $body.attributes | Add-Member -MemberType NoteProperty -Name 'finishDate' -Value $FinishDate.ToString('o')
            }

            if (-not $body.PSObject.Properties.Count) {
                throw 'At least one property (Name, StartDate, or FinishDate) must be specified to update a classification node.'
            }

            $params = @{
                Uri     = "$CollectionUri/$ProjectName/_apis/wit/classificationnodes/$StructureGroup/$Path"
                Version = $Version
                Method  = 'PATCH'
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, "Update classification node: $StructureGroup/$Path")) {
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
                        Write-Warning "Classification node '$Name' already exists under $StructureGroup/$Path, skipping."
                    } elseif ($_.ErrorDetails.Message -match 'NotFoundException') {
                        Write-Warning "Classification node '$StructureGroup/$Path' not found, skipping."
                    } else {
                        throw $_
                    }
                }
            } else {
                $params += @{
                    Body = $body
                }
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
