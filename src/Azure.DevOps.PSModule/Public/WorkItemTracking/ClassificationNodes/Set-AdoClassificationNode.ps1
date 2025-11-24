# cSpell: words classificationnodes
function Set-AdoClassificationNode {
    <#
    .SYNOPSIS
        Updates a classification node for a project in Azure DevOps.

    .DESCRIPTION
        This function updates the name of a classification node for a specified project in Azure DevOps using the REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the Azure DevOps project.

    .PARAMETER StructureType
        Mandatory. The type of classification node to update. Valid values are 'Areas' or 'Iterations'.

    .PARAMETER Name
        Mandatory. The new name for the classification node.

    .PARAMETER Path
        Optional. The path of the classification node to update. If not specified, the root classification node is updated.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Object

        The updated classification node object.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/create-or-update

    .NOTES
        - Requires an active connection to Azure DevOps using Connect-AdoOrganization.

    .EXAMPLE
        $updatedAreaNode = Set-AdoClassificationNode -ProjectId 'my-project' -Name 'New Area Name' -Path 'Area/SubArea'

        This example updates the name of the specified area node.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [ValidateSet('Areas', 'Iterations')]
        [string]$StructureType,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.1', '7.2-preview.2')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command         : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId     : {0}' -f $ProjectId)
        Write-Debug ('  StructureType : {0}' -f $StructureType)
        Write-Debug ('  Name          : {0}' -f $Name)
        Write-Debug ('  Path          : {0}' -f $Path)
        Write-Debug ('  ApiVersion    : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/_apis/wit/classificationnodes/{2}/{3}?api-version={4}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                $StructureType, [uri]::EscapeUriString($Path), $ApiVersion)

            $body = @{
                name = $Name
            } | ConvertTo-Json

            $params = @{
                Method      = 'PATCH'
                Uri         = $azDevOpsUri
                ContentType = 'application/json'
                Headers     = ((ConvertFrom-SecureString -SecureString $global:AzDevOpsHeaders -AsPlainText) | ConvertFrom-Json -AsHashtable)
                Body        = $body
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
