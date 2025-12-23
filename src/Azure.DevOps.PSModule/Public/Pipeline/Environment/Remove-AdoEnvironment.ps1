function Remove-AdoEnvironment {
    <#
    .SYNOPSIS
        Remove an Azure DevOps Pipeline Environment by its ID.

    .DESCRIPTION
        This cmdlet deletes a specific Azure DevOps Pipeline Environment using its unique identifier within a specified project.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the project.

    .PARAMETER EnvironmentId
        Mandatory. The ID of the environment to remove.

    .PARAMETER ApiVersion
        Optional. The API version to use for the request. Default is '7.2-preview.1'.

    .EXAMPLE
        Remove-AdoEnvironment -ProjectId "MyProject" -EnvironmentId "42"

        Deletes the environment with ID 42 from the project "MyProject".

    .NOTES
        This cmdlet requires an active connection to an Azure DevOps organization established via Connect-AdoOrganization.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [string]$EnvironmentId,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.2-preview.1')]
        [string]$ApiVersion = '7.2-preview.1'
    )

    begin {
        Write-Debug ('Command         : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId     : {0}' -f $ProjectId)
        Write-Debug ('  EnvironmentId : {0}' -f $EnvironmentId)
        Write-Debug ('  ApiVersion    : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/_apis/pipelines/environments/{2}?api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                $EnvironmentId, $ApiVersion)

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
        Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
