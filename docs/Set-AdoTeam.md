<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/update
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/02/2026
PlatyPS schema version: 2024-05-01
title: Set-AdoTeam
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Set-AdoTeam

## SYNOPSIS

Updates an existing Azure DevOps team.

## SYNTAX

### __AllParameterSets

```text
Set-AdoTeam [[-CollectionUri] <string>] [[-ProjectName] <string>] [-Id] <string>
 [[-Name] <string>] [[-Description] <string>] [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet updates an existing Azure DevOps team within a specified project. You can update the team name and/or description. Only properties that are explicitly provided will be updated.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    Id            = 'my-team'
    Name          = 'my-team-updated'
}
Set-AdoTeam @params -Verbose
```

Updates the name of the specified team.

### EXAMPLE 2

#### PowerShell

```powershell
[PSCustomObject]@{
    Id          = 'my-team'
    Name        = 'my-team-updated'
    Description = 'Updated description'
} | Set-AdoTeam -ProjectName 'my-project-1'
```

Updates the team using pipeline input.

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

### -Id

The ID or name of the team to update.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- TeamId
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

### -Name

The new name for the team.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- TeamName
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

### -Description

The new description for the team.

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
- PSCustomObject

## OUTPUTS

### PSCustomObject

Returns the updated team object with the following properties:
- id: The unique identifier of the team
- name: The updated name of the team
- description: The updated description of the team
- url: The REST API URL for the team
- identityUrl: The identity URL for the team
- projectId: The unique identifier of the project the team belongs to
- projectName: The name of the project the team belongs to
- collectionUri: The collection URI the team belongs to

## NOTES

- Only properties that are explicitly provided will be updated
- The Id parameter accepts either a team ID or team name
- Requires ShouldProcess confirmation due to ConfirmImpact = 'High'

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/update>
