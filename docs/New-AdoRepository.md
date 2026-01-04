<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/git/repositories/create
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/02/2026
PlatyPS schema version: 2024-05-01
title: New-AdoRepository
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# New-AdoRepository

## SYNOPSIS

Create a new repository in an Azure DevOps project.

## SYNTAX

### __AllParameterSets

```text
New-AdoRepository [[-CollectionUri] <string>] [[-ProjectName] <string>] [-Name] <string> [[-SourceRef] <string>] [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet creates a new repository in an Azure DevOps project through REST API.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    Name          = 'my-repository-1'
}
New-AdoRepository @params
```

Creates a new repository named 'my-repository-1' in the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
New-AdoRepository -Name 'my-repository-1'
```

Creates a new repository using the default collection URI and project name from environment variables.

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

Mandatory. The name of the repository.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- RepositoryName
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -SourceRef

Optional. Specify the source refs to use while creating a fork repo.

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
- If a repository with the specified name already exists, the cmdlet retrieves and returns the existing repository.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/git/repositories/create>
