<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/get
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Remove-AdoTeam
-->

# Remove-AdoTeam

## SYNOPSIS

Remove a team from an Azure DevOps project.

## SYNTAX

### __AllParameterSets

```
Remove-AdoTeam [-ProjectId] <string> [-TeamId] <string> [[-ApiVersion] <string>]
 [<CommonParameters>]
```

## ALIASES

- N/A

## DESCRIPTION

This function removes a team from an Azure DevOps project through REST API.

## EXAMPLES

### EXAMPLE 1

Remove-AdoTeam -ProjectId 'my-project-001' -TeamId '00000000-0000-0000-0000-000000000000'

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
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ProjectId

Mandatory.
The ID or name of the project.

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

### -TeamId

Mandatory.
The ID or name of the team.

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

### System.Boolean

Boolean indicating success.

## NOTES

- N/A

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/delete>
