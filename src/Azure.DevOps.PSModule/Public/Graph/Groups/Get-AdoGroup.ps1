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
        Optional. An opaque data blob that allows the next page of data to resume immediately after where the previous page ended. The only reliable way to know if there is more data left is the presence of a continuation token.

    .PARAMETER DisplayName
        Optional. A comma separated list of group display names to filter the retrieved results.

    .PARAMETER ApiVersion
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
        $project = Get-AdoProject -ProjectName 'my-project'
        $projectDescriptor = (Get-AdoDescriptor -StorageKey $project.Id)

        Get-AdoGroup -ScopeDescriptor $projectDescriptor -SubjectTypes 'vssgp'

        Retrieves all groups in the specified project with subject types 'vssgp'.

    .EXAMPLE
        $params = @{
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

        Confirm-Defaults -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })

        $result = @()
    }

    process {
        try {
            $queryParameters = @()

            if ($ScopeDescriptor) {
                $queryParameters += "scopeDescriptor=$($ScopeDescriptor)"
            }

            if ($SubjectTypes) {
                $queryParameters += "subjectTypes=$([string]::Join(',', $SubjectTypes))"
            }

            if ($ContinuationToken) {
                $queryParameters += "continuationToken=$ContinuationToken"
            }

            if ($queryParameters.Count -gt 0) {
                $queryParameters = ($queryParameters -join '&')
            }

            $params = @{
                Uri             = "$CollectionUri/_apis/graph/groups"
                Version         = $Version
                QueryParameters = $queryParameters
                Method          = 'GET'
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, 'Get Groups')) {

                $response = (Invoke-AdoRestMethod @params)
                # TODO: Handle continuation token to get all groups
                $groups = $response.value

                if ($DisplayName) {
                    foreach ($name in $DisplayName) {
                        $result += $groups | Where-Object displayName -EQ $name
                    }
                } else {
                    $result += $groups
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
        if ($result) {
            $result | ForEach-Object {
                $_
            }
        }
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
