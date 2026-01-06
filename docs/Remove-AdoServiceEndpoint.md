<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/delete?view=azure-devops
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Remove-AdoServiceEndpoint
-->

<!-- cSpell: ignore dontshow -->

# Remove-AdoServiceEndpoint

## SYNOPSIS

Removes an Azure DevOps service endpoint (service connection) from one or more projects.

## SYNTAX

### __AllParameterSets

```text
Remove-AdoServiceEndpoint [[-CollectionUri] <string>] [-Id] <string> [-ProjectIds] <string[]>
 [-Deep] [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function removes a service endpoint (service connection) from one or more Azure DevOps projects. You can perform a deep deletion to also remove all associated pipeline resources.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/myorg'
    Id            = '00000000-0000-0000-0000-000000000001'
    ProjectIds    = 'MyProject'
}
Remove-AdoServiceEndpoint @params
```

Removes the service endpoint from the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    Id         = '00000000-0000-0000-0000-000000000001'
    ProjectIds = @('Project1', 'Project2', 'Project3')
}
Remove-AdoServiceEndpoint @params
```

Removes the service endpoint from multiple projects.

### EXAMPLE 3

#### PowerShell

```powershell
Remove-AdoServiceEndpoint -Id '00000000-0000-0000-0000-000000000001' -ProjectIds 'MyProject' -Deep
```

Removes the service endpoint and all associated pipeline resources from the project.

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
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Id

Mandatory. The ID of the service endpoint to remove.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- EndpointId
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

### -ProjectIds

Mandatory. One or more project IDs from which to remove the service endpoint.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Deep

Optional. If specified, performs a deep deletion to remove all associated pipeline resources.

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
  ValueFromPipelineByPropertyName: false
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
  Position: 3
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

### None

This cmdlet does not return any output.

## NOTES

- If the service endpoint is not found, a warning is displayed instead of throwing an error.
- The cmdlet has a high impact confirmation level, so it prompts for confirmation by default unless -Confirm:$false is specified.
- Multiple projects can be specified to remove the service endpoint from all of them in a single operation.
- Supports ShouldProcess for WhatIf and Confirm parameters (high impact).
- Requires an active Azure account login. Use `Connect-AzAccount` to authenticate:

  ```powershell
  Connect-AzAccount -Tenant '<tenant-id>' -Subscription '<subscription-id>'
  ```

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/delete>
