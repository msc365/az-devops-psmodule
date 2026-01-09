<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamfieldvalues/update
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/09/2026
PlatyPS schema version: 2024-05-01
title: Set-AdoTeamFieldValue
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Set-AdoTeamFieldValue

## SYNOPSIS

Updates the team field value settings for a team in an Azure DevOps project.

## SYNTAX

### __AllParameterSets

```text
Set-AdoTeamFieldValue [[-CollectionUri] <string>] [[-ProjectName] <string>] [[-TeamName] <string>] [-DefaultValue] <string> [-Values] <hashtable[]> [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet updates the team field value settings for a specified team in an Azure DevOps project. Team field values define which work items belong to a team based on the Area Path field.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    DefaultValue  = 'my-project-1'
    Values        = @(
        @{
            value           = 'my-project-1\my-team-1'
            includeChildren = $false
        }
        @{
            value           = 'my-project-1\my-team-2'
            includeChildren = $false
        }
    )
}
Set-AdoTeamFieldValue @params
```

Updates the team field values for the default team in the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    TeamName      = 'my-team-1'
    DefaultValue  = 'my-project-1\my-team-1'
    Values        = @(
        @{
            value           = 'my-project-1\my-team-1'
            includeChildren = $false
        }
    )
}
Set-AdoTeamFieldValue @params
```

Updates the team field value for team 'my-team-1' in the specified project.

### EXAMPLE 3

#### PowerShell

```powershell
$params = @{
    TeamName     = 'my-team-1'
    DefaultValue = 'my-project-1'
    Values       = @(
        @{
            value           = 'my-project-1'
            includeChildren = $true
        }
    )
}
Set-AdoTeamFieldValue @params
```

Updates the team field values for team 'my-team-1' where sub-areas are included.

## PARAMETERS

### -CollectionUri

The collection URI of the Azure DevOps collection/organization, e.g., <https://dev.azure.com/my-org>.
If not specified, the default collection URI from the environment variable `$env:DefaultAdoCollectionUri` is used.

```yaml
Type: System.String
DefaultValue: $env:DefaultAdoCollectionUri
SupportsWildcards: false
Aliases:
- N/A
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
If not specified, the default project from the environment variable `$env:DefaultAdoProject` is used.

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

The ID or name of the team within the project.
If not specified, the default team is used.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- TeamId
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

### -DefaultValue

The default team field value for the team.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- N/A
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

### -Values

An array of team field values to set for the team.
Each value should have a 'value' property (string) and 'includeChildren' property (boolean).

```yaml
Type: System.Collections.Hashtable[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- N/A
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

### -Version

The API version to use for the request.

```yaml
Type: System.String
DefaultValue: '7.1'
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

The updated team field value settings for the specified team with the following properties:
- defaultValue: The default area path value for the team
- field: Object containing the field reference name and URL
- values: Array of area path values with includeChildren settings
- projectName: The project name used in the request
- collectionUri: The collection URI used in the request

## NOTES

- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.

- This cmdlet supports `-WhatIf` and `-Confirm` parameters for safe execution.
- Each value in the Values parameter must contain both 'value' (string) and 'includeChildren' (boolean) properties.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamfieldvalues/update>
