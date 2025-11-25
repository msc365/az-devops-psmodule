<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/feature-management/featurestatesquery
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Set-AdoFeatureState
-->

<!-- cSpell: ignore dontshow -->

# Set-AdoFeatureState

## SYNOPSIS

Set the feature state for an Azure DevOps project feature.

## SYNTAX

### __AllParameterSets

```text
Set-AdoFeatureState [-ProjectId] <string> [-Feature] <string> [[-FeatureState] <string>]
 [[-ApiVersion] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function sets the feature state for an Azure DevOps project feature through REST API.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Set-AdoFeatureState -ProjectId 'my-project-002' -Feature 'Boards' -FeatureState 'Disabled'
```

Sets the feature state for Boards to Disabled for the specified project.

## PARAMETERS

### -ApiVersion

Optional.
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
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Feature

Mandatory.
The feature to set the state for.
Valid values are 'Boards', 'Repos', 'Pipelines', 'TestPlans', 'Artifacts'.

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

### -FeatureState

Optional.
The state to set the feature to.
Default is 'Disabled'.

```yaml
Type: System.String
DefaultValue: disabled
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

Object representing the response from the Azure DevOps REST API.

## NOTES

- Turning off a feature hides this service for all members of this project.
  If you choose to enable this service later, all your existing data will be available.
- Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/feature-management/featurestatesquery>
