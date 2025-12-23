function Get-AdoMembership {
    <#
    .SYNOPSIS
        Get the membership relationship between a subject and a container in Azure DevOps.

    .DESCRIPTION
        This cmdlet retrieves the membership relationship between a specified subject and container in Azure DevOps using the Azure DevOps REST API.

    .PARAMETER containerDescriptor
        Mandatory. A descriptor to the container in the relationship.

    .PARAMETER subjectDescriptor
        Mandatory. A descriptor to the child subject in the relationship.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Object

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/memberships/get

    .EXAMPLE
        Get-AdoMembership -containerDescriptor $containerDescriptor -subjectDescriptor $subjectDescriptor

        Retrieves the membership relationship between the specified subject and container.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (

        [Parameter(Mandatory)]
        [string]$subjectDescriptor,

        [Parameter(Mandatory)]
        [string]$containerDescriptor,

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('7.1-preview.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.2-preview.1'
    )

    begin {
        Write-Debug ('Command      : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  StorageKey : {0}' -f $StorageKey)
        Write-Debug ('  ApiVersion : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/_apis/graph/memberships/{1}/{2}?api-version={3}'
            $AzDevOpsOrganization = $global:AzDevOpsOrganization -replace 'https://', 'https://vssps.'
            $azDevOpsUri = ($uriFormat -f [uri]::new($AzDevOpsOrganization), $subjectDescriptor, $containerDescriptor, $ApiVersion)

            $params = @{
                Method  = 'GET'
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
        Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
