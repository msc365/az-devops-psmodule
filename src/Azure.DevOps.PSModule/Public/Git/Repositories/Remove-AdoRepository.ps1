function Remove-AdoRepository {
    <#
    .SYNOPSIS
        Remove a repository from an Azure DevOps project.

    .DESCRIPTION
        This cmdlet removes a repository from an Azure DevOps project through REST API.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Mandatory. The ID or name of the project.

    .PARAMETER Name
        Mandatory. The repository ID or name to remove.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/git/repositories/delete

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            Id            = 'my-repository-1'
        }
        Remove-AdoRepository @params

        Removes the specified repository from the project.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('Id', 'RepositoryId')]
        [string]$Name,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.2')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Id: $($Id -join ',')")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            # Get repo ID if name was provided, id is required for deletion
            try {
                [System.Guid]::Parse($Name) | Out-Null
                $repoId = $Name
            } catch {
                $repoId = (Get-AdoRepository -CollectionUri $CollectionUri -ProjectName $ProjectName -Name $Name).id
                if (-not $repoId) { continue }
            }

            $uri = "$CollectionUri/$ProjectName/_apis/git/repositories/$repoId"

            $params = @{
                Uri     = $uri
                Version = $Version
                Method  = 'DELETE'
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, "Remove Repository '$($Name)' from project '$($ProjectName)'")) {
                try {
                    Invoke-AdoRestMethod @params | Out-Null
                } catch {
                    if ($_.ErrorDetails.Message -match 'NotFoundException') {
                        Write-Warning "Repository with ID $Name does not exist in project $ProjectName, skipping."
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
