function Remove-AdoEnvironment {
    <#
    .SYNOPSIS
        Remove an Azure DevOps Pipeline Environment by its ID.

    .DESCRIPTION
        This cmdlet deletes a specific Azure DevOps Pipeline Environment using its unique identifier within a specified project.

    .PARAMETER CollectionUri
        The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/myorganization.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER EnvironmentId
        Mandatory. The ID of the environment to remove.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
            EnvironmentId = 1
        }
        Remove-AdoEnvironment @params -Verbose

        Removes the environment with ID 1 from the specified project using the provided parameters.
    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
        }
        @(
            1, 2, 3
        ) | Remove-AdoEnvironment @params -Verbose

        Removes the environments with IDs 1, 2, and 3 from the specified project demonstrating pipeline input.
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
        [int32[]]$EnvironmentId,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("EnvironmentId: $EnvironmentId")
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
                Uri     = "$CollectionUri/$ProjectName/_apis/pipelines/environments/$EnvironmentId"
                Version = $Version
                Method  = 'DELETE'
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, "Delete Environment: $EnvironmentId")) {
                try {
                    $result += Invoke-AdoRestMethod @params | Out-Null
                } catch {
                    if ($_ -match 'does not exist in current project') {
                        Write-Warning "Environment with ID $EnvironmentId does not exist, skipping deletion."
                    } else {
                        Write-AdoError -message $_
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
