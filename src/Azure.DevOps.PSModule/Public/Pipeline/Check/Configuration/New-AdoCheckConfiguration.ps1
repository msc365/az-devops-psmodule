function New-AdoCheckConfiguration {
    <#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER ProjectId
        The ID or name of the project.

    .PARAMETER Configuration
        A string representing the configuration in JSON format.

    .PARAMETER ApiVersion
        The API version to use for the request. Default is '7.2-preview.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/add

    .EXAMPLE
        $configJson = @{
            settings = @{
                approvers = @(
                    @{
                        displayName = $null
                        id = "00000000-0000-0000-0000-000000000000"
                    }
                )
                executionOrder = "anyOrder"
                minRequiredApprovers = 0
                instructions = "Instructions"
                blockedApprovers = @()
            }
            timeout = 43200
            type = @{
                id = "8c6f20a7-a545-4486-9777-f762fafe0d4d"
                name = "Approval"
            }
            resource = @{
                type = "queue"
                id = "1"
                name = "Default"
            }
        } | ConvertTo-Json -Depth 5 -Compress

        New-AdoCheckConfiguration -ProjectId "MyProject" -Configuration $configJson

    .NOTES
        This cmdlet requires an active connection to an Azure DevOps organization established via Connect-AdoOrganization.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [string]$Configuration,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.2-preview.1')]
        [string]$ApiVersion = '7.2-preview.1'
    )

    begin {
        Write-Debug ('Command         : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId     : {0}' -f $ProjectId)
        Write-Debug ('  Configuration : {0}' -f $Configuration)
        Write-Debug ('  ApiVersion    : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            if (-not (Test-Json $Configuration -ErrorAction SilentlyContinue)) {
                throw 'Invalid JSON for configuration string.'
            }

            $uriFormat = '{0}/{1}/_apis/pipelines/checks/configurations?api-version={2}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                $ApiVersion)

            $params = @{
                Method      = 'POST'
                Uri         = $azDevOpsUri
                ContentType = 'application/json'
                Headers     = @{
                    'Accept'        = 'application/json'
                    'Authorization' = (ConvertFrom-SecureString -SecureString $AzDevOpsAuth -AsPlainText)
                }
                Body        = $Configuration
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
