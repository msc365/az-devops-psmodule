<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/get?view=azure-devops
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/02/2026
PlatyPS schema version: 2024-05-01
title: Get-AdoProject
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoProject

## SYNOPSIS

Retrieves Azure DevOps project details.

## SYNTAX

### ListProjects (Default)

```text
Get-AdoProject [[-CollectionUri] <string>] [[-Skip] <int>] [[-Top] <int>]
 [[-ContinuationToken] <string>] [[-StateFilter] <string>] [[-Version] <string>] [<CommonParameters>]
```

### ByNameOrId

```text
Get-AdoProject [[-CollectionUri] <string>] [[-Name] <string[]>] [-IncludeCapabilities]
 [-IncludeHistory] [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- Id
- ProjectId
- ProjectName

## DESCRIPTION

This cmdlet retrieves details of one or more Azure DevOps projects within a specified organization.
You can retrieve all projects, a specific project by name or id, and control the amount of data returned using pagination parameters.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
}
Get-AdoProject @params -Top 5
```

Retrieves the first 5 projects from the specified organization.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
}
Get-AdoProject @params -Name 'my-project-1'
```

Retrieves the specified project by name.

### EXAMPLE 3

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
}
@('my-project-1', 'my-project-2') | Get-AdoProject @params -Verbose
```

Retrieves multiple projects by name demonstrating pipeline input.

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

### -Name

Optional.
The name or id of the project to retrieve. If not provided, retrieves all projects.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
- ProjectId
- ProjectName
ParameterSets:
- Name: ByNameOrId
  Position: Named
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeCapabilities

Optional.
Include capabilities (such as source control) in the team project result.
Default is 'false'.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByNameOrId
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeHistory

Optional.
Search within renamed projects (that had such name in the past).
Default is 'false'.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByNameOrId
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Skip

Optional.
The number of projects to skip. Used for pagination when retrieving all projects.

```yaml
Type: System.Int32
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListProjects
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
The number of projects to retrieve. Used for pagination when retrieving all projects.

```yaml
Type: System.Int32
DefaultValue: 100
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListProjects
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ContinuationToken

Optional.
An opaque data blob that allows the next page of data to resume immediately after where the previous page ended.
The only reliable way to know if there is more data left is the presence of a continuation token.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListProjects
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -StateFilter

Optional.
A filter for the project state. Possible values are 'deleting', 'new', 'wellFormed', 'createPending', 'all', 'unchanged', 'deleted'.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListProjects
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- deleting
- new
- wellFormed
- createPending
- all
- unchanged
- deleted
HelpMessage: ''
```

### -Version

The API version to use for the request.
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
AcceptedValues:
- 7.1
- 7.2-preview.4
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

Returns one or more project objects with the following properties:
- id: The unique identifier of the project
- name: The name of the project
- description: The description of the project
- visibility: The visibility of the project (public or private)
- state: The state of the project (wellFormed, createPending, deleted, etc.)
- defaultTeam: Information about the default team for the project
- capabilities: Project capabilities if IncludeCapabilities is specified (source control type, process template, etc.)
- collectionUri: The collection URI the project belongs to
- continuationToken: Token for retrieving next page of results (only present when listing projects with pagination)

## NOTES

- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/get>
- <https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/list>
