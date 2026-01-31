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
            - `accountLicenseType`: Type of Account License (e.g. Express, Stakeholder etc.)
            - `assignmentSource`: Assignment Source of the License (e.g. Group, Unknown etc.
            - `licenseDisplayName`: Display name of the License
            - `licensingSource`: Licensing Source (e.g. Account. MSDN etc.)
            - `msdnLicenseType`: Type of MSDN License (e.g. Visual Studio Professional, Visual Studio Enterprise etc.)
            - `status`: User status in the account
            - `statusMessage`: Status message.
        - `extensions`: User's extensions.
            - `assignmentSource`: Assignment source for this extension. I.e. explicitly assigned or from a group rule.
            - `id`: Gallery Id of the Extension.
            - `name`: Friendly name of this extension.
            - `source`: Source of this extension assignment. Ex: msdn, account, none, etc.
        - `groupAssigments`: [Readonly] GroupEntitlements that this user belongs to.
            - `extensionRules`: Extension Rules.
                - `assignmentSource`: Assignment source for this extension. I.e. explicitly assigned or from a group rule.
                - `id`: Gallery Id of the Extension.
                - `name`: Friendly name of this extension.
                - `source`: Source of this extension assignment. Ex: msdn, account, none, etc.
            - `group`: Member reference.
                - `_links`: This field contains zero or more interesting links about the graph subject. These links may be invoked to obtain additional relationships or more detailed information about this graph subject.
                    - `links`: The readonly view of the links. Because Reference links are readonly, we only want to expose them as read only.
                - `cuid`: The Consistently Unique Identifier of the subject
                - `description`: A short phrase to help human readers disambiguate groups with similar names
                - `descriptor`: The descriptor is the primary way to reference the graph subject while the system is running. This field will uniquely identify the same graph subject across both Accounts and Organizations.
                - `displayName`: This is the non-unique display name of the graph subject. To change this field, you must alter its value in the source provider.
                - `domain`: This represents the name of the container of origin for a graph member. (For MSA this is "Windows Live ID", for AD the name of the domain, for AAD the tenantID of the directory, for VSTS groups the ScopeId, etc)
                - `legacyDescriptor`: [Internal Use Only] The legacy descriptor is here in case you need to access old version IMS using identity descriptor.
                - `mailAddress`: The email address of record for a given graph member. This may be different than the principal name.
                - `origin`: The type of source provider for the origin identifier (ex:AD, AAD, MSA)
                - `originId`: The unique identifier from the system of origin. Typically a sid, object id or Guid. Linking and unlinking operations can cause this value to change for a user because the user is not backed by a different provider and has a different unique id in the new provider.
                - `principalName`: This is the PrincipalName of this graph member from the source provider. The source provider may change this field over time and it is not guaranteed to be immutable for the life of the graph member by VSTS.
                - `subjectKind`: This field identifies the type of the graph subject (ex: Group, Scope, User).
                - `url`: This url is the full route to the source resource of this graph subject.
            - `id`: The unique identifier which matches the Id of the GraphMember.
            - `lastExecuted`: [Readonly] The last time the group licensing rule was executed (regardless of whether any changes were made).
            - `licenseRule`: License Rule.
                - `accountLincenseType`: Type of Account License (e.g. Express, Stakeholder etc.)
                - `assignmentSource`: Assignment Source of the License (e.g. Group, Unknown etc.
                - `licenseDisplayName`: Display name of the License
                - `licensingSource`: Licensing Source (e.g. Account. MSDN etc.)
                - `msdnLicenseType`: Type of MSDN License (e.g. Visual Studio Professional, Visual Studio Enterprise etc.)
                - `status`: User status in the account
                - `statusMessage`: Status message.
            - `members`: Group members. Only used when creating a new group.
            - `projectEntitlements`: Relation between a project and the member's effective permissions in that project.
            - `status`: The status of the group rule.
        - `id`: The unique identifier which matches the Id of the Identity associated with the GraphMember.
        - `lastAccessedDate`: [Readonly] Date the user last accessed the collection.
        - `projectEntitlements`: Relation between a project and the user's effective permissions in that project.
            - `assignmentSource`: Assignment Source (e.g. Group or Unknown).
            - `group`: Project Group (e.g. Contributor, Reader etc.)
                - `displayName`: Display Name of the Group
                - `groupType`: Group Type
            - `isProjectPermissionInherited`: Whether the user is inheriting permissions to a project through a VSTS or AAD group membership.
            - `projectRef`: Project Ref
                - `id`: Project ID.
                - `name`: Project Name.
            - `teamRefs`: Team Ref.
                - `id`: Team ID.
                - `name`: Team Name.
        - `user`: User reference.
            - `_links`: This field contains zero or more interesting links about the graph subject. These links may be invoked to obtain additional relationships or more detailed information about this graph subject.
                - `links`: The readonly view of the links. Because Reference links are readonly, we only want to expose them as read only.
            - `cuid`: The Consistently Unique Identifier of the subject
            - `descriptor`: The descriptor is the primary way to reference the graph subject while the system is running. This field will uniquely identify the same graph subject across both Accounts and Organizations.
            - `displayName`: This is the non-unique display name of the graph subject. To change this field, you must alter its value in the source provider.
            - `domain`: This represents the name of the container of origin for a graph member. (For MSA this is "Windows Live ID", for AD the name of the domain, for AAD the tenantID of the directory, for VSTS groups the ScopeId, etc)
            - `legacyDescriptor`: [Internal Use Only] The legacy descriptor is here in case you need to access old version IMS using identity descriptor.
            - `mailAddress`: The email address of record for a given graph member. This may be different than the principal name.
            - `metaType`: The meta type of the user in the origin, such as "member", "guest", etc. See UserMetaType for the set of possible values.
            - `origin`: The type of source provider for the origin identifier (ex:AD, AAD, MSA)
            - `originId`: The unique identifier from the system of origin. Typically a sid, object id or Guid. Linking and unlinking operations can cause this value to change for a user because the user is not backed by a different provider and has a different unique id in the new provider.
            - `principalName`: This is the PrincipalName of this graph member from the source provider. The source provider may change this field over time and it is not guaranteed to be immutable for the life of the graph member by VSTS.
            - `subjectKind`: This field identifies the type of the graph subject (ex: Group, Scope, User).
            - `url`: This url is the full route to the source resource of this graph subject.

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
        Get-AdoUserEntitlements @params -UserId '585edf88-4dd5-4a21-b13b-5770d00ed858'

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
    }

    process {
        try {
            $organization = $CollectionUri.Split('/')[-1]
            $uri = if ($UserId) {
                "https://vsaex.dev.azure.com/$organization/_apis/userentitlements/$UserId"
            } else {
                "https://vsaex.dev.azure.com/$organization/_apis/userentitlements"
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
