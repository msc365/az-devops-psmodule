<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/add
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/03/2026
PlatyPS schema version: 2024-05-01
title: New-AdoCheckApproval
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# New-AdoCheckApproval

## SYNOPSIS

Create a new approval check for a specific resource.

## SYNTAX

### __AllParameterSets

```text
New-AdoCheckApproval [[-CollectionUri] <string>] [[-ProjectName] <string>]
 [-Approvers] <object[]> [-ResourceType] <string> [-ResourceName] <string>
 [[-DefinitionType] <string>] [[-Instructions] <string>] [[-Timeout] <int32>]
 [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function creates a new approval check for a specified resource within an Azure DevOps project.
When existing configuration is found, it will be returned instead of creating a new one.
Approval checks ensure that deployments or other operations require approval from designated users before proceeding.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$approvers = @{ id = '00000000-0000-0000-0000-000000000000' }

$params = @{
    CollectionUri  = 'https://dev.azure.com/my-org'
    ProjectName    = 'my-project-1'
    Approvers      = $approvers
    ResourceType   = 'environment'
    ResourceName   = 'my-environment-tst'
    DefinitionType = 'approval'
    Instructions   = 'Approval required before deploying to environment'
    Timeout        = 1440
}
New-AdoCheckApproval @params
```

Creates a new approval check in the specified project using the provided parameters.

### EXAMPLE 2

#### PowerShell

```powershell
$approvers = @(
    @{ id = '11111111-1111-1111-1111-111111111111' },
    @{ id = '22222222-2222-2222-2222-222222222222' }
)

'my-environment-tst', 'my-environment-prd' | New-AdoCheckApproval -Approvers $approvers -ResourceType 'environment'
```

Creates approval checks for multiple environments using pipeline input.

### EXAMPLE 3

#### PowerShell

```powershell
$params = @{
    CollectionUri  = 'https://dev.azure.com/my-org'
    ProjectName    = 'my-project-1'
    Approvers      = @{ id = '00000000-0000-0000-0000-000000000000' }
    ResourceType   = 'environment'
    ResourceName   = 'my-environment-tst'
    DefinitionType = 'preCheckApproval'
}
New-AdoCheckApproval @params
```

Creates a pre-check approval for the specified environment.

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

### -Approvers

Mandatory.
An array of approvers in the format @{ id = 'originId' }.
Each approver must have an 'id' property containing the Azure DevOps identity ID.

```yaml
Type: System.Object[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ResourceType

Mandatory.
The type of resource to which the check will be applied.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- endpoint
- environment
- variablegroup
- repository
HelpMessage: ''
```

### -ResourceName

Mandatory.
The name of the resource to which the check will be applied.

```yaml
Type: System.String
DefaultValue: ''
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

### -DefinitionType

Optional.
The type of approval check to create.
Default is 'approval'.

```yaml
Type: System.String
DefaultValue: approval
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
- approval
- preCheckApproval
- postCheckApproval
HelpMessage: ''
```

### -Instructions

Optional.
Instructions for the approvers.
Provides guidance on what should be considered when approving.

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

### -Timeout

Optional.
The timeout in minutes for the approval check.
Default is 1440 (1 day).

```yaml
Type: System.Int32
DefaultValue: 1440
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

Optional.
The API version to use for the request.
Default is '7.2-preview.1'.
The -preview flag must be supplied in the api-version for such requests.

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
HelpMessage: The -preview flag must be supplied in the api-version for such requests.
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

Returns a custom object representing the approval check configuration:
- id: The unique identifier of the check configuration
- settings: The approval settings including approvers, instructions, and definition reference
- timeout: The timeout value in minutes
- type: The type of check (Approval)
- resource: The resource details (type and id)
- createdBy: The ID of the user who created the check
- createdOn: The timestamp when the check was created
- project: The project name
- collectionUri: The collection URI

## NOTES

- When an approval check with the same configuration already exists, the existing check is returned with a warning
- Only 'environment' resource type is currently supported
- Requires an active Azure account login. Use `Connect-AzAccount` to authenticate:

  ```powershell
  Connect-AzAccount -Tenant '<tenant-id>' -Subscription '<subscription-id>'
  ```

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/add>
