function Set-AdoEnvironment {
    <#
    .SYNOPSIS
        Update an Azure DevOps Pipeline Environment by its ID.

    .DESCRIPTION
        This cmdlet updates the details of a specific Azure DevOps Pipeline Environment using its unique identifier within a specified project.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the project.

    .PARAMETER EnvironmentId
        Mandatory. The ID of the environment to update.

    .PARAMETER Name
        Optional. The new name for the environment.

    .PARAMETER Description
        Optional. The new description for the environment.

    .PARAMETER ApiVersion
        Optional. The API version to use for the request. Default is '7.2-preview.1'.

    .EXAMPLE
        Set-AdoEnvironment -ProjectId "MyProject" -EnvironmentId "42" -Name "NewEnvName" -Description "Updated description"

        Updates the environment with ID 42 in the project "MyProject" to have a new name and description.

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
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.2-preview.1')]
        [string]$ApiVersion = '7.2-preview.1'
    )

    begin {
        Write-Debug ('Command         : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId     : {0}' -f $ProjectId)
        Write-Debug ('  EnvironmentId : {0}' -f $EnvironmentId)
        Write-Debug ('  Name          : {0}' -f $Name)
        Write-Debug ('  Description   : {0}' -f $Description)
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

            $body = @{}

            if ($null -ne $Name) {
                $body += @{
                    name = $Name
                }
            }

            if ($null -ne $Description) {
                $body += @{
                    description = $Description
                }
            }

            $params = @{
                Method      = 'PATCH'
                Uri         = $azDevOpsUri
                ContentType = 'application/json'
                Headers     = @{
                    'Accept'        = 'application/json'
                    'Authorization' = (ConvertFrom-SecureString -SecureString $AzDevOpsAuth -AsPlainText)
                }
                Body        = ($body | ConvertTo-Json -Depth 3 -Compress)
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
