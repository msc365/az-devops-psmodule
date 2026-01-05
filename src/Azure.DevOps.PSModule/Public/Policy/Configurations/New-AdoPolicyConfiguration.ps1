function New-AdoPolicyConfiguration {
    <#
    .SYNOPSIS
        Create a new policy configuration for an Azure DevOps project.

    .DESCRIPTION
        This cmdlet creates a new policy configuration for an Azure DevOps project.
        The configuration must be provided as a PSCustomObject or hashtable containing all required policy settings.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The ID or name of the project.

    .PARAMETER Configuration
        Mandatory. The configuration object for the policy as a PSCustomObject.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .OUTPUTS
        [PSCustomObject]

        The created policy configuration object.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/configurations/create

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }

        $config = [PSCustomObject]@{
            isEnabled = $true
            isBlocking = $true
            type = @{
                id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
            }
            settings = @{
                minimumApproverCount = 1
                creatorVoteCounts = $true
                allowDownvotes = $false
                resetOnSourcePush = $false
                requireVoteOnLastIteration = $false
                resetRejectionsOnSourcePush = $false
                blockLastPusherVote = $false
                requireVoteOnEachIteration = $false
                scope = @(
                    @{
                        repositoryId = $null
                        refName = $null
                        matchKind = 'DefaultBranch'
                    }
                )
            }
        }

        New-AdoPolicyConfiguration @params -Configuration $config

        Creates a new minimum approver count policy configuration in the specified project.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [PSCustomObject]$Configuration,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Configuration: $($Configuration | ConvertTo-Json -Depth 10)")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $params = @{
                Uri     = "$CollectionUri/$ProjectName/_apis/policy/configurations"
                Version = $Version
                Method  = 'POST'
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, 'Create Policy Configuration')) {
                try {
                    $results = $Configuration | Invoke-AdoRestMethod @params

                    [PSCustomObject]@{
                        id            = $results.id
                        type          = $results.type
                        revision      = $results.revision
                        isEnabled     = $results.isEnabled
                        isBlocking    = $results.isBlocking
                        isDeleted     = $results.isDeleted
                        settings      = $results.settings
                        createdBy     = $results.createdBy
                        createdDate   = $results.createdDate
                        projectName   = $ProjectName
                        collectionUri = $CollectionUri
                    }
                } catch {
                    if ($_.ErrorDetails.Message -match 'PolicyConfigurationAlreadyExistsException') {
                        Write-Warning 'A policy configuration with the same settings already exists, skipping.'
                    } else {
                        throw $_
                    }
                }
            }
        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
