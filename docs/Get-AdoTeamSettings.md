<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: 
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/24/2025
PlatyPS schema version: 2024-05-01
title: Get-AdoTeamSettings
-->

<!-- cSpell: ignore dontshow -->

# Get-AdoTeamSettings

## SYNOPSIS

Gets the settings for a team in an Azure DevOps project.

## SYNTAX

### __AllParameterSets

```text
Get-AdoTeamSettings [-ProjectId] <string> [-TeamId] <string> [[-ApiVersion] <string>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

The Get-AdoTeamSettings cmdlet retrieves the settings for a specified team within an Azure DevOps project.

## EXAMPLES

### Example 1

#### PowerShell

```powershell
Get-AdoTeamSettings -ProjectId 'my-project-1' -TeamId 'my-team'
```

Retrieves the settings for the team "my-team" in the project "my-project".

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

### System.Object

The team details object.

## NOTES

- Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamsettings/get>

