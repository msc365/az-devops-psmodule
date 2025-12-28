function Get-AdoCheckConfiguration {
    <#
    .SYNOPSIS
        Get a list of check configurations for a specific resource.

    .DESCRIPTION
        This function retrieves check configurations for a specified resource within an Azure DevOps project.
        You need to provide the resource type and resource ID to filter the results.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/myorganization.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER ResourceType
        Mandatory. The type of the resource to filter the results. E.g., 'environment'.

    .PARAMETER ResourceName
        Mandatory. The name of the resource to filter the results.

    .PARAMETER Expands
        Optional. Specifies additional details to include in the response. Default is 'none'.

        Valid values are 'none' and 'settings'.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/list

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
            ResourceType  = 'environment'
            ResourceName  = 'my-environment-tst'
        }
        Get-AdoCheckConfiguration @params

        Retrieves check configurations for the specified environment within the project using provided parameters.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
            ResourceType  = 'environment'
            Expands       = 'settings'
        }
        @(
            'my-environment-tst',
            'my-environment-dev'
        ) | Get-AdoCheckConfiguration @params

        Retrieves check configurations for the specified environments within the project using provided parameters, demonstrating pipeline input.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('endpoint', 'environment', 'variablegroup', 'repository')]
        [string]$ResourceType,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]]$ResourceName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('none', 'settings')]
        [string]$Expands = 'none',

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("ResourceType: $ResourceType")
        Write-Debug ("ResourceName: $ResourceName")
        Write-Debug ("Expands: $Expands")
        Write-Debug ("ApiVersion: $Version")

        Confirm-Defaults -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })

        $result = @()
    }

    process {
        try {
            foreach ($name in $ResourceName) {

                switch ($ResourceType) {
                    'environment' {
                        $typeParams = @{
                            CollectionUri = $CollectionUri
                            ProjectName   = $ProjectName
                            Name          = $name
                        }
                        $resourceId = (Get-AdoEnvironment @typeParams).Id
                    }
                    default {
                        throw "ResourceType '$ResourceType' is not supported yet."
                    }
                }

                $params = @{
                    Uri             = "$CollectionUri/$ProjectName/_apis/pipelines/checks/configurations"
                    Version         = $Version
                    QueryParameters = "resourceType=$ResourceType&resourceId=$resourceId&`$expand=$Expands"
                    Method          = 'GET'
                }

                if ($PSCmdlet.ShouldProcess($ProjectName, "Get Check Configuration(s) from: $ResourceType/$name")) {

                    $result += (Invoke-AdoRestMethod @params).value

                } else {
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
                $_
            }
        }

        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
