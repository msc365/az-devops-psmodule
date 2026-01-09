<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/work/iterations/get
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/07/2026
PlatyPS schema version: 2024-05-01
title: Get-AdoTeamIteration
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoTeamIteration

## SYNOPSIS

Retrieves Azure DevOps team iteration details.

## SYNTAX

### ListIterations

```text
Get-AdoTeamIteration [[-CollectionUri] <string>] [[-ProjectName] <string>] [-TeamName] <string> [[-TimeFrame] <string>] [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ById

```text
Get-AdoTeamIteration [[-CollectionUri] <string>] [[-ProjectName] <string>] [-TeamName] <string> [[-Id] <string>] [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet retrieves details of one or more Azure DevOps team iterations within a specified project and team. You can retrieve all iterations, filter by timeframe, or retrieve specific iterations by ID.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName = 'my-project'
    TeamName = 'my-team'
}
Get-AdoTeamIteration @params
```

Retrieves all iterations for the specified team.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName = 'my-project'
    TeamName = 'my-team'
    TimeFrame = 'current'
}
Get-AdoTeamIteration @params
```

Retrieves current iterations for the specified team.

### EXAMPLE 3

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName = 'my-project'
    TeamName = 'my-team'
    Id = '00000000-0000-0000-0000-000000000000'
}
Get-AdoTeamIteration @params
```

Retrieves the specified iteration by ID.

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

The ID or name of the team.

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
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Id

The ID of the iteration(s) to retrieve. If not provided, retrieves all iterations.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- IterationId
ParameterSets:
- Name: ById
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -TimeFrame

The timeframe to filter iterations. Valid values are 'past', 'current', and 'future'.
Note: Only 'current' is fully supported by the Azure DevOps API currently.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListIterations
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- past
- current
- future
HelpMessage: Only 'current' is supported currently.
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
- team: The id or name of the team
- project: The id or name of the project
- collectionUri: The collection URI

## NOTES

- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.

- If a specific iteration ID is not found, a warning will be issued and the cmdlet will continue without error.
- This cmdlet supports -WhatIf and -Confirm parameters for testing queries before execution.
- The TimeFrame parameter currently only fully supports 'current' timeframe filtering.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/work/iterations/get>
- <https://learn.microsoft.com/en-us/rest/api/azure/devops/work/iterations/list>

