function New-AdoEnvironment {
    <#
    .SYNOPSIS
        Create a new Azure DevOps Pipeline Environment.

    .DESCRIPTION
        This cmdlet creates a new Azure DevOps Pipeline Environment within a specified project.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/myorganization.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER EnvironmentName
        Optional. The name of the environment to filter the results.

    .PARAMETER Description
        Optional. The description of the new environment.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/environments/environments/add

    .EXAMPLE
        $params = @{
            CollectionUri   = 'https://dev.azure.com/my-org'
            ProjectName     = 'my-project'
            EnvironmentName = 'my-environment-tst'
            Description     = 'Test environment description'
        }

        New-AdoEnvironment @params -Verbose

        Creates a new environment in the specified project using the provided parameters.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
        }
        @(
            'my-environment-tst',
            'my-environment-dev',
            'my-environment-prd'
        ) | New-AdoEnvironment @params -Verbose

        Creates multiple new environments in the specified project demonstrating pipeline input.

    .NOTES
        This cmdlet requires an active connection to an Azure DevOps organization established via Connect-AdoOrganization.
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
        [Alias('Name')]
        [string[]]$EnvironmentName,

        [Parameter()]
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
                Uri     = "$CollectionUri/$ProjectName/_apis/pipelines/environments"
                Version = $Version
                Method  = 'POST'
            }

            foreach ($name in $EnvironmentName) {
                $body = [PSCustomObject]@{
                    Name        = $name
                    Description = $Description
                }

                if ($PSCmdlet.ShouldProcess($ProjectName, "Create Environment: $name")) {
                    try {
                        $result += ($body | Invoke-AdoRestMethod @params)
                    } catch {
                        if ($_ -match 'already exists') {
                            Write-Warning "Environment $name already exists, trying to get it"

                            $params.Method = 'GET'
                            $params += @{ QueryParameters = "name=$($name)" }
                            $result += (Invoke-AdoRestMethod @params).value
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
