<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/core/processes
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/02/2026
PlatyPS schema version: 2024-05-01
title: Get-AdoProcess
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoProcess

## SYNOPSIS

Retrieves Azure DevOps process details.

## SYNTAX

### __AllParameterSets

```text
Get-AdoProcess [[-CollectionUri] <string>] [[-Name] <string>] [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet retrieves details of one or more Azure DevOps processes within a specified organization. You can retrieve all processes or a specific process by name. Processes define the work item types, workflow, and fields available in Azure DevOps projects.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
}
Get-AdoProcess @params
```

Retrieves all available processes from the specified organization.

### EXAMPLE 2

#### PowerShell

```powershell
Get-AdoProcess -Name 'Agile'
```

Retrieves the Agile process details using the default collection URI from environment variable.

### EXAMPLE 3

#### PowerShell

```powershell
@('Agile', 'Scrum') | Get-AdoProcess -CollectionUri 'https://dev.azure.com/my-org'
```

Retrieves multiple processes by name demonstrating pipeline input.

## PARAMETERS

### -CollectionUri

The collection URI of the Azure DevOps collection/organization.
Defaults to the value of $env:DefaultAdoCollectionUri if not provided.

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

### -Name

The name of the process to retrieve. If not provided, retrieves all processes.
Valid values are predefined Azure DevOps process templates.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Process
- ProcessName
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- Agile
- Scrum
- CMMI
- Basic
HelpMessage: ''
```

### -Version

The API version to use for the request.
Defaults to '7.1'.

```yaml
Type: System.String
DefaultValue: 7.1
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

- System.String

## OUTPUTS

### PSCustomObject

Returns one or more process objects with the following properties:
- id: The unique identifier of the process
- name: The name of the process (Agile, Scrum, CMMI, or Basic)
- description: A description of the process
- url: The REST API URL for the process
- type: The type of the process
- isDefault: Boolean indicating if this is the default process
- collectionUri: The collection URI the process belongs to

## NOTES

- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.

- The CollectionUri parameter can be set as an environment variable ($env:DefaultAdoCollectionUri) to avoid specifying it in each call.
- Supports ShouldProcess for -WhatIf and -Confirm functionality.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/core/processes>
