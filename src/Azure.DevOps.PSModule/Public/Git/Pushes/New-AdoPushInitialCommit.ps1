function New-AdoPushInitialCommit {
    <#
    .SYNOPSIS
        Creates a new initial commit in a specified Azure DevOps repository.

    .DESCRIPTION
        This cmdlet allows you to create an initial commit in a specified Azure DevOps repository.
        You can specify the content of the commit, the commit message, and the branch to which the commit will be pushed.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Mandatory. The ID or name of the project.

    .PARAMETER RepositoryName
        Mandatory. The name or ID of the repository.

    .PARAMETER BranchName
        Optional. The name of the branch to which the initial commit will be pushed. Default is 'main'.

    .PARAMETER Message
        Optional. The commit message for the initial commit. Default is 'Initial commit'.

    .PARAMETER Files
        Optional. An array of file objects to include in the initial commit. Each file object should have the following properties:
        - path: The path to the file in the repository.
        - content: The content of the file.
        - contentType: The type of content ('rawtext' or 'base64encoded').

        Default is a single file with path '/README.md' and content '# Initial Commit'.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .OUTPUTS
        A custom object containing details about the push operation.

        [PSCustomObject]@{
            pushId        = The ID of the push operation.
            commits       = The commits included in the push.
            refUpdates    = The reference updates for the push.
            pushedBy      = The user who initiated the push.
            date          = The date and time of the push.
            projectName   = The name of the project.
            collectionUri = The URI of the Azure DevOps collection.
        }

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pushes/get

    .EXAMPLE
        $params = @{
            CollectionUri  = 'https://dev.azure.com/my-org'
            ProjectName    = 'my-project-1'
            RepositoryName = 'my-repository-1'
            BranchName     = 'main'
            Message        = 'Initial commit'
            Files          = @(
                @{
                    path        = '/README.md'
                    content     = (Get-Content -Path 'C:/_tmp/README.md' -Raw)
                    contentType = 'rawtext'
                },
                @{
                    path        = '/devops/pipeline/ci.yml'
                    content     = (Get-Content -Path 'C:/_tmp/ci.yml' -Raw)
                    contentType = 'rawtext'
                },
                @{
                    path        = '/.assets/tools.zip'
                    content     = [Convert]::ToBase64String([IO.File]::ReadAllBytes('C:/_tmp/tools.zip'))
                    contentType = 'base64encoded'
                }
            )
        }
        New-AdoPushInitialCommit @params

        Creates a new initial commit with the specified content in the specified repository and branch.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('RepositoryId')]
        [string]$RepositoryName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$BranchName = 'main',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Message = 'Initial commit',

        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$Files = @(
            @{
                path        = '/README.md'
                content     = '# Initial Commit'
                contentType = 'rawtext'
            }
        ),

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.2')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("RepositoryName: $RepositoryName")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $params = @{
                Uri     = "$CollectionUri/$ProjectName/_apis/git/repositories/$RepositoryName/pushes"
                Version = $Version
                Method  = 'POST'
            }

            $changes = @()
            foreach ($file in $Files) {
                $change = @{
                    changeType = 'add'
                    item       = @{
                        path = $file.path
                    }
                    newContent = @{
                        content     = $file.content
                        contentType = $file.contentType
                    }
                }
                $changes += $change
            }

            $body = [PSCustomObject]@{
                refUpdates = @(
                    [ordered]@{
                        name        = "refs/heads/$BranchName"
                        oldObjectId = '0000000000000000000000000000000000000000'
                    }
                )
                commits    = @(
                    [ordered]@{
                        comment = $Message
                        changes = $changes
                    }
                )
            }

            if ($PSCmdlet.ShouldProcess($RepositoryName, "Push Initial Commit to: $BranchName")) {
                try {
                    $results = $body | Invoke-AdoRestMethod @params

                    [PSCustomObject]@{
                        pushId        = $results.pushId
                        commits       = $results.commits
                        refUpdates    = $results.refUpdates
                        pushedBy      = $results.pushedBy
                        date          = $results.date
                        projectName   = $results.projectName
                        collectionUri = $CollectionUri
                    }
                } catch {
                    if ($_.ErrorDetails.Message -match 'GitReferenceStaleException') {
                        Write-Warning "Oops! The reference 'refs/heads/$BranchName' has already been initialized by another client, so you cannot update it."

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
