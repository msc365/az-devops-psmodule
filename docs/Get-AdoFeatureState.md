<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/feature-management/featurestatesquery
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Get-AdoFeatureState
-->

<!-- cSpell: ignore dontshow -->

# Get-AdoFeatureState

## SYNOPSIS

Get the feature states for an Azure DevOps project.

## SYNTAX

### __AllParameterSets

```text
Get-AdoFeatureState [-ProjectId] <string> [[-ApiVersion] <string>] [<CommonParameters>]
```

## ALIASES

- N/A

## DESCRIPTION

This function retrieves the feature states for an Azure DevOps project through REST API.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Get-AdoFeatureState -ProjectName 'my-project-002'
```

## PARAMETERS

### -ApiVersion

The API version to use.
Default is '4.1-preview.1'.

```yaml
Type: System.String
DefaultValue: 4.1-preview.1
SupportsWildcards: false
Aliases:
- Api
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

An object representing the feature states.

## NOTES

- Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/feature-management/featurestatesquery>
