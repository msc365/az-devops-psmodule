<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/add
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 12/31/2025
PlatyPS schema version: 2024-05-01
title: New-AdoCheckConfiguration
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# New-AdoCheckConfiguration

## SYNOPSIS

Create a new check configuration for a specific resource.

## SYNTAX

### __AllParameterSets

```text
New-AdoCheckConfiguration [[-CollectionUri] <string>] [[-ProjectName] <string>]
 [-Configuration] <PSCustomObject[]> [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- ProjectId (for ProjectName)

## DESCRIPTION

This function creates a new check configuration for a specified resource within an Azure DevOps project.
When existing configuration is found, it will be returned instead of creating a new one.

You need to provide the configuration in JSON format.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$approverId = 0000000-0000-0000-0000-000000000000
$environmentId = 1

$definitionRefId = '26014962-64a0-49f4-885b-4b874119a5cc' # Approval
$definitionRefId = '0f52a19b-c67e-468f-b8eb-0ae83b532c99' # Pre-check approval

$configJson = @{
    settings = @{
        approvers            = @(
            @{
                id = $approverId
            }
        )
        executionOrder       = 'anyOrder'
        minRequiredApprovers = 0
        instructions         = 'Approval required before deploying to environment'
        blockedApprovers     = @()
        definitionRef        = @{
            id = $definitionRefId
        }
    }
    timeout  = 1440 # 1 day
    type     = @{
        id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
        name = 'Approval'
    }
    resource = @{
        type = 'environment'
        id   = $environmentId
    }
} | ConvertTo-Json -Depth 5 -Compress

$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    Configuration = $configJson
}
New-AdoCheckConfiguration @params
```

Creates a new check configuration in the specified project using the provided configuration JSON.

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

### -Configuration

Mandatory.
A string representing the check configuration in JSON format.

```yaml
Type: System.Management.Automation.PSCustomObject[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
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

### PSCustomObject

An object representing the created check configuration.

## NOTES

- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/add>
