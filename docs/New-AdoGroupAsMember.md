<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/create
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/02/2026
PlatyPS schema version: 2024-05-01
title: New-AdoGroupAsMember
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# New-AdoGroupAsMember

## SYNOPSIS

Adds an AAD Group as member of a group.

## SYNTAX

### __AllParameterSets

```text
New-AdoGroupAsMember [[-CollectionUri] <string>] -GroupDescriptor <string> -OriginId <string>
 [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet adds an AAD Group as member of a group in Azure DevOps. It creates a new group membership by linking an Azure Active Directory (AAD) group to an existing Azure DevOps group using the origin ID and group descriptor.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri   = 'https://vssps.dev.azure.com/my-org'
    GroupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
    OriginId        = '00000000-0000-0000-0000-000000000001'
}
New-AdoGroupAsMember @params
```

Adds an AAD Group as member of a group.

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
) | New-AdoGroupAsMember @params
```

Adds multiple AAD Groups as members demonstrating pipeline input.

## PARAMETERS

### -CollectionUri

Optional.
The collection URI of the Azure DevOps collection/organization, e.g., <https://vssps.dev.azure.com/my-org>.
Defaults to the value of $env:DefaultAdoCollectionUri with the scheme replaced to use vssps subdomain.

```yaml
Type: System.String
DefaultValue: ($env:DefaultAdoCollectionUri -replace 'https://', 'https://vssps.')
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

### -GroupDescriptor

Mandatory.
A comma separated list of descriptors referencing groups you want the graph group to join.
This is the descriptor of the target Azure DevOps group that will receive the new member.

```yaml
Type: System.String
DefaultValue: ''
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
AcceptedValues: []
HelpMessage: ''
```

### -OriginId

Mandatory.
The OriginId of the Entra (Azure AD) group to add as a member.
This is the unique identifier of the AAD group in the backing directory.

```yaml
Type: System.String
DefaultValue: ''
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
AcceptedValues: []
HelpMessage: ''
```

### -Version

Optional.
The API version to use for the request.
Default is '7.2-preview.1'.
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

- System.String - Accepts OriginId via pipeline

## OUTPUTS

### PSCustomObject

Returns a group object representing the newly added member with the following properties:
- displayName: The display name of the group
- originId: The origin ID of the group
- principalName: The principal name of the group
- origin: The origin of the group (e.g., 'aad')
- subjectKind: The subject kind (typically 'group')
- descriptor: The descriptor of the newly added group member
- collectionUri: The collection URI used for the operation

## NOTES

- This cmdlet has a high confirm impact and will prompt for confirmation by default
- Handles errors gracefully with specific warnings for common issues (missing originId, invalid descriptor)
- Requires an active Azure account login. Use `Connect-AzAccount` to authenticate:

  ```powershell
  Connect-AzAccount -Tenant '<tenant-id>' -Subscription '<subscription-id>'
  ```

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/create>
