function Set-AdoEnvironment {
    <#
    .SYNOPSIS
        Update an existing Azure DevOps Pipeline Environment.

    .DESCRIPTION
        This cmdlet updates an existing Azure DevOps Pipeline Environment within a specified project.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER Id
        Mandatory. The ID of the environment to update.

    .PARAMETER Name
        Optional. The name of the environment to update.

    .PARAMETER Description
        Optional. The description of the updated environment.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.
        The -preview flag must be supplied in the api-version for such requests.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/environments/environments/update

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            Id            = 1
            Name          = 'my-environment-updated'
            Description   = 'Environment description updated'
        }
        Set-AdoEnvironment @params -Verbose

        Updates the environment with ID 1 in the specified project using the provided parameters.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }

        [PSCustomObject]@{
            Id          = 1
            Name        = 'my-environment-updated'
            Description = 'Environment description updated'
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
        [Alias('EnvironmentId')]
        [int32]$Id,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('EnvironmentName')]
        [string]$Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Description,

        [Parameter(HelpMessage = 'The -preview flag must be supplied in the api-version for such requests.')]
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

        Confirm-Default -Defaults ([ordered]@{
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
                    $results = $body | Invoke-AdoRestMethod @params

                    [PSCustomObject]@{
                        id             = $results.id
                        name           = $results.name
                        description    = $results.description
                        createdBy      = $results.createdBy
                        createdOn      = $results.createdOn
                        lastModifiedBy = $results.lastModifiedBy
                        lastModifiedOn = $results.lastModifiedOn
                        projectName    = $ProjectName
                        collectionUri  = $CollectionUri
                    }
                } catch {
                    if ($_.ErrorDetails.Message -match 'EnvironmentNotFoundException') {
                        Write-Warning "Environment with ID $Id does not exist, skipping update."
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
