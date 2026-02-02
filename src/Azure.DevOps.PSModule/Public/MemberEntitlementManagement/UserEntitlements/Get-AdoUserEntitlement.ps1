function Get-AdoUserEntitlement {
    <#
    .SYNOPSIS
        Get a paged set of user entitlements matching the filter criteria. If no filter is is passed, a page from all the account users is returned.

    .DESCRIPTION
        This cmdlet get a paged set of user entitlements matching the filter criteria. If no filter is is passed, a page from all the account users is returned.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER UserId
        Optional. ID of the user.

    .PARAMETER Filter
        Optional. Comma (",") separated list of properties and their values to filter on. Currently, the API only supports filtering by ExtensionId. An example parameter would be filter=extensionId eq search.

    .PARAMETER Select
        Optional. Comma (",") separated list of properties to select in the result entitlements. names of the properties are
         - 'Projects, 'Extensions' and 'Grouprules'.

    .PARAMETER Skip
        Optional. Offset: Number of records to skip. Default value is 0

    .PARAMETER Top
        Optional. Maximum number of the user entitlements to return. Max value is 10000. Default value is 100

    .PARAMETER ContinuationToken
        Optional. An opaque blob used to fetch the next page. If omitted, the cmdlet will automatically continue until all pages are returned.

    .PARAMETER Version
        Optional. Version of the API to use. Default is '7.1'.

    .OUTPUTS
        System.Collections.Specialized.OrderedDictionary

        The dictionary contains user entitlements:
        - `accessLevel`: User's access level denoted by a license.
        - `extensions`: User's extensions.
        - `groupAssigments`: [Readonly] GroupEntitlements that this user belongs to.
        - `id`: The unique identifier which matches the Id of the Identity associated with the GraphMember.
        - `lastAccessedDate`: [Readonly] Date the user last accessed the collection.
        - `projectEntitlements`: Relation between a project and the user's effective permissions in that project.
        - `user`: User reference.
        - `collectionUri`: The collection URI.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/memberentitlementmanagement/user-entitlements/get
        https://learn.microsoft.com/en-us/rest/api/azure/devops/memberentitlementmanagement/user-entitlements/search-user-entitlements

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        Get-AdoUserEntitlement @params -Top 5

        Retrieves the first 5 users from the specified organization.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        Get-AdoUserEntitlement @params -UserId '585edf88-4dd5-4a21-b13b-5770d00ed858'

        Retrieves the specified user by Id.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ListUserEntitlements')]
    [OutputType([ordered])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'GetUserEntitlement')]
        [ValidatePattern('^[0-9a-fA-F-]{36}$')]
        [Alias('Id')]
        [string]$UserId,

        [Parameter(ParameterSetName = 'ListUserEntitlements')]
        [string]$Filter,

        [Parameter(ParameterSetName = 'ListUserEntitlements')]
        [string]$Select,

        [Parameter(ParameterSetName = 'ListUserEntitlements')]
        [int]$Skip = 0,

        [Parameter(ParameterSetName = 'ListUserEntitlements')]
        [int]$Top = 100,

        [Parameter(ParameterSetName = 'ListUserEntitlements')]
        [string]$ContinuationToken,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.4')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("UserId: $UserId")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([Ordered]@{
                'CollectionUri' = $CollectionUri
            })

        if ($CollectionUri -notmatch 'vsaex\.') {
            $CollectionUri = $CollectionUri -replace 'https://', 'https://vsaex.'
        }
    }

    process {
        try {
            $uri = if ($UserId) {
                "$CollectionUri/_apis/userentitlements/$UserId"
            } else {
                "$CollectionUri/_apis/userentitlements"
            }

            # Loop until no continuation token is returned
            do {
                # Build query parameters for this iteration
                $queryParameters = [System.Collections.Generic.List[string]]::new()

                # Build query parameters
                if (-not $UserId) {
                    if ($Top) {
                        $queryParameters.Add("`$top=$Top")
                    }
                    if ($Skip) {
                        $queryParameters.Add("`$skip=$Skip")
                    }
                    if ($Filter) {
                        $queryParameters.Add("`$filter=$Filter")
                    }
                    if ($Select) {
                        $queryParameters.Add("`$select=$Select")
                    }
                }

                # If we have a token (incoming or from previous page), send it (URL-encoded)
                if ($ContinuationToken) {
                    $encoded = [System.Net.WebUtility]::UrlEncode($ContinuationToken)
                    $queryParameters.Add("continuationToken=$encoded")
                    Write-Verbose "Using continuationToken (encoded): $encoded"
                }

                $params = @{
                    Uri             = $uri
                    Version         = $Version
                    QueryParameters = if ($queryParameters.Count -gt 0) { $queryParameters -join '&' } else { $null }
                    Method          = 'GET'
                }

                try {
                    $results = Invoke-AdoRestMethod @params

                    # Extract items and output
                    $entitlements = if ($UserId) { @($results) } else { $results.items }

                    foreach ($e_ in $entitlements) {
                        [ordered]@{
                            accessLevel         = $e_.accessLevel
                            extensions          = if ($e_.extensions) { $e_.extensions } else { $null }
                            groupAssigments     = if ($e_.groupAssigments) { $e_.groupAssigments } else { $null }
                            id                  = $e_.id
                            lastAccessedDate    = $e_.lastAccessedDate
                            projectEntitlements = if ($e_.projectEntitlements) { $e_.projectEntitlements } else { $null }
                            user                = $e_.user
                            collectionUri       = $CollectionUri
                        }
                    }

                    $ContinuationToken = $null

                    if (-not $ContinuationToken -and ($results.PSObject.Properties.Name -contains 'continuationToken')) {
                        $ct = $results.continuationToken

                        if ($ct) {
                            $ContinuationToken = $ct
                            Write-Verbose "Continuation token from body: $ContinuationToken"
                        }
                    }
                } catch {
                    if ($_.ErrorDetails.Message -match 'MemberNotFoundException') {
                        Write-Warning "Identity not found with ID $UserId, skipping."
                    } else {
                        throw $_
                    }
                }
            } while ($ContinuationToken)
        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
