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

```text
Get-AdoUserEntitlement [-CollectionUri <string>] [-Filter <string>] [-Select <string>] [-Skip <int>]
 [-Top <int>] [-Version <string>] [<CommonParameters>]
```

### GetUserEntitlement

```text
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

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
}
Get-AdoUserEntitlement @params -Top 5
```

Retrieves the first 5 users from the specified organization.

### EXAMPLE 2

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
}
Get-AdoUserEntitlement @params -UserId '585edf88-4dd5-4a21-b13b-5770d00ed858'
```

Retrieves the specified user by Id.

## PARAMETERS

### -CollectionUri

Optional.
The collection URI of the Azure DevOps collection/organization, e.g., <https://dev.azure.com/my-org>.

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

### PSCustomObject

The dictionary contains user entitlements:
- `accessLevel`: User's access level denoted by a license.
- `extensions`: User's extensions.
- `groupAssigments`: [Readonly] GroupEntitlements that this user belongs to.
- `id`: The unique identifier which matches the Id of the Identity associated with the GraphMember.
- `lastAccessedDate`: [Readonly] Date the user last accessed the collection.
- `projectEntitlements`: Relation between a project and the user's effective permissions in that project.
- `user`: User reference.
- `collectionUri`: The collection URI.

## NOTES

- N/A

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/memberentitlementmanagement/user-entitlements/get>
- <https://learn.microsoft.com/en-us/rest/api/azure/devops/memberentitlementmanagement/user-entitlements/search-user-entitlements>
