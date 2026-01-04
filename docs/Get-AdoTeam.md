<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/get
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/02/2026
PlatyPS schema version: 2024-05-01
title: Get-AdoTeam
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoTeam

## SYNOPSIS

Retrieves Azure DevOps team details.

## SYNTAX

### ListTeams (Default)

```text
Get-AdoTeam [[-CollectionUri] <string>] [[-ProjectName] <string>] [[-Skip] <int>]
 [[-Top] <int>] [[-Version] <string>] [<CommonParameters>]
```

### ByNameOrId

```text
Get-AdoTeam [[-CollectionUri] <string>] [[-ProjectName] <string>] [[-Name] <string>]
 [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet retrieves details of one or more Azure DevOps teams within a given project. You can retrieve all teams in a project, or specific teams by name or ID. Supports pagination when retrieving all teams.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
}
Get-AdoTeam @params
```

Retrieves all teams from the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
Get-AdoTeam -Name 'my-team'
```

Retrieves the specified team using default CollectionUri and ProjectName from environment variables.

### EXAMPLE 3

#### PowerShell

```powershell
'team-1' | Get-AdoTeam -ProjectName 'my-project-1'
```

Retrieves a team demonstrating pipeline input.

## PARAMETERS

### -CollectionUri

The collection URI of the Azure DevOps collection/organization.
Defaults to the value of $env:DefaultAdoCollectionUri if not provided.

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

The ID or name of the project.
Defaults to the value of $env:DefaultAdoProject if not provided.

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

### -Name

The ID or name of the team to retrieve.
If not provided, retrieves all teams.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- TeamName
- Id
- TeamId
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

### -Skip

The number of teams to skip.
Used for pagination when retrieving all teams.

```yaml
Type: System.Int32
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListTeams
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

The number of teams to retrieve.
Used for pagination when retrieving all teams.

```yaml
Type: System.Int32
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListTeams
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
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
- 7.2-preview.3
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

- System.String

## OUTPUTS

### PSCustomObject

Returns one or more team objects with the following properties:
- id: The unique identifier of the team
- name: The name of the team
- description: The description of the team
- url: The REST API URL for the team
- identityUrl: The identity URL for the team
- projectId: The unique identifier of the project the team belongs to
- projectName: The name of the project the team belongs to
- collectionUri: The collection URI the team belongs to

## NOTES

- Both CollectionUri and ProjectName parameters can be set as environment variables ($env:DefaultAdoCollectionUri and $env:DefaultAdoProject) to avoid specifying them in each call

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/get>
