function New-AdoCheckConfiguration {
    <#
    .SYNOPSIS
        Create a new check configuration for a specific resource.

    .DESCRIPTION
        This function creates a new check configuration for a specified resource within an Azure DevOps project.
        When existing configuration is found, it will be returned instead of creating a new one.

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
        $approverId = 0000000-0000-0000-0000-000000000000
        $environmentId = 1

        $definitionRefId = '26014962-64a0-49f4-885b-4b874119a5cc' # Approval
        $definitionRefId = '0f52a19b-c67e-468f-b8eb-0ae83b532c99' # Pre-check approval

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

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {

            $params = @{
                Uri     = "$CollectionUri/$ProjectName/_apis/pipelines/checks/configurations"
                Version = $Version
                Method  = 'POST'
            }

            foreach ($c_ in $Configuration) {

                if ($PSCmdlet.ShouldProcess($ProjectName, "Create Configuration on: $($c_.resource.type)")) {
                    try {
                        $results = $c_ | Invoke-AdoRestMethod @params

                        $obj = [ordered]@{
                            id = $results.id
                        }
                        if ($results.settings) {
                            $obj['settings'] = $results.settings
                        }
                        $obj['timeout'] = $results.timeout
                        $obj['type'] = $results.type
                        $obj['resource'] = $results.resource
                        $obj['createdBy'] = $results.createdBy.id
                        $obj['createdOn'] = $results.createdOn
                        $obj['project'] = $ProjectName
                        $obj['collectionUri'] = $CollectionUri
                        [PSCustomObject]$obj

                    } catch {
                        if ($_ -match 'already exists') {
                            Write-Warning "$($c_.type.name) already exists for $($c_.resource.type) with ID $($c_.resource.id), trying to get it"

                            $params.Method = 'GET'
                            $params.QueryParameters = "resourceType=$($c_.resource.type)&resourceId=$($c_.resource.id)&`$expand=settings"

                            $results = (Invoke-AdoRestMethod @params).value | Where-Object {
                                $_.settings.definitionRef.id -eq $c_.settings.definitionRef.id
                            }

                            foreach ($r_ in $results) {
                                $obj = [ordered]@{
                                    id = $r_.id
                                }
                                if ($r_.settings) {
                                    $obj['settings'] = $r_.settings
                                }
                                $obj['timeout'] = $r_.timeout
                                $obj['type'] = $r_.type
                                $obj['resource'] = $r_.resource
                                $obj['createdBy'] = $r_.createdBy.id
                                $obj['createdOn'] = $r_.createdOn
                                $obj['project'] = $ProjectName
                                $obj['collectionUri'] = $CollectionUri
                                [PSCustomObject]$obj

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
            }

        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
