<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/create
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/02/2026
PlatyPS schema version: 2024-05-01
title: New-AdoTeam
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# New-AdoTeam

## SYNOPSIS

Creates a new team in an Azure DevOps project.

## SYNTAX

### __AllParameterSets

```text
New-AdoTeam [[-CollectionUri] <string>] [[-ProjectName] <string>] [-Name] <string>
 [[-Description] <string>] [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet creates a new Azure DevOps team within a specified project. If a team with the same name already exists, it will return the existing team instead of throwing an error.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    Name          = 'my-team'
}
New-AdoTeam @params -Verbose
```

Creates a new team in the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
@('team-1', 'team-2') | New-AdoTeam -ProjectName 'my-project-1' -Description 'Development teams'
```

Creates multiple teams demonstrating pipeline input.

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

The name of the team to create.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- TeamName
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

### -Description

The description of the team.

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

Returns a team object with the following properties:
- id: The unique identifier of the created team
- name: The name of the team
- description: The description of the team
- url: The REST API URL for the team
- identityUrl: The identity URL for the team
- projectId: The unique identifier of the project the team belongs to
- projectName: The name of the project the team belongs to
- collectionUri: The collection URI the team belongs to

## NOTES

- The team name must be unique within the project
- If a team with the same name already exists, the cmdlet returns the existing team instead of throwing an error
- Requires ShouldProcess confirmation due to ConfirmImpact = 'High'

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/create>
