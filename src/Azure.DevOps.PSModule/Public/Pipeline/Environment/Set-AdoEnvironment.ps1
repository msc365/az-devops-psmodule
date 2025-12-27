function Set-AdoEnvironment {
    <#
    .SYNOPSIS
        Create a new Azure DevOps Pipeline Environment.

    .DESCRIPTION
        This cmdlet creates a new Azure DevOps Pipeline Environment within a specified project.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/myorganization.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER EnvironmentId
        Mandatory. The ID of the environment to update.

    .PARAMETER EnvironmentName
        Mandatory. The name of the environment to update.

    .PARAMETER Description
        Optional. The description of the updated environment.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/environments/environments/update

    .EXAMPLE
        $params = @{
            CollectionUri   = 'https://dev.azure.com/my-org'
            ProjectName     = 'my-project'
            EnvironmentId   = 1
            EnvironmentName = 'my-updated-environment'
            Description     = 'Updated environment description'
        }
        Set-AdoEnvironment @params -Verbose

        Updates the environment with ID 1 in the specified project using the provided parameters.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
        }

        [PSCustomObject]@{
            EnvironmentId   = 1
            EnvironmentName = 'my-updated-environment'
            Description     = 'Updated environment description'
        } | Set-AdoEnvironment @params -Verbose

        Updates the environment with ID 1 in the specified project using the provided parameters in a pipeline.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [int32]$EnvironmentId,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Name')]
        [string]$EnvironmentName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Description,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("EnvironmentName: $EnvironmentName")
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
                Method  = 'PATCH'
            }

            $body = [PSCustomObject]@{
                Name        = $EnvironmentName
                Description = $Description
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, "Update environment: $EnvironmentId")) {
                try {
                    $result += ($body | Invoke-AdoRestMethod @params)
                } catch {
                    if ($_ -match 'does not exist') {
                        Write-Warning "Environment with ID $id does not exist, skipping update."
                    } else {
                        Write-AdoError -message $_
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
        if ($result) {
            $result | ForEach-Object {
                [PSCustomObject]@{
                    CollectionUri = $CollectionUri
                    ProjectName   = $ProjectName
                    Id            = $_.id
                    Name          = $_.name
                }
            }
        }

        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
