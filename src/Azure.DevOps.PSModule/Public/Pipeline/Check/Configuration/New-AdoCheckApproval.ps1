function New-AdoCheckApproval {
    <#
    .SYNOPSIS
        Create a new approval check for a specific resource.

    .DESCRIPTION
        This function creates a new approval check for a specified resource within an Azure DevOps project.
        When existing configuration is found, it will be returned instead of creating a new one.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER Approvers
        Mandatory. An array of approvers in the format @{ id = 'originId' }.

    .PARAMETER ResourceType
        Mandatory. The type of resource to which the check will be applied. Valid values are 'endpoint', 'environment', 'variablegroup', 'repository'.

    .PARAMETER ResourceName
        Mandatory. The name of the resource to which the check will be applied.

    .PARAMETER DefinitionType
        Optional. The type of approval check to create. Valid values are 'approval', 'preCheckApproval', and 'postCheckApproval'. Default is 'approval'.

    .PARAMETER Instructions
        Optional. Instructions for the approvers.

    .PARAMETER MinRequiredApprovers
        Optional. The minimum number of required approvers. Default is 0 (All).
        Note: When only one approver is specified ($Approvers.Count = 1), this value is automatically set to 0 regardless of the input.

    .PARAMETER ExecutionOrder
        Optional. The execution order of the approvers. Valid values are 'anyOrder' and 'inSequence'. Default is 'anyOrder'.
        Note: When MinRequiredApprovers is 0, this value is automatically set to 'anyOrder' regardless of the input.

    .PARAMETER RequesterCannotBeApprover
        Optional. Indicates whether the requester can be an approver. Default is $false.

    .PARAMETER Timeout
        Optional. The timeout in minutes for the approval check. Default is 1440 (1 day).

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.
        The -preview flag must be supplied in the api-version for such requests.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/add

    .EXAMPLE
        $approvers = @(
            @{ id = '00000000-0000-0000-0000-000000000001' }
        )
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            Approvers     = $approvers
            ResourceType  = 'environment'
            ResourceName  = 'my-environment-tst'
        }
        New-AdoCheckApproval @params -Verbose

        Creates a new approval check configuration for the specified environment with default parameters.

    .EXAMPLE
        $approvers = @(
            @{ id = '00000000-0000-0000-0000-000000000001' },
            @{ id = '00000000-0000-0000-0000-000000000002' }
        )
        $params = @{
            CollectionUri             = 'https://dev.azure.com/my-org'
            ProjectName               = 'my-project-1'
            Approvers                 = $approvers
            ResourceType              = 'environment'
            ResourceName              = 'my-environment-tst'
            DefinitionType            = 'approval'
            Instructions              = 'Approval required before deploying to environment'
            MinRequiredApprovers      = 1
            ExecutionOrder            = 'inSequence'
            RequesterCannotBeApprover = $true
            Timeout                   = 1440
        }

        New-AdoCheckApproval @params -Verbose

        Creates a new approval check configuration for the specified environment with the provided parameters.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [hashtable[]]$Approvers,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('endpoint', 'environment', 'variablegroup', 'repository')]
        [string]$ResourceType,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]$ResourceName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('approval', 'preCheckApproval', 'postCheckApproval')]
        [string]$DefinitionType = 'approval',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Instructions,

        [Parameter(ValueFromPipelineByPropertyName, HelpMessage = 'Set to 0 for All.')]
        [int32]$MinRequiredApprovers = 0,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('anyOrder', 'inSequence')]
        [string]$ExecutionOrder = 'anyOrder',

        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]$RequesterCannotBeApprover = $false,

        [Parameter(ValueFromPipelineByPropertyName)]
        [int32]$Timeout = 1440,

        [Parameter(HelpMessage = 'The -preview flag must be supplied in the api-version for such requests.')]
        [Alias('ApiVersion')]
        [ValidateSet('7.1-preview.1', '7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Approvers: $($Approvers -join ',')")
        Write-Debug ("ResourceType: $ResourceType")
        Write-Debug ("ResourceName: $ResourceName")
        Write-Debug ("DefinitionType: $DefinitionType")
        Write-Debug ("Instructions: $Instructions")
        Write-Debug ("MinRequiredApprovers: $MinRequiredApprovers")
        Write-Debug ("ExecutionOrder: $ExecutionOrder")
        Write-Debug ("RequesterCannotBeApprover: $RequesterCannotBeApprover")
        Write-Debug ("Timeout: $Timeout")
        Write-Debug ("ApiVersion: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $params = @{
                Uri     = "$CollectionUri/$ProjectName/_apis/pipelines/checks/configurations"
                Version = $Version
                Method  = 'POST'
            }

            # Determine definitionRef based on DefinitionType
            $definitionRef = Resolve-AdoCheckConfigDefinitionRef -Name $DefinitionType

            # Get resource ID
            switch ($ResourceType) {
                'environment' {
                    $typeParams = @{
                        CollectionUri = $CollectionUri
                        ProjectName   = $ProjectName
                        Name          = $ResourceName
                    }
                    $resourceId = (Get-AdoEnvironment @typeParams).Id
                }
                default {
                    throw "ResourceType '$ResourceType' is not supported yet."
                }
            }

            # Create configuration body
            $body = @{
                settings = @{
                    approvers                 = $Approvers
                    minRequiredApprovers      = if ($Approvers.Count -gt 1) { $MinRequiredApprovers } else { 0 }
                    executionOrder            = if ($MinRequiredApprovers -gt 0) { $ExecutionOrder } else { 'anyOrder' }
                    requesterCannotBeApprover = $RequesterCannotBeApprover
                    instructions              = $Instructions
                    blockedApprovers          = @()
                    definitionRef             = @{
                        id = $definitionRef.id
                    }
                }
                timeout  = $Timeout
                type     = @{
                    name = 'Approval'
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                }
                resource = @{
                    type = $ResourceType
                    id   = $resourceId
                }
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, "Create $($definitionRef.name) for: $ResourceName")) {
                try {
                    $results = $body | Invoke-AdoRestMethod @params

                    $obj = [ordered]@{
                        id = $results.id
                    }
                    if ($results.settings) {
                        $obj['settings'] = $results.settings
                    }
                    $obj['timeout'] = $results.timeout
                    $obj['type'] = $results.type
                    $obj['resource'] = $results.resource
                    $obj['createdBy'] = $results.createdBy.id
                    $obj['createdOn'] = $results.createdOn
                    $obj['project'] = $ProjectName
                    $obj['collectionUri'] = $CollectionUri
                    [PSCustomObject]$obj

                } catch {
                    if ($_.ErrorDetails.Message -match 'already exists') {
                        Write-Warning "$($definitionRef.name) already exists for $ResourceType with $ResourceName, trying to get it"

                        $params.Method = 'GET'
                        $params.QueryParameters = @(
                            "resourceType=$($ResourceType)",
                            "resourceId=$($resourceId)",
                            "`$expand=settings"
                        ) -join '&'

                        $results = (Invoke-AdoRestMethod @params).value | Where-Object {
                            $_.settings.definitionRef.id -eq $definitionRef.id
                        }

                        $obj = [ordered]@{
                            id = $results.id
                        }
                        if ($results.settings) {
                            $obj['settings'] = $results.settings
                        }
                        $obj['timeout'] = $results.timeout
                        $obj['type'] = $results.type
                        $obj['resource'] = $results.resource
                        $obj['createdBy'] = $results.createdBy.id
                        $obj['createdOn'] = $results.createdOn
                        $obj['project'] = $ProjectName
                        $obj['collectionUri'] = $CollectionUri
                        [PSCustomObject]$obj

                    } else {
                        throw $_
                    }
                }
            } else {
                $params += @{
                    Body = $body
                }
                Write-Verbose "Calling Invoke-AdoRestMethod with $($params | ConvertTo-Json -Depth 10)"
            }
        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
