<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/create-or-update
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/09/2026
PlatyPS schema version: 2024-05-01
title: New-AdoClassificationNode
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# New-AdoClassificationNode

## SYNOPSIS

Creates a new classification node for a project in Azure DevOps.

## SYNTAX

### __AllParameterSets

```text
New-AdoClassificationNode [[-CollectionUri] <string>] [[-ProjectName] <string>] -StructureGroup <string> [[-Path] <string>] -Name <string> [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet creates a new classification node under a specified path for a project in Azure DevOps.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri  = 'https://dev.azure.com/my-org'
    ProjectName    = 'my-project-1'
    StructureGroup = 'Areas'
    Name           = 'my-team-1'
}
New-AdoClassificationNode @params
```

Creates a new area node named 'my-team-1' at the root level of the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri  = 'https://dev.azure.com/my-org'
    ProjectName    = 'my-project-1'
    StructureGroup = 'Areas'
    Path           = 'my-team-1'
    Name           = 'my-subarea-1'
}
New-AdoClassificationNode @params
```

Creates a new area node named 'my-subarea-1' under the existing area node 'my-team-1' in the specified project.

## PARAMETERS

### -CollectionUri

Optional. The collection URI of the Azure DevOps collection/organization, e.g., <https://dev.azure.com/my-org>.
Defaults to the value of the environment variable `$env:DefaultAdoCollectionUri`.

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

### -ProjectName

Optional. The ID or name of the Azure DevOps project.
Defaults to the value of the environment variable `$env:DefaultAdoProject`.

```yaml
Type: System.String
DefaultValue: $env:DefaultAdoProject
SupportsWildcards: false
Aliases:
- ProjectId
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

### -StructureGroup

Mandatory. The type of classification node to create. Valid values are 'Areas' or 'Iterations'.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- Areas
- Iterations
HelpMessage: ''
```

### -Path

Optional. The path under which to create the new classification node. If not specified, the node is created at the root level.

```yaml
Type: System.String
DefaultValue: ''
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

### -Name

Mandatory. The name of the new classification node to create.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
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

### -Version

Optional. The API version to use for the request. Default is '7.1'.

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
AcceptedValues:
- 7.1
- 7.2-preview.2
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

### PSCustomObject

Returns a classification node object representing the created node with the following properties:
- id: The integer ID of the classification node
- identifier: The GUID identifier of the classification node
- name: The name of the classification node
- structureType: The type of structure (area or iteration)
- path: The full path of the classification node
- hasChildren: Boolean indicating if the node has child nodes
- children: (Optional) Array of child classification nodes if present
- attributes: (Optional) Additional attributes like startDate and finishDate for iterations
- projectName: The name of the project
- collectionUri: The collection URI

## NOTES

- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.
- If a classification node with the same name already exists at the specified path, a warning is displayed and the operation is skipped.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/create-or-update>
