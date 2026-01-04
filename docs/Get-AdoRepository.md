<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/git/repositories/get-repository
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/02/2026
PlatyPS schema version: 2024-05-01
title: Get-AdoRepository
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoRepository

## SYNOPSIS

Retrieves Azure DevOps repository details.

## SYNTAX

### ListRepositories

```text
Get-AdoRepository [[-CollectionUri] <string>] [[-ProjectName] <string>] [-IncludeLinks] [-IncludeHidden] [-IncludeAllUrls] [[-Version] <string>] [<CommonParameters>]
```

### ByNameOrId

```text
Get-AdoRepository [[-CollectionUri] <string>] [[-ProjectName] <string>] [[-Name] <string>] [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet retrieves details of one or more Azure DevOps repositories within a specified project. You can retrieve all repositories, or specific repositories by name or ID.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
}
Get-AdoRepository @params
```

Retrieves all repositories from the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    Name          = 'my-repository-1'
}
Get-AdoRepository @params
```

Retrieves the specified repository from the project.

### EXAMPLE 3

#### PowerShell

```powershell
Get-AdoRepository -Name 'my-repository-1'
```

Retrieves a specific repository using the default collection URI and project name from environment variables.

## PARAMETERS

### -CollectionUri

Optional. The collection URI of the Azure DevOps collection/organization, e.g., <https://dev.azure.com/my-org>.
Defaults to the value of $env:DefaultAdoCollectionUri.

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

Optional. The ID or name of the project.
Defaults to the value of $env:DefaultAdoProject.

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

Optional. The ID or name of the repository(s) to retrieve. If not provided, retrieves all repositories.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Repository
- RepositoryId
- RepositoryName
ParameterSets:
- Name: ByNameOrId
  Position: Named
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeLinks

Optional switch. Include additional links in the response.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListRepositories
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeHidden

Optional switch. Include hidden repositories in the response.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListRepositories
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeAllUrls

Optional switch. Include all URLs in the response.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListRepositories
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

Optional. The API version to use for the request. Default is '7.1'.

```yaml
Type: System.String
DefaultValue: '7.1'
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
- '7.1'
- '7.2-preview.2'
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

Returns a custom object with the following properties:
- id: The unique identifier of the repository
- name: The name of the repository
- project: The project object containing repository details
- defaultBranch: The default branch of the repository
- url: The URL of the repository
- remoteUrl: The remote URL for cloning the repository
- projectName: The name of the project containing the repository
- collectionUri: The collection URI of the Azure DevOps organization

## NOTES

- Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.
- If a repository is not found, a warning is displayed and the cmdlet continues processing.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/git/repositories/get-repository>
