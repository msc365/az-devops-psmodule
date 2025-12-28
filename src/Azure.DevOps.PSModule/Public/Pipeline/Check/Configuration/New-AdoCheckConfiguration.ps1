function New-AdoCheckConfiguration {
    <#
    .SYNOPSIS
        Create a new check configuration for a specific resource.

    .DESCRIPTION
        This function creates a new check configuration for a specified resource within an Azure DevOps project.
        You need to provide the configuration in JSON format.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/myorganization.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER Configuration
        Mandatory. A string representing the check configuration in JSON format.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/add

    .EXAMPLE
        Initialize variables

        $approverId = 0000000-0000-0000-0000-000000000000
        $environmentId = 1

        $definitionRefId = '26014962-64a0-49f4-885b-4b874119a5cc' # Approval
        $definitionRefId = '0f52a19b-c67e-468f-b8eb-0ae83b532c99' # Pre-check approval

        Create configuration JSON

        $configJson = @{
            settings = @{
                approvers            = @(
                    @{
                        id = $approverId
                    }
                )
                executionOrder       = 'anyOrder'
                minRequiredApprovers = 0
                instructions         = 'Approval required before deploying to environment'
                blockedApprovers     = @()
                definitionRef        = @{
                    id = $definitionRefId
                }
            }
            timeout  = 1440 # 1 day
            type     = @{
                id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                name = 'Approval'
            }
            resource = @{
                type = 'environment'
                id   = $environmentId
            }
        } | ConvertTo-Json -Depth 5 -Compress

        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project'
            Configuration = $configJson
        }
        New-AdoCheckConfiguration @params

        Creates a new check configuration in the specified project using the provided configuration JSON.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(Mandatory)]
        [PSCustomObject[]]$Configuration,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("ApiVersion: $Version")

        Confirm-Defaults -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })

        $result = @()
    }

    process {
        try {

            $params = @{
                Uri     = "$CollectionUri/$ProjectName/_apis/pipelines/checks/configurations"
                Version = $Version
                Method  = 'POST'
            }

            foreach ($config in $Configuration) {

                if ($PSCmdlet.ShouldProcess($ProjectName, "Create Configuration on: $($config.resource.type)")) {
                    try {
                        $result += ($config | Invoke-AdoRestMethod @params)
                    } catch {
                        if ($_ -match 'already exists') {
                            Write-Warning "Configuration $($config.type.name) already exists for $($config.resource.type) with ID $($config.resource.id), trying to get it"

                            $params.Method = 'GET'
                            $params.QueryParameters = "resourceType=$($config.resource.type)&resourceId=$($config.resource.id)&`$expand=settings"
                            $result += (Invoke-AdoRestMethod @params).value | Where-Object { $_.settings.definitionRef.id -eq $config.settings.definitionRef.id }
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
            }

        } catch {
            throw $_
        }
    }

    end {
        if ($result) {
            $result | ForEach-Object {
                $result | ForEach-Object {
                    $obj = [ordered]@{
                        id = $_.id
                    }
                    if ($_.settings) {
                        $obj['settings'] = $_.settings
                    }
                    $obj['timeout'] = $_.timeout
                    $obj['type'] = $_.type
                    $obj['resource'] = $_.resource
                    $obj['createdBy'] = $_.createdBy.id
                    $obj['createdOn'] = $_.createdOn
                    $obj['project'] = $ProjectName
                    $obj['collectionUri'] = $CollectionUri

                    [PSCustomObject]$obj
                }
            }
        }

        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
