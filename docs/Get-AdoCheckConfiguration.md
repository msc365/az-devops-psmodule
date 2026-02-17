<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/list
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/03/2026
PlatyPS schema version: 2024-05-01
title: Get-AdoCheckConfiguration
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoCheckConfiguration

## SYNOPSIS

Get a list of check configurations for a specific resource.

## SYNTAX

### ConfigurationList (Default)

```text
Get-AdoCheckConfiguration -ResourceType <string> -ResourceName <string> [-CollectionUri <string>]
 [-ProjectName <string>] [-DefinitionType <string[]>] [-Expands <string>] [-Version <string>]
 [<CommonParameters>]
```

### ConfigurationListByResourceId

```text
Get-AdoCheckConfiguration -ResourceType <string> -ResourceId <string> [-CollectionUri <string>]
 [-ProjectName <string>] [-DefinitionType <string[]>] [-Expands <string>] [-Version <string>]
 [<CommonParameters>]
```

### ConfigurationById

```text
Get-AdoCheckConfiguration -Id <int> [-CollectionUri <string>] [-ProjectName <string>]
 [-Expands <string>] [-Version <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function retrieves check configurations for a specified resource within an Azure DevOps project.
You need to provide the resource type and resource ID to filter the results.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    ResourceType  = 'environment'
    ResourceName  = 'my-environment-tst'
}
Get-AdoCheckConfiguration @params -Verbose
```

Retrieves check configurations for the specified environment within the project using provided parameters.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    ResourceType  = 'environment'
    Expands       = 'settings'
}
@(
    'my-environment-tst',
    'my-environment-dev'
) | Get-AdoCheckConfiguration @params -Verbose
```

Retrieves check configurations for the specified environments within the project using provided parameters, demonstrating pipeline input.

### EXAMPLE 3

#### PowerShell

```powershell
Get-AdoCheckConfiguration -Id 1 -Expands 'settings' -Verbose
```

Retrieves the check configuration with ID 1, including its settings.

### EXAMPLE 4

```powershell
$params = @{
    CollectionUri  = 'https://dev.azure.com/my-org'
    ProjectName    = 'my-project-1'
    ResourceType   = 'environment'
    ResourceId     = '00000000-0000-0000-0000-000000000100'
    DefinitionType = 'approval'
    Expands        = 'settings'
}
Get-AdoCheckConfiguration @params -Verbose
```

Retrieves check configurations for the specified environment ID filtered by the 'approval' definition type.

### EXAMPLE 5

#### PowerShell

```powershell
$params = @{
    CollectionUri  = 'https://dev.azure.com/my-org'
    ProjectName    = 'my-project-1'
    ResourceType   = 'environment'
    ResourceName   = 'my-environment-tst'
    DefinitionType = 'approval'
    Expands        = 'settings'
}
Get-AdoCheckConfiguration @params -Verbose
```

Retrieves check configurations for the specified environment name filtered by the 'approval' definition type.

### EXAMPLE 6

#### PowerShell

```powershell
$params = @{
    CollectionUri  = 'https://dev.azure.com/my-org'
    ProjectName    = 'my-project-1'
    ResourceType   = 'environment'
    ResourceName   = 'my-environment-tst'
    DefinitionType = 'approval', 'preCheckApproval'
    Expands        = 'settings'
}
Get-AdoCheckConfiguration @params -Verbose
```

Retrieves check configurations for the specified environment filtered by multiple definition types.

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

### -ResourceType

Mandatory.
The type of the resource to filter the results.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ConfigurationList
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- endpoint
- environment
- variablegroup
- repository
HelpMessage: ''
```

### -ResourceName

Mandatory.
The name of the resource to filter the results.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ConfigurationList
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ResourceId

Mandatory.
The ID of the resource to filter the results.
If not provided, the function will attempt to resolve it based on the ResourceType and ResourceName.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ConfigurationListByResourceId
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -DefinitionType

Optional.
The type(s) of check definitions to filter the results.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ConfigurationListByResourceId
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: ConfigurationList
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- approval
- preCheckApproval
- postCheckApproval
- branchControl
- businessHours
HelpMessage: ''
```

### -Id

Mandatory.
The ID of the check configuration to retrieve.

```yaml
Type: System.Int32
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ConfigurationById
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Expands

Optional.
Specifies additional details to include in the response.
Default is 'none'.

Valid values are 'none' and 'settings'.

```yaml
Type: System.String
DefaultValue: none
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
- none
- settings
HelpMessage: ''
```

### -Version

Optional.
The API version to use for the request.
Default is '7.2-preview.1'.
The -preview flag must be supplied in the api-version for such requests.

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
- 7.1-preview.1
- 7.2-preview.1
HelpMessage: The -preview flag must be supplied in the api-version for such requests.
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

## NOTES

- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/get>
- <https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/list>
