function Set-AdoProject {
    <#
    .SYNOPSIS
        Updates an existing Azure DevOps project.

    .DESCRIPTION
        This cmdlet updates an existing Azure DevOps project within a specified organization.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER Id
        Mandatory. The ID (uuid) of the project to update.

    .PARAMETER Name
        Optional. The new name of the project.

    .PARAMETER Description
        Optional. The new description of the project.

    .PARAMETER Visibility
        Optional. The visibility of the project. Default is 'Private'.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/update

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            Id            = '00000000-0000-0000-0000-000000000000'
            Name          = 'my-project-updated'
        }
        Set-AdoProject @params -Verbose

        Updates the name of the specified project.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        [PSCustomObject]@{
            Id          = '00000000-0000-0000-0000-000000000000'
            Name        = 'my-project-updated'
            Description = 'Updated description'
        } | Set-AdoProject @params -Verbose

        Updates the project using pipeline input.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('ProjectId')]
        [string]$Id,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectName')]
        [string]$Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Description,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('Private', 'Public')]
        [string]$Visibility,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.4')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("Id: $Id")
        Write-Debug ("Name: $Name")
        Write-Debug ("Description: $Description")
        Write-Debug ("Visibility: $Visibility")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })
    }

    process {
        try {
            # Get id when name was provided, id is required for update
            try {
                [System.Guid]::Parse($Id) | Out-Null
                $projectId = $Id
            } catch {
                $projectId = (Get-AdoProject -CollectionUri $CollectionUri -Name $Id).id
                if (-not $projectId) { continue }
            }

            $params = @{
                Uri     = "$CollectionUri/_apis/projects/$projectId"
                Version = $Version
                Method  = 'PATCH'
            }

            $body = [PSCustomObject]@{}

            if ($PSBoundParameters.ContainsKey('Name')) {
                $body | Add-Member -NotePropertyName 'name' -NotePropertyValue $Name
            }
            if ($PSBoundParameters.ContainsKey('Description')) {
                $body | Add-Member -NotePropertyName 'description' -NotePropertyValue $Description
            }
            if ($PSBoundParameters.ContainsKey('Visibility')) {
                $body | Add-Member -NotePropertyName 'visibility' -NotePropertyValue $Visibility
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, "Update project: $Id")) {
                try {
                    $results = $body | Invoke-AdoRestMethod @params

                    # Poll for completion
                    $status = $results.status
                    while ($status -notin @('succeeded', 'failed')) {
                        Write-Verbose 'Checking project update status...'
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
                        throw 'Project update failed.'
                    }

                    # Get the updated project details
                    $results = Get-AdoProject -CollectionUri $CollectionUri -Id $projectId -IncludeCapabilities

                    [PSCustomObject]@{
                        id            = $results.id
                        name          = $results.name
                        description   = $results.description
                        visibility    = $results.visibility
                        state         = $results.state
                        defaultTeam   = $results.defaultTeam
                        collectionUri = $CollectionUri
                    }

                } catch {
                    if ($_.ErrorDetails.Message -match 'ProjectDoesNotExistWithNameException') {
                        Write-Warning "Project with ID $Id does not exist, skipping."
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
