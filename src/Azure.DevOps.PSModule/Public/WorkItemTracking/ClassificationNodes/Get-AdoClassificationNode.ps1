# cSpell: words classificationnodes
function Get-AdoClassificationNode {
    <#
    .SYNOPSIS
        Gets classification nodes for a project in Azure DevOps.

    .DESCRIPTION
        This function retrieves classification nodes for a specified project in Azure DevOps using the REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the Azure DevOps project.

    .PARAMETER StructureType
        Mandatory. The structure type (group) of the classification node. Valid values are 'Areas' or 'Iterations'.

    .PARAMETER Path
        Optional. The path of the classification node to retrieve. If not specified, the root classification node is returned.

    .PARAMETER Depth
        Optional. The depth of the classification nodes to retrieve. If not specified, only the specified node is returned.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Object

        The classification node object retrieved from Azure DevOps.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/get

    .NOTES
        - Requires an active connection to Azure DevOps using Connect-AdoOrganization.

    .EXAMPLE
        $classificationNode = Get-AdoClassificationNode -ProjectId 'my-project-001' -StructureType 'Areas'

        This example retrieves the root area for the specified project.

    .EXAMPLE
        $classificationNode = Get-AdoClassificationNode -ProjectId 'my-project-001' -StructureType 'Areas' -Path 'Area/SubArea' -Depth 2

        This example retrieves the area at the specified path with a depth of 2.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [ValidateSet('Areas', 'Iterations')]
        [string]$StructureType,

        [Parameter(Mandatory = $false)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [int]$Depth,

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
        Write-Debug ('  Depth         : {0}' -f $Depth)
        Write-Debug ('  ApiVersion    : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/_apis/wit/classificationnodes/{2}/{3}?$depth={4}&api-version={5}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                [uri]::EscapeUriString($StructureType),
                [uri]::EscapeUriString($Path), $Depth, $ApiVersion)

            $params = @{
                Method  = 'GET'
                Uri     = $azDevOpsUri
                Headers = ((ConvertFrom-SecureString -SecureString $global:AzDevOpsHeaders -AsPlainText) | ConvertFrom-Json -AsHashtable)
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
