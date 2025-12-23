<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: ''
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 12/05/2025
PlatyPS schema version: 2024-05-01
title: New-AdoEnvironment
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# New-AdoEnvironment

## SYNOPSIS

Create a new Azure DevOps Pipeline Environment.

## SYNTAX

### __AllParameterSets

```text
New-AdoEnvironment [-ProjectId] <string> [[-Name] <string>] [[-Description] <string>]
 [[-ApiVersion] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet creates a new Azure DevOps Pipeline Environment within a specified project.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Set-AdoEnvironment -ProjectId "MyProject" -EnvironmentId "42" -Name "NewEnvName" -Description "Updated description"
```

Updates the environment with ID 42 in the project "MyProject" to have a new name and description.

## PARAMETERS

### -ApiVersion

Optional.
The API version to use for the request.
Default is '7.2-preview.1'.

```yaml
Type: System.String
DefaultValue: 7.2-preview.1
SupportsWildcards: false
Aliases:
- api
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

### -Description

Optional.
The new description for the environment.

```yaml
Type: System.String
DefaultValue: ''
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

### -Name

Mandatory.
The name for the environment.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

- N/A

## OUTPUTS

### System.Object

## NOTES

- Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/environments/environments/add>
