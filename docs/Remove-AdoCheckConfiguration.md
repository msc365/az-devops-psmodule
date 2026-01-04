<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/delete
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 12/31/2025
PlatyPS schema version: 2024-05-01
title: Remove-AdoCheckConfiguration
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Remove-AdoCheckConfiguration

## SYNOPSIS

Remove a check configuration by its ID.

## SYNTAX

### __AllParameterSets

```text
Remove-AdoCheckConfiguration [[-CollectionUri] <string>] [[-ProjectName] <string>]
 [-Id] <int32[]> [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- ProjectId (for ProjectName)

## DESCRIPTION

This cmdlet deletes a specific check configuration using its unique identifier within a specified resource.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    Id = 1
}
Remove-AdoCheckConfiguration @params -Verbose
```

Removes the check configuration with ID 1 from the specified resource using the provided parameters.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
}
@(
    1, 2, 3
) | Remove-AdoCheckConfiguration @params -Verbose
```

Removes the check configurations with IDs 1, 2, and 3 from the specified resource demonstrating pipeline input.

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

### -ProjectName

Optional.
The name or id of the project.

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

### -Id

Mandatory.
The ID of the check configuration to remove.

```yaml
Type: System.Int32[]
DefaultValue: 0
SupportsWildcards: false
Aliases: []
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

- N/A

## NOTES

- Requires an active Azure account login. Use `Connect-AzAccount` to authenticate:

  ```powershell
  Connect-AzAccount -Tenant '<tenant-id>' -Subscription '<subscription-id>'
  ```

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/delete>
