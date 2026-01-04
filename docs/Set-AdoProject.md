<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/update
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/02/2026
PlatyPS schema version: 2024-05-01
title: Set-AdoProject
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Set-AdoProject

## SYNOPSIS

Updates an existing Azure DevOps project.

## SYNTAX

### __AllParameterSets

```text
Set-AdoProject [[-CollectionUri] <string>] [-Id] <string[]> [[-Name] <string>]
 [[-Description] <string>] [[-Visibility] <string>] [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- ProjectId
- ProjectName

## DESCRIPTION

This cmdlet updates an existing Azure DevOps project within a specified organization.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    Id            = 'my-project-1'
    Name          = 'my-project-updated'
}
Set-AdoProject @params -Verbose
```

Updates the name of the specified project.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
}
[PSCustomObject]@{
    Id          = 'my-project-1'
    Name        = 'my-project-updated'
    Description = 'Updated description'
} | Set-AdoProject @params -Verbose
```

Updates the project using pipeline input.

## PARAMETERS

### -CollectionUri

Optional.
The collection URI of the Azure DevOps collection/organization, e.g., <https://dev.azure.com/my-org>.

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

### -Id

The ID (uuid) or name of the project to update.
The cmdlet will automatically resolve project names to IDs.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- ProjectId
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

### -Description

The new description for the project.

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

### -Name

The new name for the project.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- ProjectName
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

### -Visibility

Optional.
The visibility of the project.
Default is 'Private'.

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
AcceptedValues:
- Private
- Public
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
- 7.2-preview.4
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

- System.String
- PSCustomObject

## OUTPUTS

### PSCustomObject

Returns the updated project object with the following properties:
- id: The unique identifier of the project
- name: The updated name of the project
- description: The updated description of the project
- visibility: The visibility of the project (Private or Public)
- state: The state of the project
- defaultTeam: Information about the default team for the project
- collectionUri: The collection URI the project belongs to

## NOTES

- The cmdlet accepts either a project ID (GUID) or project name for the Id parameter
- The cmdlet automatically polls for update completion before returning
- Only properties that are explicitly provided will be updated
- Requires ShouldProcess confirmation due to ConfirmImpact = 'High'

- Requires an active Azure account login. Use `Connect-AzAccount` to authenticate:

  ```powershell
  Connect-AzAccount -Tenant '<tenant-id>' -Subscription '<subscription-id>'
  ```

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/update>
