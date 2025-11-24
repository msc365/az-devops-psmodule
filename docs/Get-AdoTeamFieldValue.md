<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamfieldvalues/get
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Get-AdoTeamFieldValue
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoTeamFieldValue

## SYNOPSIS

Gets the team field value settings for a team in an Azure DevOps project.

## SYNTAX

### __AllParameterSets

```text
Get-AdoTeamFieldValue [-ProjectId] <string> [[-TeamId] <string>] [[-ApiVersion] <string>]
 [<CommonParameters>]
```

## ALIASES

- N/A

## DESCRIPTION

This function retrieves the team field value settings for a specified team in an Azure DevOps project using the REST API.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Get-AdoTeamFieldValue -ProjectId 'e2egov-fantastic-four
```

This example retrieves the team field values for the default team in the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
Get-AdoTeamFieldValue -ProjectId 'e2egov-fantastic-four' -TeamId 'Mister Fantastic'
```

This example retrieves the team field values for the specified team in the specified project.

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
The ID or name of the Azure DevOps project.

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

Optional.
The ID or name of the team within the project.
If not specified, the default team is used.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
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

## OUTPUTS

### System.Object

The team field value settings for the specified team.

## NOTES

- Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamfieldvalues/get>
