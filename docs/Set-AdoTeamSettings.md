<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamsettings/update
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/07/2026
PlatyPS schema version: 2024-05-01
title: Set-AdoTeamSettings
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Set-AdoTeamSettings

## SYNOPSIS

Updates the settings for a team in Azure DevOps.

## SYNTAX

### DefaultIterationMacro

```text
Set-AdoTeamSettings [[-CollectionUri] <string>] [[-ProjectName] <string>] [-Name] <string>
 [[-BacklogIteration] <string>] [[-BacklogVisibilities] <object>] [[-BugsBehavior] <string>]
 [[-DefaultIterationMacro] <string>] [[-WorkingDays] <string[]>] [[-Version] <string>] [<CommonParameters>]
```

### DefaultIteration

```text
Set-AdoTeamSettings [[-CollectionUri] <string>] [[-ProjectName] <string>] [-Name] <string>
 [[-BacklogIteration] <string>] [[-BacklogVisibilities] <object>] [[-BugsBehavior] <string>]
 [[-DefaultIteration] <string>] [[-WorkingDays] <string[]>] [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet updates the settings for a team in Azure DevOps by sending a PATCH request to the Azure DevOps REST API.
You can update working days, bugs behavior, backlog iteration, and backlog visibilities.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    Name          = 'my-team-1'
    BugsBehavior  = 'asRequirements'
    WorkingDays   = @('monday', 'tuesday', 'wednesday', 'thursday', 'friday')
}
Set-AdoTeamSettings @params
```

Updates the team settings to treat bugs as requirements and set working days.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri        = 'https://dev.azure.com/my-org'
    ProjectName          = 'my-project-1'
    Name                 = 'my-team-1'
    BacklogVisibilities  = @{
        'Microsoft.EpicCategory'        = $false
        'Microsoft.FeatureCategory'     = $true
        'Microsoft.RequirementCategory' = $true
    }
}
Set-AdoTeamSettings @params
```

Updates the backlog visibilities for the team.

### EXAMPLE 3

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    BugsBehavior  = 'asRequirements'
    WorkingDays   = @('monday', 'tuesday', 'wednesday')
}
@(
    'my-team-1',
    'my-team-2'
) | Set-AdoTeamSettings @params
```

Updates multiple teams to treat bugs as requirements and set working days using pipeline input.

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
- Name: DefaultIterationMacro
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: DefaultIteration
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

Optional.
The ID or name of the project.
If not specified, the default project is used.

```yaml
Type: System.String
DefaultValue: $env:DefaultAdoProject
SupportsWildcards: false
Aliases:
- ProjectId
ParameterSets:
- Name: DefaultIterationMacro
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: DefaultIteration
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

Mandatory.
The ID or name of the team to update settings for.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Team
- TeamId
- TeamName
ParameterSets:
- Name: DefaultIterationMacro
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: DefaultIteration
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -BacklogIteration

Optional.
The id (uuid) of the iteration to use as the backlog iteration.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: DefaultIterationMacro
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: DefaultIteration
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -BacklogVisibilities

Optional.
Object with backlog level visibilities (e.g., @{'Microsoft.EpicCategory' = $true}).

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: DefaultIterationMacro
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: DefaultIteration
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -BugsBehavior

Optional.
How bugs should behave.
Valid values: 'off', 'asRequirements', 'asTasks'.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: DefaultIterationMacro
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: DefaultIteration
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- off
- asRequirements
- asTasks
HelpMessage: ''
```

### -DefaultIteration

Optional.
The default iteration id (uuid) for the team.
Cannot be used together with DefaultIterationMacro.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: DefaultIteration
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -DefaultIterationMacro

Optional.
Default iteration macro (e.g., '@currentIteration').
Used to set the default iteration dynamically.
Cannot be used together with DefaultIteration.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: DefaultIterationMacro
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WorkingDays

Optional.
Array of working days for the team (e.g., 'monday', 'tuesday', 'wednesday').

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: DefaultIterationMacro
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: DefaultIteration
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- sunday
- monday
- tuesday
- wednesday
- thursday
- friday
- saturday
HelpMessage: ''
```

### -Version

Optional.
The API version to use for the request.
Default is '7.1'.

```yaml
Type: System.String
DefaultValue: 7.1
SupportsWildcards: false
Aliases:
- ApiVersion
ParameterSets:
- Name: DefaultIterationMacro
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: DefaultIteration
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- 7.1
- 7.2-preview.1
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

Returns a team settings object containing:
- backlogIteration: The backlog iteration configuration
- backlogVisibilities: Hashtable of backlog level visibilities (Epic, Feature, Requirement categories)
- bugsBehavior: How bugs are treated ('off', 'asRequirements', or 'asTasks')
- defaultIteration: The default iteration configuration
- defaultIterationMacro: Default iteration macro (e.g., '@currentIteration')
- workingDays: Array of working days for the team
- url: API URL for the team settings
- projectName: The name of the project
- collectionUri: The collection URI

## NOTES

- Requires an active Azure account login. Use `Connect-AzAccount` to authenticate:

  ```powershell
  Connect-AzAccount -Tenant '<tenant-id>' -Subscription '<subscription-id>'
  ```

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamsettings/update>

