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

    .PARAMETER Id
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
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
            Id            = 1
            Name          = 'my-updated-environment'
            Description   = 'Updated environment description'
        }
        Set-AdoEnvironment @params -Verbose

        Updates the environment with ID 1 in the specified project using the provided parameters.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
        }

        [PSCustomObject]@{
            Id          = 1
            Name        = 'my-updated-environment'
            Description = 'Updated environment description'
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
        [int32]$Id,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Name')]
        [string]$Name,

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
        Write-Debug ("Id: $Id")
        Write-Debug ("Name: $Name")
        Write-Debug ("Description: $Description")
        Write-Debug ("Version: $Version")

        Confirm-Defaults -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {

            $params = @{
                Uri     = "$CollectionUri/$ProjectName/_apis/pipelines/environments/$Id"
                Version = $Version
                Method  = 'PATCH'
            }

            $body = [PSCustomObject]@{
                Name        = $Name
                Description = $Description
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, "Update environment: $Id")) {
                try {
                    $env = $body | Invoke-AdoRestMethod @params
                    [PSCustomObject]@{
                        id             = $env.id
                        name           = $env.name
                        createdBy      = $env.createdBy.id
                        createdOn      = $env.createdOn
                        lastModifiedBy = $env.lastModifiedBy.id
                        lastModifiedOn = $env.lastModifiedOn
                        projectName    = $ProjectName
                        collectionUri  = $CollectionUri
                    }
                } catch {
                    if ($_ -match 'does not exist') {
                        Write-Warning "Environment with ID $id does not exist, skipping update."
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
