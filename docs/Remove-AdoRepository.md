<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/git/repositories/delete
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/02/2026
PlatyPS schema version: 2024-05-01
title: Remove-AdoRepository
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Remove-AdoRepository

## SYNOPSIS

Remove a repository from an Azure DevOps project.

## SYNTAX

### __AllParameterSets

```text
Remove-AdoRepository [[-CollectionUri] <string>] [[-ProjectName] <string>] [-Name] <string> [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet removes a repository from an Azure DevOps project through REST API.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    Name          = 'my-repository-1'
}
Remove-AdoRepository @params
```

Removes the specified repository from the project.

### EXAMPLE 2

#### PowerShell

```powershell
Remove-AdoRepository -Name $repo.id
```

Removes a repository using its ID and the default collection URI and project name from environment variables.

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

Mandatory. The repository ID or name to remove.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
- RepositoryId
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

### None

This cmdlet does not produce output. It removes the specified repository.

## NOTES

- Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.
- If a repository is not found, a warning is displayed and the cmdlet continues processing.
- The cmdlet accepts either repository ID (GUID) or repository name.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/git/repositories/delete>
