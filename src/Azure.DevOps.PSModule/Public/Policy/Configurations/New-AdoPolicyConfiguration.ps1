function New-AdoPolicyConfiguration {
    <#
    .SYNOPSIS
        Create a new policy configuration for an Azure DevOps project.

    .DESCRIPTION
        This function creates a new policy configuration for an Azure DevOps project through REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the project.

    .PARAMETER Configuration
        Mandatory. The configuration JSON for the policy.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Object

        The created policy configuration object.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/configurations/create?view=azure-devops

    .EXAMPLE
        $config = @{
            "isEnabled": true,
            "isBlocking": true,
            "type": @{
                "id": "fa4e907d-c16b-4a4c-9dfa-4906e5d171dd"
            },
            "settings": @{
                "minimumApproverCount": 1,
                "creatorVoteCounts": true,
                "allowDownvotes": false,
                "resetOnSourcePush": false,
                "requireVoteOnLastIteration": false,
                "resetRejectionsOnSourcePush": false,
                "blockLastPusherVote": false,
                "requireVoteOnEachIteration": false,
                "scope": @(
                    {
                        "repositoryId": null,
                        "refName": null,
                        "matchKind": "DefaultBranch"
                    }
                )
            }
        } | ConvertTo-Json -Depth 5 -Compress

        $policy = New-AdoPolicyConfiguration -ProjectName 'my-project-1' -Configuration $config
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Mandatory)]
        [Alias('ProjectName')]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [string]$Configuration,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command         : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId     : {0}' -f $ProjectId)
        Write-Debug ('  Configuration : {0}' -f ($Configuration | ConvertTo-Json))
        Write-Debug ('  ApiVersion    : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            if (-not (Test-Json $Configuration)) {
                throw 'Invalid JSON for service endpoint configuration object.'
            }

            $uriFormat = '{0}/{1}/_apis/policy/configurations?api-version={2}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeDataString($ProjectId), $ApiVersion)

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
