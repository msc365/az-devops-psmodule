<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/get-service-endpoints-by-names
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Get-AdoServiceEndpointByName
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore hashtable dontshow -->

# Get-AdoServiceEndpointByName

## SYNOPSIS

Get the service endpoint details for an Azure DevOps service endpoint.

## SYNTAX

### __AllParameterSets

```text
Get-AdoServiceEndpointByName [-ProjectId] <string> [-EndpointNames] <string[]>
 [[-ApiVersion] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function retrieves the service endpoint details for an Azure DevOps service endpoint through REST API.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Get-AdoServiceEndpoint -ProjectId 'my-project-1' -EndpointNames 'id-my-adortagent'
```

Retrieves the service endpoint with the name 'id-my-adortagent' in the project 'my-project-1'.

### EXAMPLE 2

#### PowerShell

```powershell
Get-AdoServiceEndpoint -ProjectId 'my-project-1' -EndpointNames 'id-my-adortagent', 'id-my-other-endpoint'
```

Retrieves the service endpoints with the names 'id-my-adortagent' and 'id-my-other-endpoint' in the project 'my-project-1'.

## PARAMETERS

### -ApiVersion

Optional.
The API version to use.

```yaml
Type: System.String
DefaultValue: 7.1
SupportsWildcards: false
Aliases:
- Api
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

### -EndpointNames

Mandatory.
The names of the service endpoints.

```yaml
Type: System.String[]
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

### -ProjectId

Mandatory.
The unique identifier or name of the project.

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

## OUTPUTS

### System.Object[]

Objects representing the service endpoints.

## NOTES

- Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/get-service-endpoints-by-names>
