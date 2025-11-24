function New-AdoPolicyConfiguration {
    <#
    .SYNOPSIS
        Create a new policy configuration for an Azure DevOps project.

    .DESCRIPTION
        This function creates a new policy configuration for an Azure DevOps project through REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the project.

    .PARAMETER Configuration
        Mandatory. The configuration object for the policy.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .NOTES
        - The configuration object should be a valid JSON object.

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
        }

        $policy = New-AdoPolicyConfiguration -ProjectName 'my-project' -Configuration $config
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Mandatory)]
        [Alias('ProjectName')]
        [string]$ProjectId,

        [Parameter(Mandatory)]
        [object]$Configuration,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Verbose ('Command         : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Verbose ('  ProjectId     : {0}' -f $ProjectId)
        Write-Verbose ('  Configuration : {0}' -f ($Configuration | ConvertTo-Json))
        Write-Verbose ('  ApiVersion    : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/_apis/policy/configurations?api-version={2}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeDataString($ProjectId), $ApiVersion)

            $params = @{
                Method      = 'POST'
                Uri         = $azDevOpsUri
                ContentType = 'application/json'
                Headers     = ((ConvertFrom-SecureString -SecureString $global:AzDevOpsHeaders -AsPlainText) | ConvertFrom-Json -AsHashtable)
                Body        = ($Configuration | ConvertTo-Json -Depth 5)
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
