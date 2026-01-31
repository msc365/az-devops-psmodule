<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: >-
  https://learn.microsoft.com/en-us/rest/api/azure/devops/memberentitlementmanagement/user-entitlements/get

  https://learn.microsoft.com/en-us/rest/api/azure/devops/memberentitlementmanagement/user-entitlements/list
Locale: nl-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01-31-2026
PlatyPS schema version: 2024-05-01
title: Get-AdoUserEntitlement
-->

# Get-AdoUserEntitlement

## SYNOPSIS

Get a paged set of user entitlements matching the filter criteria. If no filter is is passed, a page from all the
account users is returned.

## SYNTAX

### ListUserEntitlements (Default)

```
Get-AdoUserEntitlement [-CollectionUri <string>] [-Filter <string>] [-Select <string>] [-Skip <int>]
 [-Top <int>] [-ContinuationToken <string>] [-Version <string>] [<CommonParameters>]
```

### GetUserEntitlement

```
Get-AdoUserEntitlement [-CollectionUri <string>] [-UserId <string>] [-Version <string>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet get a paged set of user entitlements matching the filter criteria.
If no filter is is passed, a page from all the account users is returned.

## EXAMPLES

### EXAMPLE 1

$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
}
Get-AdoUserEntitlements @params -Top 5

Retrieves the first 5 users from the specified organization.

### EXAMPLE 2

$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
}
Get-AdoUserEntitlements @params -UserId '585edf88-4dd5-4a21-b13b-5770d00ed858'

Retrieves the specified user by Id.

## PARAMETERS

### -CollectionUri

Optional.
The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

```yaml
Type: System.String
DefaultValue: $env:DefaultAdoCollectionUri
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ContinuationToken

Optional.
An opaque blob used to fetch the next page.
If omitted, the cmdlet will automatically continue until all pages are returned.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListUserEntitlements
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Filter

Optional.
Comma (",") separated list of properties and their values to filter on.
Currently, the API only supports
filtering by ExtensionId.
An example parameter would be filter=extensionId eq search.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListUserEntitlements
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Select

Optional.
Comma (",") separated list of properties to select in the result entitlements.
names of the properties are
 - 'Projects, 'Extensions' and 'Grouprules'.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListUserEntitlements
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Skip

Optional.
Offset: Number of records to skip.
Default value is 0

```yaml
Type: System.Int32
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListUserEntitlements
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Top

Optional.
Maximum number of the user entitlements to return.
Max value is 10000.
Default value is 100

```yaml
Type: System.Int32
DefaultValue: 100
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListUserEntitlements
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -UserId

Optional.
ID of the user.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
ParameterSets:
- Name: GetUserEntitlement
  Position: Named
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Version

Optional.
Version of the API to use.
Default is '7.1'.

```yaml
Type: System.String
DefaultValue: 7.1
SupportsWildcards: false
Aliases:
- ApiVersion
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

- N/A

## OUTPUTS

### System.Collections.Specialized.OrderedDictionary

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

## NOTES

- N/A

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/memberentitlementmanagement/user-entitlements/get>
- <https://learn.microsoft.com/en-us/rest/api/azure/devops/memberentitlementmanagement/user-entitlements/list>
