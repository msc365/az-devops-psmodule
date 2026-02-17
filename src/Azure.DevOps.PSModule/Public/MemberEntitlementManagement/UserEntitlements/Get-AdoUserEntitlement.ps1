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

    .PARAMETER Version
        Optional. Version of the API to use. Default is '7.1'.

    .OUTPUTS
        PSCustomObject

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
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'GetUserEntitlement')]
        [ValidatePattern('^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')]
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
            $queryParameters = [List[string]]::new()

            if ($UserId) {
                $uri = "$CollectionUri/_apis/userentitlements/$UserId"
            } else {
                $uri = "$CollectionUri/_apis/userentitlements"

                # Build query parameters
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
                    $entitlements = if ($UserId) { @($results) } else { $results.items }

                    foreach ($e_ in $entitlements) {
                        $obj = [ordered]@{
                            id                  = $e_.id
                            user                = $e_.user
                            accessLevel         = $e_.accessLevel
                            dateCreated         = $e_.dateCreated
                            lastAccessedDate    = $e_.lastAccessedDate
                            projectEntitlements = if ($e_.projectEntitlements) { $e_.projectEntitlements } else { $null }
                            extensions          = if ($e_.extensions) { $e_.extensions } else { $null }
                            groupAssignments    = if ($e_.groupAssignments) { $e_.groupAssignments } else { $null }
                            collectionUri       = $CollectionUri
                        }
                        [PSCustomObject]$obj
                    }

                    $continuationToken = ($results.continuationToken | Select-Object -First 1)

                } while ($continuationToken)

            } catch {
                if ($_.ErrorDetails.Message -match 'UserEntitlementNotFoundException') {
                    Write-Warning "User entitlement not found for ID $UserId, skipping."
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
