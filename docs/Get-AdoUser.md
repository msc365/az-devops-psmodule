<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/users/list
Locale: nl-NL
Module Name: Azure.DevOps.PSModule
ms.date: 02-14-2026
PlatyPS schema version: 2024-05-01
title: Get-AdoUser
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoUser

## SYNOPSIS

Get a single or multiple users in an Azure DevOps organization.

## SYNTAX

### ListUsers (Default)

```powershell
Get-AdoUser [-CollectionUri <string>] [-ScopeDescriptor <string>] [-SubjectTypes <string[]>]
 [-Name <string[]>] [-Version <string>] [<CommonParameters>]
```

### ByDescriptor

```powershell
Get-AdoUser [-CollectionUri <string>] [-UserDescriptor <string>] [-Version <string>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function retrieves a single or multiple users in an Azure DevOps organization through REST API.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Get-AdoUser
```

Retrieves all users in the Azure DevOps organization.

### EXAMPLE 2

#### PowerShell

```powershell
$project = Get-AdoProject -Name 'my-project-1'
$projectDescriptor = (Get-AdoDescriptor -StorageKey $project.Id)

$params = @{
    CollectionUri   = 'https://dev.azure.com/my-org'
    ScopeDescriptor = $projectDescriptor
    SubjectTypes    = 'aad'
}
Get-AdoUser @params
```

Retrieves all users in the specified project with subject types 'aad'.

### EXAMPLE 3

#### PowerShell

```powershell
@(
    'aad.00000000-0000-0000-0000-000000000000',
    'aad.00000000-0000-0000-0000-000000000001',
    'aad.00000000-0000-0000-0000-000000000002'
) | Get-AdoUser
```

Retrieves the users with the specified descriptors.

## PARAMETERS

### -CollectionUri

Optional.
The collection URI of the Azure DevOps collection/organization, e.g., <https://vssps.dev.azure.com/my-org>.

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

Optional.
A user's display name to filter the retrieved results.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- DisplayName
- UserName
ParameterSets:
- Name: ListUsers
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ScopeDescriptor

Optional.
Specify a non-default scope (collection, project) to search for users.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListUsers
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -SubjectTypes

Optional.
A comma separated list of user subject subtypes to reduce the retrieved results, e.g.
'msa', 'aad', 'svc' (service identity), 'imp' (imported identity), etc.

```yaml
Type: System.String[]
DefaultValue: "@('msa', 'aad', 'svc', 'imp')"
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListUsers
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -UserDescriptor

Optional.
The descriptor of a specific user to retrieve.
When provided, retrieves a single user by its descriptor.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByDescriptor
  Position: Named
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Version

Optional.
The API version to use for the request.
Default is '7.2-preview.1'.
The -preview flag must be supplied in the api-version for this request to work.

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
HelpMessage: The -preview flag must be supplied in the api-version for this request to work.
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

Retrieves users in an Azure DevOps organization.


## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/users/get>
- <https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/users/list>
