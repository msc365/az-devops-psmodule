<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/feature-management/featurestatesquery
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/02/2026
PlatyPS schema version: 2024-05-01
title: Set-AdoFeatureState
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Set-AdoFeatureState

## SYNOPSIS

Set the feature state for an Azure DevOps project feature.

## SYNTAX

### __AllParameterSets

```text
Set-AdoFeatureState [[-CollectionUri] <string>] [[-ProjectName] <string>] [-Feature] <string>
 [[-FeatureState] <string>] [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- ProjectId

## DESCRIPTION

This cmdlet sets the feature state for an Azure DevOps project feature through REST API.
Controls whether features like Boards, Repos, Pipelines, Test Plans, and Artifacts are enabled or disabled.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-002'
    Feature       = 'Boards'
    FeatureState  = 'Disabled'
}
Set-AdoFeatureState @params
```

Sets the feature state for Boards to Disabled for the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
Set-AdoFeatureState -ProjectName 'my-project-002' -Feature 'Repos' -FeatureState 'Enabled'
```

Enables the Repos feature for the specified project using the default collection URI.

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
Defaults to the value of $env:DefaultAdoProject.

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

### -Feature

Mandatory.
The feature to set the state for.
Valid values are 'boards', 'repos', 'pipelines', 'testPlans', 'artifacts'.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- boards
- repos
- pipelines
- testPlans
- artifacts
HelpMessage: ''
```

### -FeatureState

Optional.
The state to set the feature to.
Valid values are 'enabled' or 'disabled'.
Default is 'disabled'.

```yaml
Type: System.String
DefaultValue: disabled
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
AcceptedValues:
- enabled
- disabled
HelpMessage: ''
```

### -Version

Optional.
The API version to use.
Default is '4.1-preview.1'.

```yaml
Type: System.String
DefaultValue: 4.1-preview.1
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
- 4.1-preview.1
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

Returns a custom object with the following properties:
- featureId: The unique identifier for the feature
- state: The state as text ('enabled' or 'disabled')
- feature: The feature name that was updated
- projectName: The name of the project
- projectId: The ID of the project
- collectionUri: The collection URI

## NOTES

- Turning off a feature hides this service for all members of this project.
  If you choose to enable this service later, all your existing data will be available.
- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/feature-management/featurestatesquery>
