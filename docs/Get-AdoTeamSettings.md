<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamsettings/get
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/07/2026
PlatyPS schema version: 2024-05-01
title: Get-AdoTeamSettings
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoTeamSettings

## SYNOPSIS

Retrieves the settings for a team in an Azure DevOps project.

## SYNTAX

### __AllParameterSets

```text
Get-AdoTeamSettings [[-CollectionUri] <string>] [[-ProjectName] <string>] [-Name] <string> [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet retrieves the settings for a specified team within an Azure DevOps project,
including working days, backlog iteration, bugs behavior, and backlog visibilities.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
}
Get-AdoTeamSettings @params -Name 'my-team-1'
```

Retrieves the settings for the team "my-team-1" in the project "my-project-1".

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
}
'my-team-1' | Get-AdoTeamSettings @params
```

Retrieves the team settings using pipeline input.

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

Mandatory.
The ID or name of the team to retrieve settings for.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Team
- TeamId
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
- Name: (All)
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

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamsettings/get>

