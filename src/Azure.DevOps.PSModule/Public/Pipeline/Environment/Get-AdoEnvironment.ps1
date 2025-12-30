function Get-AdoEnvironment {
    <#
    .SYNOPSIS
        Get a list of Azure DevOps Pipeline Environments within a specified project.

    .DESCRIPTION
        This cmdlet retrieves a list of Azure DevOps Pipeline Environments for a given project, with optional filtering by environment name and pagination support.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/myorganization.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER Name
        Optional. The name of the environment to filter the results.

    .PARAMETER Top
        Optional. The maximum number of environments to return. Default is 20.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/environments/environments/list

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
        }

        Get-AdoEnvironment @params -Top 2
        Get-AdoEnvironment @params -Name 'my-environment-tst'
        Get-AdoEnvironment @params -Name '*environment*'
        Get-AdoEnvironment @params -Name 'my-env*' -Top 2

        Retrieves environments from the specified project with various filtering and pagination options.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
        }
        @(
            'my-environment-tst',
            'my-environment-dev'
        ) | Get-AdoEnvironment @params -Verbose

        Retrieves the specified environments from the project, demonstrating pipeline input.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]]$Name,

        [Parameter()]
        [int]$Top = 20,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Name: $Name")
        Write-Debug ("Top: $Top")
        Write-Debug ("Version: $Version")

        Confirm-Defaults -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {

            $params = @{
                Uri             = "$CollectionUri/$ProjectName/_apis/pipelines/environments"
                Version         = $Version
                QueryParameters = "name=$($Name)&`$top=$Top"
                Method          = 'GET'
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, "Get Environment(s) from: $ProjectName")) {

                $environments = (Invoke-AdoRestMethod @params).value

                foreach ($env in $environments) {
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
                }

            } else {
                Write-Verbose "Calling Invoke-AdoRestMethod with $($params| ConvertTo-Json -Depth 10)"
            }

        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
