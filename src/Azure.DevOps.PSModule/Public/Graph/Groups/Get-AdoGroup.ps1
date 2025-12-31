function Get-AdoGroup {
    <#
    .SYNOPSIS
        Get a single or multiple groups in an Azure DevOps organization.

    .DESCRIPTION
        This function retrieves a single or multiple groups in an Azure DevOps organization through REST API.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://vssps.dev.azure.com/myorganization.

    .PARAMETER ScopeDescriptor
        Optional. Specify a non-default scope (collection, project) to search for groups.

    .PARAMETER SubjectTypes
        Optional. A comma separated list of user subject subtypes to reduce the retrieved results, e.g. Microsoft.IdentityModel.Claims.ClaimsIdentity

    .PARAMETER ContinuationToken
        Optional. An opaque data blob that allows the next page of data to resume immediately after where the previous page ended.
        The only reliable way to know if there is more data left is the presence of a continuation token.

    .PARAMETER DisplayName
        Optional. A comma separated list of group display names to filter the retrieved results.

    .PARAMETER Version
        The API version to use.

    .OUTPUTS
        PSCustomObject

    .LINK
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/get
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/list

    .EXAMPLE
        Get-AdoGroup

        Retrieves all groups in the Azure DevOps organization.

    .EXAMPLE
        $project = Get-AdoProject -Name 'my-project'
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
            CollectionUri = 'https://dev.azure.com/my-org'
            ScopeDescriptor = $projectDescriptor
            SubjectTypes    = 'vssgp'
        }
        @(
            'Project Administrators',
            'Release Administrators'
        ) | Get-AdoGroup @params

        Retrieves the 'Project Administrators' and 'Release Administrators' groups of type 'vssgp', demonstrating pipeline input.

    .NOTES
        Retrieves groups in an Azure DevOps organization.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$CollectionUri = ($env:DefaultAdoCollectionUri -replace 'https://', 'https://vssps.'),

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$ScopeDescriptor,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('vssgp', 'aadgp')]
        [string[]]$SubjectTypes = ('vssgp', 'aadgp'),

        [Parameter()]
        [string]$ContinuationToken,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]]$DisplayName,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("DisplayName: $($DisplayName -join ',')")
        Write-Debug ("ScopeDescriptor: $ScopeDescriptor")
        Write-Debug ("SubjectTypes: $($SubjectTypes -join ',')")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })
    }

    process {
        try {
            $queryParameters = [System.Collections.Generic.List[string]]::new()

            if ($ScopeDescriptor) {
                $queryParameters.Add("scopeDescriptor=$($ScopeDescriptor)")
            }

            if ($SubjectTypes) {
                $queryParameters.Add("subjectTypes=$([string]::Join(',', $SubjectTypes))")
            }

            if ($ContinuationToken) {
                $queryParameters.Add("continuationToken=$ContinuationToken")
            }

            if ($queryParameters.Count -gt 0) {
                $queryParameters = $queryParameters -join '&'
            }

            $params = @{
                Uri             = "$CollectionUri/_apis/graph/groups"
                Version         = $Version
                QueryParameters = $queryParameters
                Method          = 'GET'
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, 'Get Groups')) {

                $result = Invoke-AdoRestMethod @params
                $groups = $result.value

                if ($DisplayName) {
                    $groups = foreach ($n_ in $DisplayName) {
                        $groups | Where-Object { $_.displayName -eq $n_ }
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
            } else {
                if ($DisplayName) {
                    $params.DisplayName = ($DisplayName -join ',')
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
