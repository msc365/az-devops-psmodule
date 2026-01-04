function New-AdoProject {
    <#
    .SYNOPSIS
        Create a new project in an Azure DevOps organization.

    .DESCRIPTION
        This cmdlet creates a new Azure DevOps project within a specified organization.
        When a project with the specified name already exists, it will be returned instead of creating a new one.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER Name
        Mandatory. The name of the project to create.

    .PARAMETER Description
        Optional. The description of the project.

    .PARAMETER Process
        Optional. The process to use for the project. Default is 'Agile'.

    .PARAMETER SourceControl
        Optional. The source control type to use for the project. Default is 'Git'.

    .PARAMETER Visibility
        Optional. The visibility of the project. Default is 'Private'.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/create

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            Name          = 'my-project-1'
            Description   = 'My new project'
        }
        New-AdoProject @params -Verbose

        Creates a new project in the specified organization.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        @('my-project-1', 'my-project-2') | New-AdoProject @params -Verbose

        Creates multiple projects demonstrating pipeline input.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]]$Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Description,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('Agile', 'Scrum', 'CMMI', 'Basic')]
        [string]$Process = 'Agile',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('Git', 'Tfvc')]
        [string]$SourceControl = 'Git',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('Private', 'Public')]
        [string]$Visibility = 'Private',

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.4')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("Name: $Name")
        Write-Debug ("Description: $Description")
        Write-Debug ("Process: $Process")
        Write-Debug ("SourceControl: $SourceControl")
        Write-Debug ("Visibility: $Visibility")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })

        # Get process template ID once for efficiency
        $processTemplate = Get-AdoProcess -Name $Process
        if (-not $processTemplate) {
            throw "Process template '$Process' not found."
        }
    }

    process {
        try {
            $params = @{
                Uri     = "$CollectionUri/_apis/projects"
                Version = $Version
                Method  = 'POST'
            }

            foreach ($name_ in $Name) {

                $body = [PSCustomObject]@{
                    name         = $name_
                    description  = $Description
                    capabilities = @{
                        versioncontrol  = @{
                            sourceControlType = $SourceControl
                        }
                        processTemplate = @{
                            templateTypeId = $processTemplate.id
                        }
                    }
                    visibility   = $Visibility
                }

                if ($PSCmdlet.ShouldProcess($CollectionUri, "Create project: $name_")) {
                    try {
                        $results = $body | Invoke-AdoRestMethod @params

                        # Poll for completion
                        $status = $results.status

                        while ($status -notin @('succeeded', 'failed')) {
                            Write-Verbose 'Checking project creation status...'
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
                            throw 'Project creation failed.'
                        }

                        # Get the created project details
                        $results = Get-AdoProject -CollectionUri $CollectionUri -Name $name_

                        [PSCustomObject]@{
                            id            = $results.id
                            name          = $results.name
                            description   = $results.description
                            visibility    = $results.visibility
                            state         = $results.state
                            defaultTeam   = $results.DefaultTeam
                            collectionUri = $CollectionUri
                        }

                    } catch {
                        if ($_.ErrorDetails.Message -match 'ProjectAlreadyExistsException') {
                            Write-Warning "Project $name_ already exists, trying to get it"

                            $results = Get-AdoProject -CollectionUri $CollectionUri -Name $name_

                            [PSCustomObject]@{
                                id            = $results.id
                                name          = $results.name
                                description   = $results.description
                                visibility    = $results.visibility
                                state         = $results.state
                                defaultTeam   = $results.DefaultTeam
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
            }
        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
