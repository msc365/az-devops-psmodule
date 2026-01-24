<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/create
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/04/2026
PlatyPS schema version: 2024-05-01
title: Add-AdoGroupMember
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Add-AdoGroupMember

## SYNOPSIS

Adds an Entra ID group as member of a group.

## SYNTAX

### __AllParameterSets

```text
Add-AdoGroupMember [[-CollectionUri] <string>] [-GroupDescriptor] <string> [-OriginId] <string> [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet adds an Entra ID group as member of a group in Azure DevOps. It uses the Azure DevOps Graph API to create the membership relationship by specifying the group descriptor of the parent group and the Origin ID of the Entra ID group to be added as a member.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri   = 'https://vssps.dev.azure.com/my-org'
    GroupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
    OriginId        = '00000000-0000-0000-0000-000000000001'
}
Add-AdoGroupMember @params
```

Adds an Entra ID group as member of a group using the specified collection URI, group descriptor, and origin ID.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri   = 'https://vssps.dev.azure.com/my-org'
    GroupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
}
@(
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002'
) | Add-AdoGroupMember @params
```

Adds multiple Entra ID groups as members demonstrating pipeline input. The Origin IDs are piped to the cmdlet.

## PARAMETERS

### -CollectionUri

The collection URI of the Azure DevOps collection/organization.
The URI should be in the format: <https://vssps.dev.azure.com/my-org>.
If not provided, the default collection URI from the environment variable `$env:DefaultAdoCollectionUri` is used (with https:// replaced by <https://vssps>.).

```yaml
Type: System.String
DefaultValue: $env:DefaultAdoCollectionUri
SupportsWildcards: false
Aliases:
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
HelpMessage: ''
```

### -GroupDescriptor

The descriptor of the group to which the member will be added.
This is the unique identifier for the Azure DevOps group that will contain the new member.

```yaml
Type: System.String
DefaultValue: 
SupportsWildcards: false
Aliases:
- Descriptor
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
HelpMessage: ''
```

### -OriginId

The Origin ID of the Entra ID group to add as a member.
This is the unique identifier from Entra ID (formerly Azure Active Directory) that identifies the group to be added.

```yaml
Type: System.String
DefaultValue: 
SupportsWildcards: false
Aliases:
- Id
- GroupId
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
HelpMessage: ''
```

### -Version

The API version to use for the request.
The -preview flag must be supplied in the api-version for this request to work.

```yaml
Type: System.String
DefaultValue: 7.2-preview.1
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
AcceptedValues:
- 7.1-preview.1
- 7.2-preview.1
HelpMessage: The -preview flag must be supplied in the api-version for this request to work.
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

- System.String - The Origin ID can be piped to this cmdlet

## OUTPUTS

### PSCustomObject

Returns a custom object with the following properties:
- displayName: The display name of the group that was added
- originId: The Origin ID of the Entra ID group
- principalName: The principal name of the group
- origin: The origin source of the group
- subjectKind: The kind of subject (e.g., group)
- descriptor: The descriptor of the group that was created/added
- collectionUri: The collection URI where the operation was performed

## NOTES

- This cmdlet has a high confirm impact and will prompt for confirmation by default
- Handles errors gracefully with specific warnings for common issues (missing originId, invalid descriptor)
- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/create>
