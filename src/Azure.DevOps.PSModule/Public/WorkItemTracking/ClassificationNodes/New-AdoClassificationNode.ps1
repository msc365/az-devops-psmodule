# cSpell: words classificationnodes
function New-AdoClassificationNode {
    <#
    .SYNOPSIS
        Creates a new classification node for a project in Azure DevOps.

    .DESCRIPTION
        This function creates a new classification node under a specified path for a project in Azure DevOps using the REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the Azure DevOps project.

    .PARAMETER StructureType
        Mandatory. The type of classification node to create. Valid values are 'Areas' or 'Iterations'.

    .PARAMETER Name
        Mandatory. The name of the new classification node to create.

    .PARAMETER Path
        Optional. The path under which to create the new classification node. If not specified, the node is created at the root level.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Object

        Object representing the created classification node.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/create-or-update

    .NOTES
        - Requires an active connection to Azure DevOps using Connect-AdoOrganization.

    .EXAMPLE
        $newAreaNode = New-AdoClassificationNode -Name 'NewArea' -ProjectId 'my-project' -StructureType 'Areas'

        This example creates a new area node named 'NewArea' at the root level of the specified project.

    .EXAMPLE
        $newAreaNode = New-AdoClassificationNode -Name 'SubArea' -Path 'ExistingArea' -ProjectId 'my-project' -StructureType 'Areas'

        This example creates a new area node named 'SubArea' under the existing area node 'ExistingArea' in the specified project.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateSet('Areas', 'Iterations')]
        [string]$StructureType,

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
                [uri]::EscapeUriString($StructureType), [uri]::EscapeUriString($Path), $ApiVersion)

            $body = @{
                name = $Name
            } | ConvertTo-Json

            $params = @{
                Method      = 'POST'
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
