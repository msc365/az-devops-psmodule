<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: 
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/04/2026
PlatyPS schema version: 2024-05-01
title: Get-AdoEnvironment 
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoEnvironment

## SYNOPSIS

Get a list of Azure DevOps Pipeline Environments within a specified project.

## SYNTAX

### ListEnvironments (Default)

```text
Get-AdoEnvironment [[-CollectionUri] <string>] [[-ProjectName] <string>] [[-Name] <string>]
 [[-ContinuationToken] <string>] [[-Top] <int32>] [[-Version] <string>] [<CommonParameters>]
```

### ByEnvironmentId

```text
Get-AdoEnvironment [[-CollectionUri] <string>] [[-ProjectName] <string>] [-Id] <int32>
 [[-Expands] <string>] [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet retrieves a list of Azure DevOps Pipeline Environments for a given project, with optional filtering by environment name and pagination support.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
}

Get-AdoEnvironment @params -Top 2
Get-AdoEnvironment @params -Name 'my-environment-tst'
Get-AdoEnvironment @params -Name '*environment*'
Get-AdoEnvironment @params -Name 'my-env*' -Top 2
```

Retrieves environments from the specified project with various filtering and pagination options.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
}
@(
    'my-environment-tst',
    'my-environment-dev'
) | Get-AdoEnvironment @params -Verbose
```

Retrieves the specified environments from the project, demonstrating pipeline input.

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
The name or id of the project.

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

### -Name

Optional.
The name of the environment to filter the results.
Supports wildcard patterns.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: true
Aliases: []
ParameterSets:
- Name: ListEnvironments
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ContinuationToken

Optional.
A continuation token from a previous request to get the next set of results.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListEnvironments
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Top

Optional.
The maximum number of environments to return.

```yaml
Type: System.Int32
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListEnvironments
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Id

Optional.
The ID of a specific environment to retrieve.

```yaml
Type: System.Int32
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByEnvironmentId
  Position: Named
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Expands

Optional.
Include additional details in the returned objects.
Valid values are 'none' and 'resourceReferences'.
Default is 'none'.

```yaml
Type: System.String
DefaultValue: none
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByEnvironmentId
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- none
- resourceReferences
HelpMessage: ''
```

### -Version

Optional.
The API version to use for the request.
Default is '7.2-preview.1'.

```yaml
Type: System.String
DefaultValue: 7.2-preview.1
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
- 7.2-preview.1
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

Returns environment objects with the following properties:
- id: The unique identifier of the environment
- name: The name of the environment
- createdBy: ID of the user who created the environment
- createdOn: Date and time when the environment was created
- lastModifiedBy: ID of the user who last modified the environment
- lastModifiedOn: Date and time when the environment was last modified
- projectName: The project name
- collectionUri: The collection URI
- resources: (Only when Expands is 'resourceReferences') Array of resource references
- continuationToken: (When applicable) Token for pagination

## NOTES

- Requires an active Azure account login. Use `Connect-AzAccount` to authenticate:

  ```powershell
  Connect-AzAccount -Tenant '<tenant-id>' -Subscription '<subscription-id>'
  ```

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/environments/environments/list>

