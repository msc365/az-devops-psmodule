<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/get-service-endpoints-by-names
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Get-AdoServiceEndpoint
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore hashtable dontshow -->

# Get-AdoServiceEndpoint

## SYNOPSIS

Retrieves Azure DevOps service endpoints (service connections).

## SYNTAX

### ByNames (Default)

```text
Get-AdoServiceEndpoint [[-CollectionUri] <string>] [[-ProjectName] <string>] [[-Names] <string[]>]
 [[-ActionFilter] <string>] [[-Owner] <string>] [[-Type] <string>] [[-AuthSchemes] <string>]
 [-IncludeFailed] [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByIds

```text
Get-AdoServiceEndpoint [[-CollectionUri] <string>] [[-ProjectName] <string>] [[-Ids] <string[]>]
 [[-ActionFilter] <string>] [[-Owner] <string>] [[-Type] <string>] [[-AuthSchemes] <string>]
 [-IncludeFailed] [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function retrieves service endpoint details from an Azure DevOps project. You can retrieve endpoints by name or ID, and filter by various properties such as type, owner, and action permissions.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/myorg'
    ProjectName   = 'my-project-1'
}
Get-AdoServiceEndpoint @params
```

Retrieves all service endpoints in the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    ProjectName = 'my-project-1'
    Names       = 'my-endpoint-1'
}
Get-AdoServiceEndpoint @params
```

Retrieves the service endpoint with the name 'my-endpoint-1'.

### EXAMPLE 3

#### PowerShell

```powershell
$params = @{
    ProjectName = 'my-project-1'
    Ids         = @('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002')
}
Get-AdoServiceEndpoint @params
```

Retrieves service endpoints with the specified IDs.

### EXAMPLE 4

#### PowerShell

```powershell
$params = @{
    ProjectName = 'my-project-1'
    Type        = 'AzureRM'
    Owner       = 'library'
}
Get-AdoServiceEndpoint @params
```

Retrieves all Azure Resource Manager endpoints owned by the library.

### EXAMPLE 5

#### PowerShell

```powershell
Get-AdoServiceEndpoint -ProjectName 'my-project-1' -ActionFilter 'manage'
```

Retrieves service endpoints where the caller has manage permissions.

## PARAMETERS

### -CollectionUri

Optional. The URI of the Azure DevOps collection or Azure DevOps Server. If not provided, it uses the default collection URI from $env:DefaultAdoCollectionUri.

```yaml
Type: System.String
DefaultValue: $env:DefaultAdoCollectionUri
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ProjectName

Optional. The name or ID of the project. If not provided, it uses the default project from $env:DefaultAdoProject.

```yaml
Type: System.String
DefaultValue: $env:DefaultAdoProject
SupportsWildcards: false
Aliases:
- ProjectId
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Names

Optional. One or more service endpoint names to retrieve.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- EndpointNames
ParameterSets:
- Name: ByNames
  Position: 2
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Ids

Optional. One or more service endpoint IDs to retrieve.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- EndpointIds
ParameterSets:
- Name: ByIds
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ActionFilter

Optional. Filters service endpoints based on action permissions. Valid values: none, manage, use, view.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByIds
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- none
- manage
- use
- view
HelpMessage: ''
```

### -Owner

Optional. Filters service endpoints by owner. Valid values: library, agentcloud.

```yaml
Type: System.String
DefaultValue: ''
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
- library
- agentcloud
HelpMessage: ''
```

### -Type

Optional. Filters service endpoints by type (e.g., 'AzureRM', 'GitHub', 'Docker').

```yaml
Type: System.String
DefaultValue: ''
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

### -AuthSchemes

Optional. Filters service endpoints by authorization scheme.

```yaml
Type: System.String
DefaultValue: ''
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

### -IncludeFailed

Optional. Include service endpoints that have failed authorization.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: false
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

### -Version

Optional. The API version to use. Defaults to '7.1'.

```yaml
Type: System.String
DefaultValue: 7.1
SupportsWildcards: false
Aliases:
- ApiVersion
- Api
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- 7.1
- 7.2-preview.4
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

Service endpoint objects with the following properties:
- id: The unique identifier of the service endpoint
- name: The name of the service endpoint
- type: The type of service endpoint (e.g., AzureRM, GitHub, Docker)
- description: The description of the service endpoint
- authorization: Authorization details including scheme and parameters
- isShared: Whether the endpoint is shared across projects
- isReady: Whether the endpoint is ready for use
- owner: The owner of the endpoint (library or agentcloud)
- data: Additional data associated with the endpoint
- serviceEndpointProjectReferences: Project references for the endpoint
- projectName: The project name
- collectionUri: The collection URI

## NOTES

- If a service endpoint is not found, a warning is displayed instead of throwing an error.
- Supports ShouldProcess for WhatIf and Confirm parameters.
- Requires an active Azure account login. Use `Connect-AzAccount` to authenticate:

  ```powershell
  Connect-AzAccount -Tenant '<tenant-id>' -Subscription '<subscription-id>'
  ```

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/get>
- <https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/get-service-endpoints>
- <https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/get-service-endpoints-by-names>
