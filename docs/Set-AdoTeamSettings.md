<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: ''
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/24/2025
PlatyPS schema version: 2024-05-01
title: Set-AdoTeamSettings
-->

# Set-AdoTeamSettings

## SYNOPSIS

Update the settings for a team in Azure DevOps.

## SYNTAX

### __AllParameterSets

```text
Set-AdoTeamSettings [-ProjectId] <string> [-TeamId] <string> [-TeamSettings] <Object>
 [[-ApiVersion] <string>] [<CommonParameters>]
```

## ALIASES

- N/A

## DESCRIPTION

Update the settings for a team in Azure DevOps by sending a PATCH request to the Azure DevOps REST API.

## EXAMPLES

### Example 1

#### PowerShell

```powershell
$params = @{
  bugsBehavior = 'asRequirements'
  backlogVisibilities = @{
    'Microsoft.EpicCategory' = $false
    'Microsoft.FeatureCategory' = $true
    'Microsoft.RequirementCategory' = $true
  }
  defaultIterationMacro = '@currentIteration'
  workingDays = @(
    'monday'
    'tuesday'
    'wednesday'
    'thursday'
    'friday'
  )
  backlogIteration = '00000000-0000-0000-0000-000000000000'
  }

  Set-AdoTeamSettings -ProjectId 'my-project' -TeamId 'my-other-team' -TeamSettings $params
```

Updates the settings for the team "my-other-team" in the project "my-project" with the specified parameters.

The backlogIteration is set to the root iteration, bugs are treated as requirements, and working days are set to Monday through Friday.

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

### -TeamSettings

An object representing the team settings to be updated.

```yaml
Type: System.Object
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

- N/A

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamsettings/update>

