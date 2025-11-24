<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/create
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: New-AdoProject
-->

<!-- cSpell: ignore dontshow -->

# New-AdoProject

## SYNOPSIS

Create a new project in an Azure DevOps organization.

## SYNTAX

### __AllParameterSets

```text
New-AdoProject [-Name] <string> [[-Description] <string>] [[-Process] <string>]
 [[-SourceControl] <string>] [[-Visibility] <string>] [[-ApiVersion] <string>] [<CommonParameters>]
```

## ALIASES

- N/A

## DESCRIPTION

This function creates a new project in an Azure DevOps organization through REST API.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
New-AdoProject -Name 'my-project-002' -Description 'My new project'
```

Creates a new project named 'my-project-002' with the description 'My new project'.

## PARAMETERS

### -ApiVersion

Optional.
The API version to use.
Default is '7.1'.

```yaml
Type: System.String
DefaultValue: 7.1
SupportsWildcards: false
Aliases:
- Api
ParameterSets:
- Name: (All)
  Position: 5
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Description

Optional.
The description of the project.

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

### -Name

Mandatory.
The name of the project to create.

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

### -Process

Optional.
The process to use for the project.
Default is 'Agile'.

```yaml
Type: System.String
DefaultValue: Agile
SupportsWildcards: false
Aliases: []
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

### -SourceControl

Optional.
The source control type to use for the project.
Default is 'Git'.

```yaml
Type: System.String
DefaultValue: Git
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Visibility

Optional.
The visibility of the project.
Default is 'Private'.

```yaml
Type: System.String
DefaultValue: Private
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 4
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

- N/A

## OUTPUTS

### System.Object

An object representing the created project.

## NOTES

- Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/create>
