<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/delete
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/02/2026
PlatyPS schema version: 2024-05-01
title: Remove-AdoTeam
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Remove-AdoTeam

## SYNOPSIS

Removes a team from an Azure DevOps project.

## SYNTAX

### __AllParameterSets

```text
Remove-AdoTeam [[-CollectionUri] <string>] [[-ProjectName] <string>] [-Name] <string>
 [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet removes a team from an Azure DevOps project. This action permanently deletes the team.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
}
Remove-AdoTeam @params -Name 'my-team'
```

Removes the specified team from the project.

### EXAMPLE 2

#### PowerShell

```powershell
@('team-1', 'team-2') | Remove-AdoTeam -ProjectName 'my-project-1'
```

Removes multiple teams demonstrating pipeline input.

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

### -ProjectName

The ID or name of the project.
Defaults to the value of $env:DefaultAdoProject if not provided.

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

The ID or name of the team to remove.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- TeamName
- Id
- TeamId
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

The API version to use for the request.
Default is '7.1'.

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
- 7.2-preview.3
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

- None. This cmdlet does not generate output.

## NOTES

- This cmdlet permanently removes the team from Azure DevOps
- The Name parameter accepts either a team ID or team name
- Requires ShouldProcess confirmation due to ConfirmImpact = 'High'
- Use -Confirm:$false to skip confirmation prompts

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/delete>
