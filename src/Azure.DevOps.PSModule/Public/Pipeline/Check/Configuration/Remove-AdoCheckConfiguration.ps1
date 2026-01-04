function Remove-AdoCheckConfiguration {
    <#
    .SYNOPSIS
        Remove a check configuration by its ID.

    .DESCRIPTION
        This cmdlet deletes a specific check configuration using its unique identifier within a specified resource.

    .PARAMETER CollectionUri
        The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER Id
        Mandatory. The ID of the check configuration to remove.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.
        The -preview flag must be supplied in the api-version for such requests.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            Id = 1
        }
        Remove-AdoCheckConfiguration @params -Verbose

        Removes the check configuration with ID 1 from the specified resource using the provided parameters.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
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
        [int32]$Id,

        [Parameter(HelpMessage = 'The -preview flag must be supplied in the api-version for such requests.')]
        [Alias('ApiVersion')]
        [ValidateSet('7.1-preview.1', '7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Id: $Id")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $params = @{
                Uri     = "$CollectionUri/$ProjectName/_apis/pipelines/checks/configurations/$Id"
                Version = $Version
                Method  = 'DELETE'
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, "Delete Check Configuration: $Id")) {
                try {
                    Invoke-AdoRestMethod @params | Out-Null
                } catch {
                    if ($_.ErrorDetails.Message -match 'NotFoundException') {
                        Write-Warning "Check Configuration with ID $Id does not exist, skipping deletion."
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
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
