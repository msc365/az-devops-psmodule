<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/configurations/get
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/05/2026
PlatyPS schema version: 2024-05-01
title: Get-AdoPolicyConfiguration
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoPolicyConfiguration

## SYNOPSIS

Retrieves Azure DevOps policy configuration details.

## SYNTAX

### ListConfigurations

```text
Get-AdoPolicyConfiguration [[-CollectionUri] <string>] [[-ProjectName] <string>] [[-PolicyType] <string>] [[-Scope] <string>] [[-Top] <int32>] [[-ContinuationToken] <string>] [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByConfigurationId

```text
Get-AdoPolicyConfiguration [[-CollectionUri] <string>] [[-ProjectName] <string>] [[-Id] <int>] [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet retrieves details of one or more Azure DevOps policy configurations within a specified project. You can retrieve all policy configurations, filter by policy type, or retrieve a specific configuration by ID.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
}
Get-AdoPolicyConfiguration @params
```

Retrieves all policy configurations from the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
}
Get-AdoPolicyConfiguration @params -PolicyType 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
```

Retrieves all policy configurations of the specified policy type from the project.

### EXAMPLE 3

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
}
Get-AdoPolicyConfiguration @params -Id 42
```

Retrieves the policy configuration with ID 42 from the project.

### EXAMPLE 4

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
}
42, 43, 44 | Get-AdoPolicyConfiguration @params
```

Retrieves multiple policy configurations by ID using pipeline input.

## PARAMETERS

### -CollectionUri

The collection URI of the Azure DevOps collection/organization, e.g., <https://dev.azure.com/my-org>.
Defaults to $env:DefaultAdoCollectionUri.

```yaml
Type: System.String
DefaultValue: $env:DefaultAdoCollectionUri
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListConfigurations
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: ByConfigurationId
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
Defaults to $env:DefaultAdoProject.

```yaml
Type: System.String
DefaultValue: $env:DefaultAdoProject
SupportsWildcards: false
Aliases:
- ProjectId
ParameterSets:
- Name: ListConfigurations
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: ByConfigurationId
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Id

The ID of a specific policy configuration to retrieve.

```yaml
Type: System.Int32
DefaultValue: 
SupportsWildcards: false
Aliases:
- ConfigurationId
ParameterSets:
- Name: ByConfigurationId
  Position: Named
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PolicyType

The policy type ID to filter configurations. Used to retrieve configurations of a specific policy type.

```yaml
Type: System.String
DefaultValue: 
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListConfigurations
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Scope

The scope of the policy to filter configurations.
[Provided for legacy reasons] The scope on which a subset of policies is defined.

```yaml
Type: System.String
DefaultValue: 
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListConfigurations
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: [Provided for legacy reasons] The scope on which a subset of policies is defined.
```

### -Top

The maximum number of configurations to return. Used for pagination.

```yaml
Type: System.Int32
DefaultValue: 
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListConfigurations
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ContinuationToken

The continuation token for pagination. Used to retrieve the next page of results.

```yaml
Type: System.String
DefaultValue: 
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListConfigurations
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Version

The API version to use for the request.

```yaml
Type: System.String
DefaultValue: 7.1
SupportsWildcards: false
Aliases:
- ApiVersion
ParameterSets:
- Name: ListConfigurations
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: ByConfigurationId
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- 7.1
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

Returns policy configuration objects with the following properties:
- id: The unique identifier of the policy configuration
- type: The policy type object containing the type ID
- revision: The revision number of the configuration
- isEnabled: Whether the policy is enabled
- isBlocking: Whether the policy is blocking
- isDeleted: Whether the policy is deleted
- settings: The policy-specific settings object
- createdBy: The user who created the configuration
- createdDate: The date the configuration was created
- continuationToken: (Optional) Token for pagination when listing configurations
- projectName: The project name where the configuration exists
- collectionUri: The collection URI of the Azure DevOps organization

## NOTES

- Requires an active Azure account login. Use `Connect-AzAccount` to authenticate:

  ```powershell
  Connect-AzAccount -Tenant '<tenant-id>' -Subscription '<subscription-id>'
  ```

- If a policy configuration with the specified ID does not exist, a warning is displayed and the cmdlet continues execution.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/configurations/get>
- <https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/configurations/list>
