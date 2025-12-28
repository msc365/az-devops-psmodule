function Remove-AdoCheckConfiguration {
    <#
    .SYNOPSIS
        Remove a check configuration by its ID.

    .DESCRIPTION
        This cmdlet deletes a specific check configuration using its unique identifier within a specified resource.

    .PARAMETER CollectionUri
        The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/myorganization.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER CheckConfigurationId
        Mandatory. The ID of the check configuration to remove.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
            CheckConfigurationId = 1
        }
        Remove-AdoCheckConfiguration @params -Verbose

        Removes the check configuration with ID 1 from the specified resource using the provided parameters.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
        }
        @(
            1, 2, 3
        ) | Remove-AdoCheckConfiguration @params -Verbose

        Removes the check configurations with IDs 1, 2, and 3 from the specified resource demonstrating pipeline input.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('Id')]
        [int32[]]$CheckConfigurationId,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("CheckConfigurationId: $CheckConfigurationId")
        Write-Debug ("Version: $Version")

        Confirm-Defaults -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })

        $result = @()
    }

    process {
        try {
            $params = @{
                Uri     = "$CollectionUri/$ProjectName/_apis/pipelines/checks/configurations/$CheckConfigurationId"
                Version = $Version
                Method  = 'DELETE'
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, "Delete Check Configuration: $CheckConfigurationId")) {
                try {
                    $result += Invoke-AdoRestMethod @params | Out-Null
                } catch {
                    if ($_ -match 'does not exist') {
                        Write-Warning "Check Configuration with ID $CheckConfigurationId does not exist, skipping deletion."
                    } else {
                        throw $_
                    }
                }

            } else {
                Write-Verbose "Calling Invoke-AdoRestMethod with $($params | ConvertTo-Json -Depth 10)"
            }

        } catch {
            throw $_
        }
    }

    end {
        if ($result) {
            $result
        }

        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
