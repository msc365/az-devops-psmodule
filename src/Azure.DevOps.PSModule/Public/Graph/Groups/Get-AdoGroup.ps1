function Get-AdoGroup {
    <#
    .SYNOPSIS
        Get a single or multiple groups in an Azure DevOps organization.

    .DESCRIPTION
        This function retrieves a single or multiple groups in an Azure DevOps organization through REST API.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://vssps.dev.azure.com/my-org.

    .PARAMETER ScopeDescriptor
        Optional. Specify a non-default scope (collection, project) to search for groups.

    .PARAMETER SubjectTypes
        Optional. A comma separated list of user subject subtypes to reduce the retrieved results, e.g. Microsoft.IdentityModel.Claims.ClaimsIdentity

    .PARAMETER ContinuationToken
        Optional. An opaque data blob that allows the next page of data to resume immediately after where the previous page ended.
        The only reliable way to know if there is more data left is the presence of a continuation token.

    .PARAMETER Name
        Optional. A group's display name to filter the retrieved results.

    .PARAMETER Version
        The API version to use. Default is '7.2-preview.1'.
        The -preview flag must be supplied in the api-version for this request to work.

    .OUTPUTS
        PSCustomObject

    .LINK
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/get
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/list

    .EXAMPLE
        Get-AdoGroup

        Retrieves all groups in the Azure DevOps organization.

    .EXAMPLE
        $project = Get-AdoProject -Name 'my-project-1'
        $projectDescriptor = (Get-AdoDescriptor -StorageKey $project.Id)

        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ScopeDescriptor = $projectDescriptor
            SubjectTypes    = 'vssgp'
        }
        Get-AdoGroup @params

        Retrieves all groups in the specified project with subject types 'vssgp'.

    .EXAMPLE
        $params = @{
            SubjectTypes    = 'vssgp'
            ScopeDescriptor = $projectDescriptor
            Name            = @(
                'Project Administrators',
                'Contributors'
            )
        }
        Get-AdoGroup @params

        Retrieves the 'Project Administrators' and 'Contributors' groups in the specified scope with subject types 'vssgp'.

    .EXAMPLE
        @(
            'vssgp.00000000-0000-0000-0000-000000000000',
            'vssgp.00000000-0000-0000-0000-000000000001',
            'vssgp.00000000-0000-0000-0000-000000000002'
        ) | Get-AdoGroup

        Retrieves the groups with the specified descriptors.

    .NOTES
        Retrieves groups in an Azure DevOps organization.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ListGroups')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ListGroups')]
        [string]$ScopeDescriptor,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ListGroups')]
        [ValidateSet('vssgp', 'aadgp')]
        [string[]]$SubjectTypes = @('vssgp', 'aadgp'),

        [Parameter(ParameterSetName = 'ListGroups')]
        [string]$ContinuationToken,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ListGroups')]
        [Alias('DisplayName', 'GroupName')]
        [string[]]$Name,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'ByDescriptor')]
        [string]$GroupDescriptor,

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
        Write-Debug ("ContinuationToken: $ContinuationToken")
        Write-Debug ("Name: $($Name -join ',')")
        Write-Debug ("GroupDescriptor: $GroupDescriptor")
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
            $queryParameters = [System.Collections.Generic.List[string]]::new()

            if ($GroupDescriptor) {
                $uri = "$CollectionUri/_apis/graph/groups/$GroupDescriptor"
            } else {
                $uri = "$CollectionUri/_apis/graph/groups"

                if ($ScopeDescriptor) {
                    $queryParameters.Add("scopeDescriptor=$($ScopeDescriptor)")
                }

                if ($SubjectTypes) {
                    $queryParameters.Add("subjectTypes=$([string]::Join(',', $SubjectTypes))")
                }

                if ($ContinuationToken) {
                    $queryParameters.Add("continuationToken=$ContinuationToken")
                }
            }

            $params = @{
                Uri             = $uri
                Version         = $Version
                QueryParameters = if ($queryParameters.Count -gt 0) { $queryParameters -join '&' } else { $null }
                Method          = 'GET'
            }

            try {
                $results = Invoke-AdoRestMethod @params
                $groups = if ($GroupDescriptor) { @($results) } else { $results.value }

                if ($Name) {
                    $groups = foreach ($n_ in $Name) {
                        $groups | Where-Object { -not $n_ -or $_.displayName -like $n_ }
                    }
                }

                foreach ($g_ in $groups) {
                    $obj = [ordered]@{
                        displayName   = $g_.displayName
                        originId      = $g_.originId
                        principalName = $g_.principalName
                        origin        = $g_.origin
                        subjectKind   = $g_.subjectKind
                        description   = $g_.description
                        mailAddress   = $g_.mailAddress
                        descriptor    = $g_.descriptor
                        collectionUri = $CollectionUri
                    }
                    if ($result.continuationToken) {
                        $obj['continuationToken'] = $result.continuationToken
                    }
                    [PSCustomObject]$obj
                }
            } catch {
                if ($_.ErrorDetails.Message -match 'InvalidSubjectTypeException') {
                    Write-Warning "Subject with scope descriptor $ScopeDescriptor does not exist, skipping."
                } elseif ($_.ErrorDetails.Message -match 'GraphSubjectNotFoundException') {
                    Write-Warning "Subject with group descriptor $GroupDescriptor does not exist, skipping."
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
