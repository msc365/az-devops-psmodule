function New-AdoCheckApproval {
    <#
    .SYNOPSIS
        Create a new approval check for a specific resource.

    .DESCRIPTION
        This function creates a new approval check for a specified resource within an Azure DevOps project.
        When existing configuration is found, it will be returned instead of creating a new one.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/myorganization.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER Approvers
        Mandatory. An array of approvers in the format @{ id = 'originId' }.

    .PARAMETER ResourceType
        Mandatory. The type of resource to which the check will be applied. Valid values are 'endpoint', 'environment', 'variablegroup', 'repository'.

    .PARAMETER ResourceName
        Mandatory. An array of resource names to which the check will be applied.

    .PARAMETER ApprovalType
        Optional. The type of approval check to create. Valid values are 'approval' and 'precheck'. Default is 'approval'.

    .PARAMETER Instructions
        Optional. Instructions for the approvers.

    .PARAMETER Timeout
        Optional. The timeout in minutes for the approval check. Default is 1440 (1 day).

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/add

    .EXAMPLE
        $approvers = @{ id = '0000000-0000-0000-0000-000000000000' }

        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
            Approvers     = $approvers
            ResourceType  = 'environment'
            ResourceName  = 'my-environment-tst'
            ApprovalType  = 'approval'
            Instructions  = 'Approval required before deploying to environment'
            Timeout       = 1440
        }
        New-AdoCheckApproval @params

        Creates a new approval check in the specified project using the provided parameters.
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
        [object[]]$Approvers,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('endpoint', 'environment', 'variablegroup', 'repository')]
        [string]$ResourceType,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]]$ResourceName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('approval', 'precheck')]
        [string]$ApprovalType = 'approval',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Instructions,

        [Parameter(ValueFromPipelineByPropertyName)]
        [int32]$Timeout = 1440,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Approvers: $Approvers")
        Write-Debug ("ResourceType: $ResourceType")
        Write-Debug ("ResourceName: $ResourceName")
        Write-Debug ("ApprovalType: $ApprovalType")
        Write-Debug ("Instructions: $Instructions")
        Write-Debug ("Timeout: $Timeout")
        Write-Debug ("ApiVersion: $Version")

        Confirm-Defaults -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })

        $result = @()
    }

    process {
        try {
            $params = @{
                Uri     = "$CollectionUri/$ProjectName/_apis/pipelines/checks/configurations"
                Version = $Version
                Method  = 'POST'
            }

            foreach ($name in $ResourceName) {
                # Determine definitionRef based on ApprovalType
                switch ($ApprovalType) {
                    'approval' {
                        $definitionRef = @{
                            name = 'Approval'
                            id   = '26014962-64a0-49f4-885b-4b874119a5cc'
                        }
                    }
                    'precheck' {
                        $definitionRef = @{
                            name = 'Pre-check approval'
                            id   = '0f52a19b-c67e-468f-b8eb-0ae83b532c99'
                        }
                    }
                }

                # Get resource ID
                switch ($ResourceType) {
                    'environment' {
                        $typeParams = @{
                            CollectionUri = $CollectionUri
                            ProjectName   = $ProjectName
                            Name          = $name
                        }
                        $resourceId = (Get-AdoEnvironment @typeParams).Id
                    }
                    default {
                        throw "ResourceType '$ResourceType' is not supported yet."
                    }
                }

                # Create configuration JSON
                $body = @{
                    settings = @{
                        approvers            = $Approvers
                        executionOrder       = 'anyOrder'
                        minRequiredApprovers = 0
                        instructions         = $Instructions
                        blockedApprovers     = @()
                        definitionRef        = @{
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

                if ($PSCmdlet.ShouldProcess($ProjectName, "Create $($definitionRef.name) for: $name")) {
                    try {
                        $result += ($body | Invoke-AdoRestMethod @params)
                    } catch {
                        if ($_ -match 'already exists') {
                            Write-Warning "Configuration $($definitionRef.name) already exists for $ResourceType with ID $resourceId, trying to get it"

                            $params.Method = 'GET'
                            $params.QueryParameters = "resourceType=$ResourceType&resourceId=$resourceId&`$expand=settings"
                            $result += (Invoke-AdoRestMethod @params).value | Where-Object { $_.settings.definitionRef.id -eq $definitionRef.id }
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
            }

        } catch {
            throw $_
        }
    }

    end {
        if ($result) {
            $result | ForEach-Object {
                $result | ForEach-Object {
                    $obj = [ordered]@{
                        id = $_.id
                    }
                    if ($_.settings) {
                        $obj['settings'] = $_.settings
                    }
                    $obj['timeout'] = $_.timeout
                    $obj['type'] = $_.type
                    $obj['resource'] = $_.resource
                    $obj['createdBy'] = $_.createdBy.id
                    $obj['createdOn'] = $_.createdOn
                    $obj['project'] = $ProjectName
                    $obj['collectionUri'] = $CollectionUri

                    [PSCustomObject]$obj
                }
            }
        }

        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
