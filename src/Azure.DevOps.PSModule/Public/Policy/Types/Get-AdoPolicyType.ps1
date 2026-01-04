function Get-AdoPolicyType {
    <#
    .SYNOPSIS
        Gets policy types for an Azure DevOps project.

    .DESCRIPTION
        This function retrieves policy types for an Azure DevOps project through REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the project.

    .PARAMETER PolicyType
        Mandatory. The type of policy to retrieve.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/types/get

    .EXAMPLE
        $policyTypes = Get-AdoPolicyType -ProjectId 'my-project-1' -PolicyType '00000000-0000-0000-0000-000000000000'
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [string]$PolicyType,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command       : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId   : {0}' -f $ProjectId)
        Write-Debug ('  PolicyType  : {0}' -f $PolicyType)
        Write-Debug ('  ApiVersion  : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/_apis/policy/types?policyType={2}&api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), $ProjectId,
                [uri]::EscapeUriString($PolicyType), $ApiVersion)

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
