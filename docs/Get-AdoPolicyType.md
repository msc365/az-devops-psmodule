<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/types/get
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/06/2026
PlatyPS schema version: 2024-05-01
title: Get-AdoPolicyType
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoPolicyType

## SYNOPSIS

Retrieves Azure DevOps policy type details.

## SYNTAX

### ListPolicyTypes (Default)

```text
Get-AdoPolicyType [[-CollectionUri] <string>] [[-ProjectName] <string>] [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByTypeId

```text
Get-AdoPolicyType [[-CollectionUri] <string>] [[-ProjectName] <string>] [-Id] <string> [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet retrieves details of one or more Azure DevOps policy types within a specified project. You can retrieve all policy types, or specific policy types by ID. Policy types define the kinds of policies that can be configured for repositories, such as build validation, required reviewers, and work item linking.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
}
Get-AdoPolicyType @params
```

Retrieves all policy types from the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
}
Get-AdoPolicyType @params -Id 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
```

Retrieves the "Minimum number of reviewers" policy type from the project.

### EXAMPLE 3

#### PowerShell

```powershell
Get-AdoPolicyType -ProjectName 'my-project-1' -Id '0609b952-1397-4640-95ec-e00a01b2c241'
```

Retrieves the "Build" policy type using default collection URI from environment variable.

### EXAMPLE 4

#### PowerShell

```powershell
'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd', '0609b952-1397-4640-95ec-e00a01b2c241' | 
    Get-AdoPolicyType -ProjectName 'my-project-1'
```

Retrieves multiple policy types by piping their IDs to the cmdlet.

## PARAMETERS

### -CollectionUri

The collection URI of the Azure DevOps collection/organization, e.g., `https://dev.azure.com/my-org`.

```yaml
Type: System.String
DefaultValue: $env:DefaultAdoCollectionUri
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListPolicyTypes
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: ByTypeId
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

```yaml
Type: System.String
DefaultValue: $env:DefaultAdoProject
SupportsWildcards: false
Aliases:
- ProjectId
ParameterSets:
- Name: ListPolicyTypes
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: ByTypeId
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

The ID (uuid) of the policy type to retrieve. If not provided, retrieves all policy types. The set of policy types is standard across Azure DevOps; projects don't get different type catalogs, only different configurations.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- TypeId
- PolicyTypeId
ParameterSets:
- Name: ByTypeId
  Position: Named
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- 0517f88d-4ec5-4343-9d26-9930ebd53069
- ec003f37-8db0-4e10-992a-a2895045752c
- 90f9629b-664b-4804-a560-dd79b0c628f8
- 001a79cf-fda1-4c4e-9e7c-bac40ee5ead8
- 67ed70bd-2a6b-4006-af44-be590463f46d
- db2b9b4c-180d-4529-9701-01541d19f36b
- fa4e907d-c16b-4a4c-9dfa-4916e5d171ab
- c6a1889d-b943-4856-b76f-9e46bb6b0df2
- cbdc66da-9728-4af8-aada-9a5a32e4a226
- 7ed39669-655c-494e-b4a0-a08b4da0fcce
- 0609b952-1397-4640-95ec-e00a01b2c241
- 2e26e725-8201-4edd-8bf5-978563c34a80
- 51c78909-e838-41a2-9496-c647091e3c61
- 77ed4bd3-b063-4689-934a-175e4d0a78d7
- fd2167ab-b0be-447a-8ec8-39368250530e
- fa4e907d-c16b-4a4c-9dfa-4906e5d171dd
- 40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e
HelpMessage: ''
```

### -Version

The API version to use for the request. Default is '7.1'.

```yaml
Type: System.String
DefaultValue: 7.1
SupportsWildcards: false
Aliases:
- ApiVersion
ParameterSets:
- Name: ListPolicyTypes
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: ByTypeId
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

- System.String (Id parameter accepts pipeline input)

## OUTPUTS

### PSCustomObject

Returns a custom object with the following properties:
- **id**: The unique identifier (GUID) of the policy type
- **displayName**: The friendly display name of the policy type
- **description**: A detailed description of what the policy type does
- **projectName**: The name of the project the policy type belongs to
- **collectionUri**: The collection URI used for the query

## NOTES

- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.

- Current policy type IDs include:
  - `0517f88d-4ec5-4343-9d26-9930ebd53069` Git repository settings policy name
  - `ec003f37-8db0-4e10-992a-a2895045752c` Secrets scanning restriction
  - `90f9629b-664b-4804-a560-dd79b0c628f8` Secrets scanning restriction
  - `001a79cf-fda1-4c4e-9e7c-bac40ee5ead8` Path Length restriction
  - `67ed70bd-2a6b-4006-af44-be590463f46d` Proof of Presence
  - `db2b9b4c-180d-4529-9701-01541d19f36b` Reserved names restriction
  - `fa4e907d-c16b-4a4c-9dfa-4916e5d171ab` Require a merge strategy
  - `c6a1889d-b943-4856-b76f-9e46bb6b0df2` Comment requirements
  - `cbdc66da-9728-4af8-aada-9a5a32e4a226` Status
  - `7ed39669-655c-494e-b4a0-a08b4da0fcce` Git repository settings
  - `0609b952-1397-4640-95ec-e00a01b2c241` Build
  - `2e26e725-8201-4edd-8bf5-978563c34a80` File size restriction
  - `51c78909-e838-41a2-9496-c647091e3c61` File name restriction
  - `77ed4bd3-b063-4689-934a-175e4d0a78d7` Commit author email validation
  - `fd2167ab-b0be-447a-8ec8-39368250530e` Required reviewers
  - `fa4e907d-c16b-4a4c-9dfa-4906e5d171dd` Minimum number of reviewers
  - `40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e` Work item linking
- See [branch policies](https://learn.microsoft.com/en-us/azure/devops/repos/git/branch-policies) overview for more information about policy types.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/types/get>
- <https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/types/list>
