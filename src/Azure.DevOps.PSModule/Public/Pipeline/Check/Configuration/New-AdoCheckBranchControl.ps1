function New-AdoCheckBranchControl {
    <#
    .SYNOPSIS
        Create a new branch control check for a specific resource.

    .DESCRIPTION
        This function creates a new branch control check for a specified resource within an Azure DevOps project.
        When existing configuration is found, it will be returned instead of creating a new one.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER DisplayName
        Optional. The name of the branch control check. Default is 'Branch Control'.

    .PARAMETER ResourceType
        Mandatory. The type of resource to which the check will be applied. Valid values are 'endpoint', 'environment', 'variablegroup', 'repository'.

    .PARAMETER ResourceName
        Mandatory. The name of the resource to which the check will be applied.

    .PARAMETER AllowedBranches
        Optional. A comma-separated list of allowed branches. Default is 'refs/heads/main'.

    .PARAMETER EnsureProtectionOfBranch
        Optional. Specifies whether to ensure the protection of the specified branches. Default is $true.

    .PARAMETER AllowUnknownStatusBranches
        Optional. Specifies whether to allow branches with unknown status. Default is $false.

    .PARAMETER Timeout
        Optional. The timeout in minutes for the approval check. Default is 1440 (1 day).

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.
        The -preview flag must be supplied in the api-version for such requests.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/add

    .EXAMPLE
        $params = @{
        CollectionUri                  = 'https://dev.azure.com/my-org'
            ProjectName                = 'my-project-1'
            DisplayName                = 'Branch Control'
            ResourceType               = 'environment'
            ResourceName               = 'my-environment-tst'
            AllowedBranches            = 'refs/heads/main', 'refs/heads/release/*'
            EnsureProtectionOfBranch   = $true
            AllowUnknownStatusBranches = $false
            Timeout                    = 1440
        }
        New-AdoCheckBranchControl @params

        Creates a new branch control check in the specified project using the provided parameters.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$DisplayName = 'Branch Control',

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('endpoint', 'environment', 'variablegroup', 'repository')]
        [string]$ResourceType,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]$ResourceName,

        [Parameter()]
        [string[]]$AllowedBranches = 'refs/heads/main',

        [Parameter()]
        [bool]$EnsureProtectionOfBranch = $true,

        [Parameter()]
        [bool]$AllowUnknownStatusBranches = $false,

        [Parameter()]
        [int]$Timeout = 1440,

        [Parameter(HelpMessage = 'The -preview flag must be supplied in the api-version for such requests.')]
        [Alias('ApiVersion')]
        [ValidateSet('7.1-preview.1', '7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("ResourceType: $ResourceType")
        Write-Debug ("ResourceName: $ResourceName")
        Write-Debug ("AllowedBranches: $($AllowedBranches -join ', ')")
        Write-Debug ("EnsureProtectionOfBranch: $EnsureProtectionOfBranch")
        Write-Debug ("AllowUnknownStatusBranches: $AllowUnknownStatusBranches")
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

            # Create configuration JSON
            $body = @{
                type     = @{
                    name = 'Task Check'
                    id   = 'fe1de3ee-a436-41b4-bb20-f6eb4cb879a7'
                }
                settings = @{
                    displayName   = $DisplayName
                    definitionRef = @{
                        id      = '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'
                        name    = 'evaluatebranchProtection'
                        version = '0.0.1'
                    }
                    inputs        = @{
                        allowedBranches            = ($AllowedBranches -join ', ')
                        ensureProtectionOfBranch   = ($EnsureProtectionOfBranch ? 'true' : 'false')
                        allowUnknownStatusBranches = ($AllowUnknownStatusBranches ? 'true' : 'false')
                    }
                }
                timeout  = $Timeout
                resource = @{
                    type = $ResourceType
                    id   = $resourceId
                }
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, "Create $($DisplayName) for: $ResourceName")) {
                try {
                    # Check if configuration already exists with the same inputs
                    $exists = [PSCustomObject]@{
                        ResourceType = $ResourceType
                        ResourceName = $ResourceName
                        Expands      = 'settings'
                    } | Get-AdoCheckConfiguration

                    $exists = $exists | Where-Object {
                        $_.settings.definitionRef.id -eq '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b' -and
                        $_.settings.inputs.allowedBranches -eq $AllowedBranches -and
                        $_.settings.inputs.ensureProtectionOfBranch -eq ($EnsureProtectionOfBranch ? 'true' : 'false') -and
                        $_.settings.inputs.allowUnknownStatusBranches -eq ($AllowUnknownStatusBranches ? 'true' : 'false')
                    }

                    if (-not $exists) {
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

                    } else {
                        Write-Warning "$DisplayName already exists for $ResourceType with $ResourceName, returning existing one"

                        $obj = [ordered]@{
                            id = $exists.id
                        }
                        if ($exists.settings) {
                            $obj['settings'] = $exists.settings
                        }
                        $obj['timeout'] = $exists.timeout
                        $obj['type'] = $exists.type
                        $obj['resource'] = $exists.resource
                        $obj['createdBy'] = $exists.createdBy.id
                        $obj['createdOn'] = $exists.createdOn
                        $obj['project'] = $ProjectName
                        $obj['collectionUri'] = $CollectionUri
                        [PSCustomObject]$obj
                    }
                } catch {
                    throw $_
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
