function Get-AdoPolicyConfiguration {
    <#
    .SYNOPSIS
        Retrieves Azure DevOps policy configuration details.

    .DESCRIPTION
        This cmdlet retrieves details of one or more Azure DevOps policy configurations within a specified project.
        You can retrieve all policy configurations, filter by policy type, or retrieve a specific configuration by ID.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The ID or name of the project.

    .PARAMETER Id
        Optional. The ID of a specific policy configuration to retrieve.

    .PARAMETER PolicyType
        Optional. The policy type ID to filter configurations. Used to retrieve configurations of a specific policy type.

    .PARAMETER Scope
        Optional. The scope of the policy to filter configurations.
        [Provided for legacy reasons] The scope on which a subset of policies is defined.

    .PARAMETER Top
        Optional. The maximum number of configurations to return. Used for pagination.

    .PARAMETER Skip
        Optional. The number of configurations to skip. Used for pagination.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/configurations/get
        https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/configurations/list

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        Get-AdoPolicyConfiguration @params

        Retrieves all policy configurations from the specified project.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        Get-AdoPolicyConfiguration @params -PolicyType 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'

        Retrieves all policy configurations of the specified policy type from the project.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        Get-AdoPolicyConfiguration @params -Id 42

        Retrieves the policy configuration with ID 42 from the project.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        42, 43, 44 | Get-AdoPolicyConfiguration @params

        Retrieves multiple policy configurations by ID using pipeline input.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ListConfigurations', SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'ByConfigurationId')]
        [Alias('ConfigurationId')]
        [int]$Id,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ListConfigurations')]
        [string]$PolicyType,

        [Parameter(
            HelpMessage = '[Provided for legacy reasons] The scope on which a subset of policies is defined.',
            ParameterSetName = 'ListConfigurations')]
        [string]$Scope,

        [Parameter(ParameterSetName = 'ListConfigurations')]
        [int32]$Top,

        [Parameter(ParameterSetName = 'ListConfigurations')]
        [string]$ContinuationToken,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Id: $Id")
        Write-Debug ("PolicyType: $PolicyType")
        Write-Debug ("Scope: $Scope")
        Write-Debug ("Top: $Top")
        Write-Debug ("Skip: $Skip")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $QueryParameters = [System.Collections.Generic.List[string]]::new()

            if ($Id) {
                $uri = "$CollectionUri/$ProjectName/_apis/policy/configurations/$Id"
            } else {
                $uri = "$CollectionUri/$ProjectName/_apis/policy/configurations"

                # Build query parameters for list operations
                if ($PolicyType) {
                    $QueryParameters.Add("policyType=$PolicyType")
                }
                if ($Scope) {
                    $QueryParameters.Add("scope=$Scope")
                }
                if ($PSBoundParameters.ContainsKey('Top')) {
                    $QueryParameters.Add("`$top=$Top")
                }
                if ($PSBoundParameters.ContainsKey('ContinuationToken')) {
                    $QueryParameters.Add("continuationToken=$ContinuationToken")
                }
            }

            $params = @{
                Uri             = $uri
                Version         = $Version
                QueryParameters = if ($QueryParameters.Count -gt 0) { $QueryParameters -join '&' } else { $null }
                Method          = 'GET'
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, $Id ? "Get Policy Configuration: $Id from: $ProjectName" : "Get Policy Configurations from: $ProjectName")) {
                try {
                    $results = (Invoke-AdoRestMethod @params)
                    $configurations = if ($Id) { @($results) } else { $results.value }

                    foreach ($c_ in $configurations) {
                        $obj = [ordered]@{
                            id          = $c_.id
                            type        = $c_.type
                            revision    = $c_.revision
                            isEnabled   = $c_.isEnabled
                            isBlocking  = $c_.isBlocking
                            isDeleted   = $c_.isDeleted
                            settings    = $c_.settings
                            createdBy   = $c_.createdBy
                            createdDate = $c_.createdDate
                        }
                        if ($c_.continuationToken) {
                            $obj['continuationToken'] = $c_.continuationToken
                        }
                        $obj['projectName'] = $ProjectName
                        $obj['collectionUri'] = $CollectionUri

                        # Output the configuration object
                        [PSCustomObject]$obj
                    }
                } catch {
                    if ($_.ErrorDetails.Message -match 'NotFoundException') {
                        Write-Warning "Policy configuration with ID $Id does not exist, skipping."
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
