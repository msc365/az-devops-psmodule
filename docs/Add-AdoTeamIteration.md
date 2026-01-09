<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/work/iterations/post-team-iteration
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/07/2026
PlatyPS schema version: 2024-05-01
title: Add-AdoTeamIteration
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Add-AdoTeamIteration

## SYNOPSIS

Adds an iteration to a team in Azure DevOps.

## SYNTAX

### __AllParameterSets

```text
Add-AdoTeamIteration [[-CollectionUri] <string>] [[-ProjectName] <string>] [-TeamName] <string> [-Id] <string> [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet adds a specific iteration to a team for a specified project in Azure DevOps. The iteration must already exist in the project's classification nodes before it can be added to a team.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName = 'my-project'
    TeamName = 'my-team'
    Id = '00000000-0000-0000-0000-000000000000'
}
Add-AdoTeamIteration @params
```

Adds the specified iteration to the team.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    ProjectName = 'my-project'
    TeamName = 'my-team'
    Id = '00000000-0000-0000-0000-000000000000'
}
Add-AdoTeamIteration @params
```

Adds the iteration using the default CollectionUri from the environment variable.

## PARAMETERS

### -CollectionUri

The collection URI of the Azure DevOps collection/organization, e.g., <https://dev.azure.com/my-org>.
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

### -TeamName

The ID or name of the team to add the iteration to.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Team
- TeamId
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Id

The ID of the iteration to add to the team. The iteration must already exist in the project's classification nodes.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- IterationId
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

The API version to use for the request.

```yaml
Type: System.String
DefaultValue: '7.1'
SupportsWildcards: false
Aliases:
- api
- ApiVersion
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- '7.1'
- '7.2-preview.1'
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

The cmdlet returns a PSCustomObject with the following properties:
- id: The unique identifier of the iteration
- name: The name of the iteration
- attributes: The iteration attributes including start date, finish date, and time frame
- team: The id or name of the team the iteration was added to
- project: The id or name of the project
- collectionUri: The collection URI

## NOTES

- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.

- The iteration must already exist in the project's classification nodes before it can be added to a team.
- If the iteration does not exist, a warning will be issued and the cmdlet will continue without error.
- This cmdlet supports -WhatIf and -Confirm parameters for testing changes before execution.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/work/iterations/post-team-iteration>
