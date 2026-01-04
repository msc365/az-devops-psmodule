function New-AdoEnvironment {
    <#
    .SYNOPSIS
        Create a new Azure DevOps Pipeline Environment.

    .DESCRIPTION
        This cmdlet creates a new Azure DevOps Pipeline Environment within a specified project.
        When an environment with the specified name already exists, it will be returned instead of creating a new one.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER Name
        Optional. The name of the environment to filter the results.

    .PARAMETER Description
        Optional. The description of the new environment.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.
        The -preview flag must be supplied in the api-version for such requests.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/environments/environments/add

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            Name          = 'my-environment-tst'
            Description   = 'Test environment description'
        }

        New-AdoEnvironment @params -Verbose

        Creates a new environment in the specified project using the provided parameters.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        @(
            'my-environment-dev',
            'my-environment-tst',
            'my-environment-prd'
        ) | New-AdoEnvironment @params -Verbose

        Creates multiple new environments in the specified project demonstrating pipeline input.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]$Name,

        [Parameter()]
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
                Uri     = "$CollectionUri/$ProjectName/_apis/pipelines/environments"
                Version = $Version
                Method  = 'POST'
            }

            $body = [PSCustomObject]@{
                name        = $Name
                description = $Description
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, "Create environment: $Name")) {
                try {
                    $results = $body | Invoke-AdoRestMethod @params

                    [PSCustomObject]@{
                        id            = $results.id
                        name          = $results.name
                        createdBy     = $results.createdBy.id
                        createdOn     = $results.createdOn
                        projectName   = $ProjectName
                        collectionUri = $CollectionUri
                    }

                } catch {
                    if ($_.ErrorDetails.Message -match 'EnvironmentExistsException') {
                        Write-Warning "Environment $Name already exists, trying to get it"

                        $params.Method = 'GET'
                        $params.QueryParameters = "name=$Name"

                        $results = (Invoke-AdoRestMethod @params).value

                        [PSCustomObject]@{
                            id            = $results.id
                            name          = $results.name
                            createdBy     = $results.createdBy.id
                            createdOn     = $results.createdOn
                            projectName   = $ProjectName
                            collectionUri = $CollectionUri
                        }
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
