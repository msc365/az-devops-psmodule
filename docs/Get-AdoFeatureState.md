<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/feature-management/featurestatesquery
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/02/2026
PlatyPS schema version: 2024-05-01
title: Get-AdoFeatureState
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoFeatureState

## SYNOPSIS

Get the feature states for an Azure DevOps project.

## SYNTAX

### __AllParameterSets

```text
Get-AdoFeatureState [[-CollectionUri] <string>] [[-ProjectName] <string>] [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- ProjectId

## DESCRIPTION

This cmdlet retrieves the feature states for an Azure DevOps project through REST API.
Returns the states for Boards, Repos, Pipelines, Test Plans, and Artifacts features.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-002'
}
Get-AdoFeatureState @params
```

Retrieves the feature states for the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
Get-AdoFeatureState -ProjectName 'my-project-002'
```

Retrieves the feature states using the default collection URI from environment variable.

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

Returns a collection of feature state objects, each containing:
- feature: The feature name (Boards, Repos, Pipelines, TestPlans, Artifacts)
- featureId: The unique identifier for the feature
- state: The state as text ('enabled' or 'disabled')
- projectName: The name of the project
- projectId: The ID of the project
- collectionUri: The collection URI

## NOTES

- Requires an active Azure account login. Use `Connect-AzAccount` to authenticate:

  ```powershell
  Connect-AzAccount -Tenant '<tenant-id>' -Subscription '<subscription-id>'
  ```

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/feature-management/featurestatesquery>
