function Get-AdoUserEntitlements {
    <#
    .SYNOPSIS
        Get a paged set of user entitlements matching the filter criteria. If no filter is is passed, a page from all the
        account users is returned.

    .DESCRIPTION
        This cmdlet get a paged set of user entitlements matching the filter criteria. If no filter is is passed, a page from
        all the account users is returned.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER UserId
        Optional. ID of the user.

    .PARAMETER Filter
        Optional. Comma (",") separated list of properties and their values to filter on. Currently, the API only supports
        filtering by ExtensionId. An example parameter would be filter=extensionId eq search.

    .PARAMETER Select
        Optional. Comma (",") separated list of properties to select in the result entitlements. names of the properties are
         - 'Projects, 'Extensions' and 'Grouprules'.

    .PARAMETER Skip
        Optional. Offset: Number of records to skip. Default value is 0

    .PARAMETER Top
        Optional. Maximum number of the user entitlements to return. Max value is 10000. Default value is 100

    .PARAMETER Version
        Optional. Version of the API to use. Default is '4.1-preview.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/memberentitlementmanagement/user-entitlements/get
        https://learn.microsoft.com/en-us/rest/api/azure/devops/memberentitlementmanagement/user-entitlements/list

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        Get-AdoUserEntitlements @params -Top 5

        Retrieves the first 5 users from the specified organization.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        Get-AdoUserEntitlements @params -UserId 123

        Retrieves the specified user by Id.
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', 'Get-AdoUserEntitlements')]
    [CmdletBinding(DefaultParameterSetName = 'ListUsers')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'ByUserId')]
        [ValidatePattern('^[0-9a-fA-F-]{36}$')]
        [Alias('Id')]
        [string]$UserId,

        [Parameter(ParameterSetName = 'ListUsers')]
        [string]$Filter,

        [Parameter(ParameterSetName = 'ListUsers')]
        [string]$Select,

        [Parameter(ParameterSetName = 'ListUsers')]
        [int]$Skip = 0,

        [Parameter(ParameterSetName = 'ListUsers')]
        [int]$Top = 100,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('4.1-preview.1')]
        [string]$Version = '4.1-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("UserId: $UserId")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([Ordered]@{
                'CollectionUri' = $CollectionUri
            })
    }

    process {
        try {
            $queryParameters = [System.Collections.Generic.List[string]]::new()
            $organization = $CollectionUri.Split('/')[-1]

            if ($UserId) {
                $uri = "https://vsaex.dev.azure.com/$organization/_apis/userentitlements/$UserId"
            } else {
                $uri = "https://vsaex.dev.azure.com/$organization/_apis/userentitlements"

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
                $results = Invoke-AdoRestMethod @params
                $entitlements = if ($UserId) { @($results) } else { $results.value }

                foreach ($e_ in $entitlements) {
                    $obj = [ordered]@{
                        accesLevel          = $e_.accesLevel
                        extensions          = if ($e_.extensions) { $e_.extensions } else { $null }
                        groupAssigments     = if ($e_.groupAssigments) { $e_.groupAssigments } else { $null }
                        id                  = $e_.id
                        lastAccessedDate    = $e_.lastAccessedDate
                        projectEntitlements = if ($e_.projectEntitlements) { $e_.projectEntitlements } else { $null }
                        user                = $e_.user
                    }

                    # Output the entitlements object
                    [PSCustomObject]$obj
                }
            } catch {
                if ($_.ErrorDetails.Message -match 'MemberNotFoundException') {
                    Write-Warning "Identity not found with ID $UserId, skipping."
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
