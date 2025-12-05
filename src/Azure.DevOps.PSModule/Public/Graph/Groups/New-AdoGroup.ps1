function New-AdoGroup {
    <#
    .SYNOPSIS
        Adds an AAD Group as member of a group.

    .DESCRIPTION
        This function adds an AAD Group as member of a group in Azure DevOps through REST API.

    .PARAMETER GroupDescriptor
        A comma separated list of descriptors referencing groups you want the graph group to join.

    .PARAMETER GroupId
        The OriginId of the entra group to add as a member.

    .PARAMETER ApiVersion
        The API version to use.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/create

    .EXAMPLE
        New-AdoGroup -GroupDescriptor 'vssgp.00000000-0000-0000-0000-000000000000' -GroupId '00000000-0000-0000-0000-000000000000'

        Adds an AAD Group as member of a group.
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Mandatory)]
        [Alias('Descriptor')]
        [string]$GroupDescriptor,

        [Parameter(Mandatory)]
        [Alias('OriginId')]
        [string]$GroupId,

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('7.1-preview.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.2-preview.1'
    )

    begin {
        Write-Debug ('Command              : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  GroupDescriptor    : {0}' -f $GroupDescriptor)
        Write-Debug ('  GroupId (OriginId) : {0}' -f $GroupId)
        Write-Debug ('  ApiVersion         : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $AzDevOpsOrganization = $global:AzDevOpsOrganization -replace 'https://', 'https://vssps.'

            $uriFormat = ('{0}/_apis/graph/groups?groupDescriptors={1}&api-version={2}')
            $azDevOpsUri = ($uriFormat -f [uri]::new($AzDevOpsOrganization), $GroupDescriptor, $ApiVersion)

            $body = @{
                originId = $GroupId
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
        Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
