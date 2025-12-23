# cSpell: words classificationnodes
function Remove-AdoClassificationNode {
    <#
    .SYNOPSIS
        Removes a classification node from a project in Azure DevOps.

    .DESCRIPTION
        This function removes a classification node from a specified project in Azure DevOps using the REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the Azure DevOps project.

    .PARAMETER StructureType
        Mandatory. The type of the classification node structure (Areas or Iterations).

    .PARAMETER Path
        Required. The path of the classification node to remove. The root classification node cannot be removed.

    .PARAMETER ReclassifyId
        Optional. The ID of the target classification node for reclassification. If not provided, child nodes will be deleted.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/delete

    .NOTES
        - Requires an active connection to Azure DevOps using Connect-AdoOrganization.

    .EXAMPLE
        Remove-AdoClassificationNode -ProjectId 'my-project' -Path 'Area/SubArea'

        This example removes the area node at the specified path from the specified project.

    .EXAMPLE
        Remove-AdoClassificationNode -ProjectId 'my-project' -Path 'Area'

        This example removes the area node named 'Area' from the specified project including its 'SubArea' child node.

    .EXAMPLE
        Remove-AdoClassificationNode -ProjectId 'my-project' -Path 'Area/SubArea' -ReclassifyId 658

        This example removes the area node at the specified path and reassigns (reclassifies) the work items that were associated with that node to another existing node, the node with ID 658.

        Without $reclassifyId, deleting a node could leave work items orphaned or unclassified. This parameter ensures a smooth transition by automatically moving them to a valid node.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [ValidateSet('Areas', 'Iterations')]
        [string]$StructureType,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [int]$ReclassifyId,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.1', '7.2-preview.2')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command         : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId     : {0}' -f $ProjectId)
        Write-Debug ('  StructureType : {0}' -f $StructureType)
        Write-Debug ('  Path          : {0}' -f $Path)
        Write-Debug ('  ReclassifyId  : {0}' -f $ReclassifyId)
        Write-Debug ('  ApiVersion    : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/_apis/wit/classificationnodes/{2}/{3}?$reclassifyId={4}&api-version={5}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                [uri]::EscapeUriString($StructureType), [uri]::EscapeUriString($Path), $ReclassifyId, $ApiVersion)

            $params = @{
                Method  = 'DELETE'
                Uri     = $azDevOpsUri
                Headers = @{
                    'Accept'        = 'application/json'
                    'Authorization' = (ConvertFrom-SecureString -SecureString $AzDevOpsAuth -AsPlainText)
                }
            }

            $response = Invoke-RestMethod @params -Verbose:$VerbosePreference

            return $response

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
