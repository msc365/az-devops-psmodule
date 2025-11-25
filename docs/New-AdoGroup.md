<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/create
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: New-AdoGroup
-->

<!-- cSpell: ignore dontshow -->

# New-AdoGroup

## SYNOPSIS

Adds an AAD Group as member of a group.

## SYNTAX

### __AllParameterSets

```text
New-AdoGroup [-GroupDescriptor] <string> [-GroupId] <string> [[-ApiVersion] <string>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function adds an AAD Group as member of a group in Azure DevOps through REST API.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
New-AdoGroupMembership -GroupDescriptor 'vssgp.00000000-0000-0000-0000-000000000000' -GroupId '00000000-0000-0000-0000-000000000000'
```

Adds an AAD Group as member of a group.

## PARAMETERS

### -ApiVersion

The API version to use.

```yaml
Type: System.String
DefaultValue: 7.1
SupportsWildcards: false
Aliases:
- Api
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -GroupDescriptor

A comma separated list of descriptors referencing groups you want the graph group to join.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Descriptor
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -GroupId

The OriginId of the entra group to add as a member.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- OriginId
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
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

- N/A

## OUTPUTS

### System.String

## NOTES

- Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/create>
