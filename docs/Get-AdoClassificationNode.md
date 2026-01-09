<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/get
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/09/2026
PlatyPS schema version: 2024-05-01
title: Get-AdoClassificationNode
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoClassificationNode

## SYNOPSIS

Gets classification nodes for a project in Azure DevOps.

## SYNTAX

### __AllParameterSets

```text
Get-AdoClassificationNode [[-CollectionUri] <string>] [[-ProjectName] <string>] [[-StructureGroup] <string>] [[-Path] <string>] [[-Depth] <int>] [[-Version] <string>] [<CommonParameters>]
```

### ByNodesIds

```text
Get-AdoClassificationNode [[-CollectionUri] <string>] [[-ProjectName] <string>] -Ids <string[]> [[-ErrorPolicy] <string>] [[-Depth] <int>] [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet retrieves classification nodes for a specified project in Azure DevOps. You can retrieve the root node, specific nodes by path with optional depth control, or multiple nodes by their IDs.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri  = 'https://dev.azure.com/my-org'
    ProjectName    = 'my-project-1'
    StructureGroup = 'Areas'
}
Get-AdoClassificationNode @params
```

Retrieves the root area for the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri  = 'https://dev.azure.com/my-org'
    ProjectName    = 'my-project-1'
    StructureGroup = 'Areas'
    Path           = 'my-team-1/my-subarea-1'
    Depth          = 2
}
Get-AdoClassificationNode @params
```

Retrieves the area at the specified path with a depth of 2.

### EXAMPLE 3

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    Ids           = 1, 2, 3
    ErrorPolicy   = 'omit'
}
Get-AdoClassificationNode @params
```

Retrieves multiple classification nodes by their IDs, omitting any not found.

### EXAMPLE 4

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    Ids           = 1, 2, 3
    ErrorPolicy   = 'fail'
}
Get-AdoClassificationNode @params
```

Retrieves multiple classification nodes by their IDs, failing if any are not found.

### EXAMPLE 5

#### PowerShell

```powershell
$params = @{
    StructureGroup = 'Iterations'
    Path           = 'Sprint 1'
}
Get-AdoClassificationNode @params
```

Retrieves the iteration node at the specified path from the default project and collection.

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

Optional. The structure group of the classification node. Valid values are 'Areas' or 'Iterations'.
When not specified, all root classification nodes are returned.

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
AcceptedValues:
- Areas
- Iterations
HelpMessage: ''
```

### -Path

Optional. The path of the classification node to retrieve. If not specified, the root classification node is returned.

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

### -Ids

Optional. The unique identifiers of the classification nodes to retrieve.
Used with the 'ByNodesIds' parameter set to retrieve multiple nodes by their IDs.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByNodesIds
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ErrorPolicy

Optional. The error policy to apply when retrieving multiple nodes by IDs. Valid values are 'fail' and 'omit'.
When set to 'fail', the request fails if any of the specified IDs are not found.
When set to 'omit', nodes that are not found are omitted from the results.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByNodesIds
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- fail
- omit
HelpMessage: ''
```

### -Depth

Optional. The depth of the classification nodes to retrieve. If not specified, only the specified node is returned.

```yaml
Type: System.Int32
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

Returns classification node objects from Azure DevOps with the following properties:
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

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/get>
- <https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/get-root-nodes>
- <https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/get-classification-nodes>
