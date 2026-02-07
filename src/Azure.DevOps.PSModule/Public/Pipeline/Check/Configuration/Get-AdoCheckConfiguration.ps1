function Get-AdoCheckConfiguration {
    <#
    .SYNOPSIS
        Get a list of check configurations for a specific resource.

    .DESCRIPTION
        This function retrieves check configurations for a specified resource within an Azure DevOps project.
        You need to provide the resource type and resource ID to filter the results.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER ResourceType
        Mandatory. The type of the resource to filter the results. E.g., 'environment'.

    .PARAMETER ResourceName
        Mandatory. The name of the resource to filter the results.

    .PARAMETER DefinitionType
        Optional. The type(s) of check definitions to filter the results.
        Valid values are 'approval', 'preCheckApproval', 'postCheckApproval', 'branchControl', and 'businessHours'.

    .PARAMETER Id
        Mandatory. The ID of the check configuration to retrieve.

    .PARAMETER Expands
        Optional. Specifies additional details to include in the response. Default is 'none'.

        Valid values are 'none' and 'settings'.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.
        The -preview flag must be supplied in the api-version for such requests.

    .LINK
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/get
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/list

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            ResourceType  = 'environment'
            ResourceName  = 'my-environment-tst'
        }
        Get-AdoCheckConfiguration @params -Verbose

        Retrieves check configurations for the specified environment within the project using provided parameters.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            ResourceType  = 'environment'
            Expands       = 'settings'
        }
        @(
            'my-environment-tst',
            'my-environment-dev'
        ) | Get-AdoCheckConfiguration @params -Verbose

        Retrieves check configurations for the specified environments within the project using provided parameters, demonstrating pipeline input.

    .EXAMPLE
        Get-AdoCheckConfiguration -Id 1 -Expands 'settings' -Verbose

        Retrieves the check configuration with ID 1, including its settings.

    .EXAMPLE
        $params = @{
            CollectionUri  = 'https://dev.azure.com/my-org'
            ProjectName    = 'my-project-1'
            ResourceType   = 'environment'
            ResourceName   = 'my-environment-tst'
            DefinitionType = 'approval'
            Expands        = 'settings'
        }
        Get-AdoCheckConfiguration @params -Verbose

        Retrieves check configurations for the specified environment filtered by the 'approval' definition type.

    .EXAMPLE
        $params = @{
            CollectionUri  = 'https://dev.azure.com/my-org'
            ProjectName    = 'my-project-1'
            ResourceType   = 'environment'
            ResourceName   = 'my-environment-tst'
            DefinitionType = 'approval', 'preCheckApproval'
            Expands        = 'settings'
        }
        Get-AdoCheckConfiguration @params -Verbose

        Retrieves check configurations for the specified environment filtered by multiple definition types.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ConfigurationList')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ConfigurationList')]
        [ValidateSet('endpoint', 'environment', 'variablegroup', 'repository')]
        [string]$ResourceType,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'ConfigurationList')]
        [string]$ResourceName,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ConfigurationList')]
        [ValidateSet('approval', 'preCheckApproval', 'postCheckApproval', 'branchControl', 'businessHours')]
        [string[]]$DefinitionType,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ConfigurationById')]
        [int32]$Id,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('none', 'settings')]
        [string]$Expands = 'none',

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
        Write-Debug ("Expands: $Expands")
        Write-Debug ("ApiVersion: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $QueryParameters = [List[string]]::new()
            $DefinitionRefIds = [List[string]]::new()

            if ($id) {
                $uri = "$CollectionUri/$ProjectName/_apis/pipelines/checks/configurations/$id"
            } else {
                $resourceId = $null

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
                        Write-Warning "ResourceType '$ResourceType' is not supported yet."
                        return
                    }
                }

                if (-not $resourceId) {
                    return
                }

                $uri = "$CollectionUri/$ProjectName/_apis/pipelines/checks/configurations"

                # If DefinitionType is provided, resolve it to get the definitionRef
                if ($DefinitionType) {
                    foreach ($definitionType_ in $DefinitionType) {
                        $definitionRef = Resolve-AdoDefinitionRef -Name $definitionType_
                        $DefinitionRefIds.Add($definitionRef.id)
                    }
                    $Expands = 'settings'
                }

                # Build query parameters
                if ($ResourceType) {
                    $QueryParameters.Add("resourceType=$ResourceType")
                }
                if ($resourceId) {
                    $QueryParameters.Add("resourceId=$resourceId")
                }
            }

            if ($Expands -ne 'none') {
                $QueryParameters.Add("`$expand=$Expands")
            }

            $params = @{
                Uri             = $uri
                Version         = $Version
                QueryParameters = if ($queryParameters.Count -gt 0) { $queryParameters -join '&' } else { $null }
                Method          = 'GET'
            }

            try {
                $results = (Invoke-AdoRestMethod @params)
                if ($Id) { $results = @($results) } else {
                    if ($DefinitionRefIds.Count -gt 0) {
                        $results = $results.value |
                            Where-Object { $DefinitionRefIds -contains $_.settings.definitionRef.id }
                    } else {
                        $results = $results.value
                    }
                }

                foreach ($c_ in $results) {
                    $obj = [ordered]@{
                        id = $c_.id
                    }
                    if ($c_.settings) {
                        $obj['settings'] = $c_.settings
                    }
                    $obj['timeout'] = $c_.timeout
                    $obj['type'] = $c_.type
                    $obj['resource'] = $c_.resource
                    $obj['createdBy'] = $c_.createdBy.id
                    $obj['createdOn'] = $c_.createdOn
                    $obj['project'] = $ProjectName
                    $obj['collectionUri'] = $CollectionUri
                    [PSCustomObject]$obj
                }
            } catch {
                if ($_.ErrorDetails.Message -match 'NotFoundException') {
                    Write-Warning "Check configuration with ID $Id does not exist, skipping."
                } else {
                    throw $_
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
