function Remove-AdoProject {
    <#
    .SYNOPSIS
        Remove a project from an Azure DevOps organization.

    .DESCRIPTION
        This cmdlet removes a project from an Azure DevOps organization.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/myorganization.

    .PARAMETER Id
        Mandatory. The ID or name of the project to remove.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/delete

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            Id            = 'my-project'
        }
        Remove-AdoProject @params -Verbose

        Removes the specified project from the organization.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        @('my-project-1', 'my-project-2') | Remove-AdoProject @params -Verbose

        Removes multiple projects demonstrating pipeline input.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('ProjectId')]
        [string[]]$Id,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.4')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("Id: $Id")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })
    }

    process {
        try {
            foreach ($id_ in $Id) {
                # Get id when name was provided, id is required for deletion
                try {
                    [System.Guid]::Parse($id_) | Out-Null
                    $projectId = $id_
                } catch {
                    $projectId = (Get-AdoProject -CollectionUri $CollectionUri -Name $id_).id
                    if (-not $projectId) { continue }
                }

                $params = @{
                    Uri     = "$CollectionUri/_apis/projects/$projectId"
                    Version = $Version
                    Method  = 'DELETE'
                }

                if ($PSCmdlet.ShouldProcess($CollectionUri, "Delete project: $id_")) {
                    try {
                        $results = Invoke-AdoRestMethod @params

                        # Poll for completion
                        $status = $results.status

                        while ($status -notin @('succeeded', 'failed')) {
                            Write-Verbose 'Checking project deletion status...'
                            Start-Sleep -Seconds 3

                            $pollParams = @{
                                Uri     = $results.url
                                Version = $Version
                                Method  = 'GET'
                            }
                            $results = Invoke-AdoRestMethod @pollParams
                            $status = $results.status
                        }

                        if ($status -eq 'failed') {
                            throw 'Project deletion failed.'
                        }

                    } catch {
                        if ($_.ErrorDetails.Message -match 'ProjectDoesNotExistWithNameException') {
                            Write-Warning "Project with ID $id_ does not exist, skipping."
                        } else {
                            throw $_
                        }
                    }
                } else {
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
