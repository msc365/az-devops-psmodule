<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/delete
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/02/2026
PlatyPS schema version: 2024-05-01
title: Remove-AdoProject
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Remove-AdoProject

## SYNOPSIS

Remove a project from an Azure DevOps organization.

## SYNTAX

### __AllParameterSets

```text
Remove-AdoProject [[-CollectionUri] <string>] [-Id] <string[]> [[-Version] <string>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet removes a project from an Azure DevOps organization.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    Id            = 'my-project-1'
}
Remove-AdoProject @params -Verbose
```

Removes the specified project from the organization.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
}
@('my-project-1', 'my-project-2') | Remove-AdoProject @params -Verbose
```

Removes multiple projects demonstrating pipeline input.

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

Mandatory.
The ID or name of the project to remove.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- ProjectId
- ProjectName
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

## OUTPUTS

- None. This cmdlet does not generate output.

## NOTES

- This cmdlet permanently removes the project from Azure DevOps
- The cmdlet accepts either a project ID (GUID) or project name for the Id parameter
- The cmdlet automatically polls for deletion completion before returning
- Requires ShouldProcess confirmation due to ConfirmImpact = 'High'
- Use -Confirm:$false to skip confirmation prompts

- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/delete>
