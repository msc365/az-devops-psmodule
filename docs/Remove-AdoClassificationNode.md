<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/delete
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Remove-AdoClassificationNode
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Remove-AdoClassificationNode

## SYNOPSIS

Removes a classification node from a project in Azure DevOps.

## SYNTAX

### __AllParameterSets

```text
Remove-AdoClassificationNode [-ProjectId] <string> [-StructureType] <string> [-Path] <string>
 [[-ReclassifyId] <int>] [[-ApiVersion] <string>] [<CommonParameters>]
```

## ALIASES

- N/A

## DESCRIPTION

This function removes a classification node from a specified project in Azure DevOps using the REST API.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Remove-AdoClassificationNode -ProjectId 'my-project' -Path 'Area/SubArea'
```

This example removes the area node at the specified path from the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
Remove-AdoClassificationNode -ProjectId 'my-project' -Path 'Area'
```

This example removes the area node named 'Area' from the specified project including its 'SubArea' child node.

### EXAMPLE 3

#### PowerShell

```powershell
Remove-AdoClassificationNode -ProjectId 'my-project' -Path 'Area/SubArea' -ReclassifyId 658
```

This example removes the area node at the specified path and reassigns (reclassifies) the work items that were associated with that node to another existing node, the node with ID 658.

> [!NOTE] Note  
> Without `-ReclassifyId`, deleting a node could leave work items orphaned or unclassified.  
> This parameter ensures a smooth transition by automatically moving them to a valid node.

## PARAMETERS

### -ApiVersion

Optional.
The API version to use.

```yaml
Type: System.String
DefaultValue: 7.1
SupportsWildcards: false
Aliases:
- api
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Path

Required.
The path of the classification node to remove.
The root classification node cannot be removed.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ProjectId

Mandatory.
The ID or name of the Azure DevOps project.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
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

### -ReclassifyId

Optional.
The ID of the target classification node for reclassification.
If not provided, child nodes will be deleted.

```yaml
Type: System.Int32
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -StructureType

Mandatory.
The type of the classification node structure (Areas or Iterations).

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
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

- N/A

## NOTES

- Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/delete>
