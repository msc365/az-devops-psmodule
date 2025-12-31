<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/list
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Get-AdoGroup
-->

<!-- cSpell: ignore dontshow -->

# Get-AdoGroup

## SYNOPSIS

Get a single or multiple groups in an Azure DevOps organization.

## SYNTAX

### __AllParameterSets

```text
Get-AdoGroup [[-CollectionUri] <string>] [[-ScopeDescriptor] <string>] [[-SubjectTypes] <string[]>]
 [[-ContinuationToken] <string>] [[-DisplayName] <string[]>] [[-Version] <string>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function retrieves a single or multiple groups in an Azure DevOps organization through REST API.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Get-AdoGroup
```

Retrieves all groups in the Azure DevOps organization.

### EXAMPLE 2

#### PowerShell

```powershell
$project = Get-AdoProject -Name 'my-project'
$projectDescriptor = (Get-AdoDescriptor -StorageKey $project.Id)

$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ScopeDescriptor = $projectDescriptor
    SubjectTypes    = 'vssgp'
}
Get-AdoGroup @params
```

Retrieves all groups in the specified project with subject types 'vssgp'.

### EXAMPLE 3

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ScopeDescriptor = $projectDescriptor
    SubjectTypes    = 'vssgp'
}
@(
    'Project Administrators',
    'Release Administrators'
) | Get-AdoGroup @params
```

Retrieves the 'Project Administrators' and 'Release Administrators' groups of type 'vssgp', demonstrating pipeline input.

## PARAMETERS

### -CollectionUri

Optional.
The collection URI of the Azure DevOps collection/organization, e.g., <https://vssps.dev.azure.com/myorganization>.

```yaml
Type: System.String
DefaultValue: ($env:DefaultAdoCollectionUri -replace 'https://', 'https://vssps.')
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

### -ScopeDescriptor

Optional.
Specify a non-default scope (collection, project) to search for groups.

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

### -SubjectTypes

Optional.
A comma separated list of user subject subtypes to reduce the retrieved results, e.g. Microsoft.IdentityModel.Claims.ClaimsIdentity

```yaml
Type: System.String[]
DefaultValue: ('vssgp', 'aadgp')
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
- vssgp
- aadgp
HelpMessage: ''
```

### -ContinuationToken

Optional.
An opaque data blob that allows the next page of data to resume immediately after where the previous page ended.
The only reliable way to know if there is more data left is the presence of a continuation token.

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
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -DisplayName

Optional.
A comma separated list of group display names to filter the retrieved results.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
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

### System.Object

An object representing the groups in the specified scope.

## NOTES

- Requires an active Azure account login. Use `Connect-AzAccount` to authenticate:

  ```powershell
  Connect-AzAccount -Tenant '<tenant-id>' -Subscription '<subscription-id>'
  ```

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/get>
- <https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/list>
