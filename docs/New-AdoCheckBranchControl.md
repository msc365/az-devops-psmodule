<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/add
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/03/2026
PlatyPS schema version: 2024-05-01
title: New-AdoCheckBranchControl
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# New-AdoCheckBranchControl

## SYNOPSIS

Create a new branch control check for a specific resource.

## SYNTAX

### __AllParameterSets

```text
New-AdoCheckBranchControl [[-CollectionUri] <string>] [[-ProjectName] <string>]
 [[-DisplayName] <string>] [-ResourceType] <string> [-ResourceName] <string>
 [[-AllowedBranches] <string[]>] [[-EnsureProtectionOfBranch] <bool>]
 [[-AllowUnknownStatusBranches] <bool>] [[-Timeout] <int>] [[-Version] <string>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function creates a new branch control check for a specified resource within an Azure DevOps project.
Branch control checks ensure that deployments or operations only proceed from allowed branches.
When existing configuration is found with the same settings, it will be returned instead of creating a new one.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri                  = 'https://dev.azure.com/my-org'
    ProjectName                    = 'my-project-1'
    DisplayName                    = 'Branch Control'
    ResourceType                   = 'environment'
    ResourceName                   = 'my-environment-tst'
    AllowedBranches                = 'refs/heads/main', 'refs/heads/release/*'
    EnsureProtectionOfBranch       = $true
    AllowUnknownStatusBranches     = $false
    Timeout                        = 1440
}
New-AdoCheckBranchControl @params
```

Creates a new branch control check in the specified project using the provided parameters.

### EXAMPLE 2

#### PowerShell

```powershell
'my-environment-tst', 'my-environment-prd' | New-AdoCheckBranchControl -ResourceType 'environment' -AllowedBranches 'refs/heads/main'
```

Creates branch control checks for multiple environments using pipeline input.

### EXAMPLE 3

#### PowerShell

```powershell
$params = @{
    ResourceType               = 'environment'
    ResourceName               = 'my-environment'
    AllowedBranches            = 'refs/heads/main', 'refs/heads/develop'
    EnsureProtectionOfBranch   = $false
    AllowUnknownStatusBranches = $true
}
New-AdoCheckBranchControl @params
```

Creates a branch control check allowing multiple branches without enforcing branch protection.

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

### -DisplayName

Optional.
The name of the branch control check.
Default is 'Branch Control'.

```yaml
Type: System.String
DefaultValue: Branch Control
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

### -AllowedBranches

Optional.
A comma-separated list of allowed branches.
Default is 'refs/heads/main'.
Supports wildcards for branch patterns (e.g., 'refs/heads/release/*').

```yaml
Type: System.String[]
DefaultValue: refs/heads/main
SupportsWildcards: true
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

### -EnsureProtectionOfBranch

Optional.
Specifies whether to ensure the protection of the specified branches.
Default is $true.

```yaml
Type: System.Boolean
DefaultValue: True
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

### -AllowUnknownStatusBranches

Optional.
Specifies whether to allow branches with unknown status.
Default is $false.

```yaml
Type: System.Boolean
DefaultValue: False
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

Returns a custom object representing the branch control check configuration:
- id: The unique identifier of the check configuration
- settings: The branch control settings including display name, definition reference, and inputs
- timeout: The timeout value in minutes
- type: The type of check (Task Check)
- resource: The resource details (type and id)
- createdBy: The ID of the user who created the check
- createdOn: The timestamp when the check was created
- project: The project name
- collectionUri: The collection URI

## NOTES

- When a branch control check with the same configuration already exists, the existing check is returned with a warning
- Only 'environment' resource type is currently supported
- The check uses the 'evaluatebranchProtection' task definition
- Requires an active Azure account login. Use `Connect-AzAccount` to authenticate:

  ```powershell
  Connect-AzAccount -Tenant '<tenant-id>' -Subscription '<subscription-id>'
  ```

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/add>
