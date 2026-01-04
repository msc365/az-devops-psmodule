function Remove-AdoTeam {
    <#
    .SYNOPSIS
        Removes a team from an Azure DevOps project.

    .DESCRIPTION
        This cmdlet removes a team from an Azure DevOps project.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The ID or name of the project. If not specified, the default project is used.

    .PARAMETER Name
        Mandatory. The ID or name of the team to remove.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/delete

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        Remove-AdoTeam @params -Id 'my-team' -Verbose

        Removes the specified team from the project.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        @('team-1', 'team-2') | Remove-AdoTeam @params -Verbose

        Removes multiple teams demonstrating pipeline input.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('TeamName', 'Id', 'TeamId')]
        [string]$Name,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.3')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Id: $Id")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $params = @{
                Uri     = "$CollectionUri/_apis/projects/$ProjectName/teams/$Name"
                Version = $Version
                Method  = 'DELETE'
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, "Delete Team: $Name from Project: $ProjectName")) {
                try {
                    Invoke-AdoRestMethod @params | Out-Null
                } catch {
                    if ($_.ErrorDetails.Message -match 'NotFoundException') {
                        Write-Warning "Team with Name $Name does not exist, skipping deletion."
                    } else {
                        throw $_
                    }
                }

            } else {
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
