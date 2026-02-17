function Get-AdoUser {
    <#
    .SYNOPSIS
        Get a single or multiple users in an Azure DevOps organization.

    .DESCRIPTION
        This function retrieves a single or multiple users in an Azure DevOps organization through REST API.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://vssps.dev.azure.com/my-org.

    .PARAMETER ScopeDescriptor
        Optional. Specify a non-default scope (collection, project) to search for users.

    .PARAMETER SubjectTypes
        Optional. A comma separated list of user subject subtypes to reduce the retrieved results, e.g. 'msa', 'aad', 'svc' (service identity), 'imp' (imported identity), etc.

    .PARAMETER Name
        Optional. A user's display name to filter the retrieved results.

    .PARAMETER UserDescriptor
        Optional. The descriptor of a specific user to retrieve. When provided, retrieves a single user by its descriptor.

    .PARAMETER Version
        The API version to use for the request. Default is '7.2-preview.1'.
        The -preview flag must be supplied in the api-version for this request to work.

    .OUTPUTS
        PSCustomObject

    .LINK
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/users/get
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/users/list

    .EXAMPLE
        Get-AdoUser

        Retrieves all users in the Azure DevOps organization.

    .EXAMPLE
        $project = Get-AdoProject -Name 'my-project-1'
        $projectDescriptor = (Get-AdoDescriptor -StorageKey $project.Id)

        $params = @{
            CollectionUri   = 'https://dev.azure.com/my-org'
            ScopeDescriptor = $projectDescriptor
            SubjectTypes    = 'aad'
        }
        Get-AdoUser @params

        Retrieves all users in the specified project with subject types 'aad'.

    .EXAMPLE
        @(
            'aad.00000000-0000-0000-0000-000000000000',
            'aad.00000000-0000-0000-0000-000000000001',
            'aad.00000000-0000-0000-0000-000000000002'
        ) | Get-AdoUser

        Retrieves the users with the specified descriptors.

    .NOTES
        Retrieves users in an Azure DevOps organization.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ListUsers')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ListUsers')]
        [string]$ScopeDescriptor,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ListUsers')]
        [ValidateSet('msa', 'aad', 'svc', 'imp')]
        [string[]]$SubjectTypes = @('msa', 'aad', 'svc', 'imp'),

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ListUsers')]
        [Alias('DisplayName', 'UserName')]
        [string[]]$Name,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'ByDescriptor')]
        [string]$UserDescriptor,

        [Parameter(HelpMessage = 'The -preview flag must be supplied in the api-version for this request to work.')]
        [Alias('ApiVersion')]
        [ValidateSet('7.1-preview.1', '7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ScopeDescriptor: $ScopeDescriptor")
        Write-Debug ("SubjectTypes: $($SubjectTypes -join ',')")
        Write-Debug ("Name: $($Name -join ',')")
        Write-Debug ("UserDescriptor: $UserDescriptor")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })

        if ($CollectionUri -notmatch 'vssps\.') {
            $CollectionUri = $CollectionUri -replace 'https://', 'https://vssps.'
        }
    }

    process {
        try {
            $queryParameters = [List[string]]::new()

            if ($UserDescriptor) {
                $uri = "$CollectionUri/_apis/graph/users/$UserDescriptor"
            } else {
                $uri = "$CollectionUri/_apis/graph/users"

                if ($ScopeDescriptor) {
                    $queryParameters.Add("scopeDescriptor=$($ScopeDescriptor)")
                }

                if ($SubjectTypes) {
                    $queryParameters.Add("subjectTypes=$([string]::Join(',', $SubjectTypes))")
                }
            }

            $params = @{
                Uri             = $uri
                Version         = $Version
                QueryParameters = if ($queryParameters.Count -gt 0) { $queryParameters -join '&' } else { $null }
                Method          = 'GET'
            }

            try {
                $continuationToken = $null

                do {
                    $pagedParams = [List[string]]::new()

                    if ($queryParameters.Count) {
                        $pagedParams.AddRange($queryParameters)
                    }
                    if ($continuationToken) {
                        $pagedParams.Add("continuationToken=$([uri]::EscapeDataString($continuationToken))")
                    }

                    $params.QueryParameters = if ($pagedParams.Count) { $pagedParams -join '&' } else { $null }

                    $results = Invoke-AdoRestMethod @params
                    $users = if ($UserDescriptor) { @($results) } else { $results.value }

                    if ($Name) {
                        $users = foreach ($n_ in $Name) {
                            $users | Where-Object { -not $n_ -or $_.displayName -like $n_ }
                        }
                    }

                    foreach ($u_ in $users) {
                        $obj = [ordered]@{
                            subjectKind       = $u_.subjectKind
                            directoryAlias    = $u_.directoryAlias
                            domain            = $u_.domain
                            principalName     = $u_.principalName
                            mailAddress       = $u_.mailAddress
                            origin            = $u_.origin
                            originId          = $u_.originId
                            displayName       = $u_.displayName
                            descriptor        = $u_.descriptor
                            isDeletedInOrigin = $u_.isDeletedInOrigin
                            metaType          = $u_.metaType
                            collectionUri     = $CollectionUri
                        }
                        [PSCustomObject]$obj
                    }

                    $continuationToken = ($results.continuationToken | Select-Object -First 1)

                } while ($continuationToken)
            } catch {
                if ($_.ErrorDetails.Message -match 'InvalidSubjectTypeException') {
                    Write-Warning "Subject with scope descriptor $ScopeDescriptor does not exist, skipping."
                } elseif ($_.ErrorDetails.Message -match 'GraphSubjectNotFoundException') {
                    Write-Warning "Subject with user descriptor $UserDescriptor does not exist, skipping."
                } else {
                    throw $_
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
