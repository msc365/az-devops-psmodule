function Remove-AdoProject {
    <#
    .SYNOPSIS
        Remove a project from an Azure DevOps organization.

    .DESCRIPTION
        This function removes a project from an Azure DevOps organization through REST API.

    .PARAMETER ProjectId
        Mandatory. Project ID from the project to remove.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Boolean

        Indicates whether the project was successfully removed.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/delete

    .EXAMPLE
        Remove-AdoProject -ProjectId 'my-project-001'
    #>
    [CmdletBinding()]
    [OutputType([boolean])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Verbose ('Command      : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Verbose ('  ProjectId  : {0}' -f $ProjectId)
        Write-Verbose ('  ApiVersion : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/_apis/projects/{1}?api-version={2}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId), $ApiVersion)

            $params = @{
                Method  = 'DELETE'
                Uri     = $azDevOpsUri
                Headers = ((ConvertFrom-SecureString -SecureString $global:AzDevOpsHeaders -AsPlainText) | ConvertFrom-Json -AsHashtable)
            }

            $response = Invoke-RestMethod @params -Verbose:$VerbosePreference

            $status = $response.status

            while ($status -ne 'succeeded') {
                Write-Verbose 'Checking project deletion status...'
                Start-Sleep -Seconds 2

                $response = Invoke-RestMethod -Method GET -Uri $response.url -Headers $params.Headers -Verbose:$VerbosePreference
                $status = $response.status

                if ($status -eq 'failed') {
                    Write-Error -Message ('Project deletion failed {0}' -f $PSItem.Exception.Message)
                }
            }

            return $true

        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
