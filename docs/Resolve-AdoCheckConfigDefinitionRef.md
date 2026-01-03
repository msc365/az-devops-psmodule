<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri:
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/03/2026
PlatyPS schema version: 2024-05-01
title: Resolve-AdoCheckConfigDefinitionRef
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Resolve-AdoCheckConfigDefinitionRef

## SYNOPSIS

Resolve a check definition reference by its name or ID.

## SYNTAX

### ById

```text
Resolve-AdoCheckConfigDefinitionRef -Id <string> [<CommonParameters>]
```

### ByName

```text
Resolve-AdoCheckConfigDefinitionRef -Name <string> [<CommonParameters>]
```

### ListAll

```text
Resolve-AdoCheckConfigDefinitionRef -ListAll [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function resolves a check definition reference in Azure DevOps by either its name or ID. It returns the corresponding definition reference object with name, ID, and display name properties. The function uses a static mapping of Azure DevOps check definition types with IDs fixed by Azure DevOps.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Resolve-AdoCheckConfigDefinitionRef -Name 'approval'
```

Resolves the definition reference for the 'approval' check, returning the check definition with name, ID, and display name.

### EXAMPLE 2

#### PowerShell

```powershell
Resolve-AdoCheckConfigDefinitionRef -Id '26014962-64a0-49f4-885b-4b874119a5cc'
```

Resolves the definition reference for the check with the specified ID, returning the approval check definition.

### EXAMPLE 3

#### PowerShell

```powershell
Resolve-AdoCheckConfigDefinitionRef -ListAll
```

Returns all available check definition references sorted by name.

### EXAMPLE 4

#### PowerShell

```powershell
$checkDef = Resolve-AdoCheckConfigDefinitionRef -Name 'branchControl'
Write-Host "Check: $($checkDef.displayName) - $($checkDef.id)"
```

Resolves the branch control check definition and displays its display name and ID.

## PARAMETERS

### -Id

The ID of the check definition reference to resolve.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ById
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- 26014962-64a0-49f4-885b-4b874119a5cc
- 0f52a19b-c67e-468f-b8eb-0ae83b532c99
- 06441319-13fb-4756-b198-c2da116894a4
- 86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b
- 445fde2f-6c39-441c-807f-8a59ff2e075f
HelpMessage: ''
```

### -Name

The name of the check definition reference to resolve. Case-insensitive.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- approval
- preCheckApproval
- postCheckApproval
- branchControl
- businessHours
HelpMessage: ''
```

### -ListAll

Returns all available check definition references sorted by name.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListAll
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
Doname: The camelCase name of the check definition (e.g., 'approval', 'branchControl')
- displayName: The display name of the check definition (e.g., 'Approval', 'Branch control')
- id: The unique identifier GUID of the check definition

When using -ListAll, returns an array of all definition reference objects sorted by name.
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

Representing the check definition reference with the following properties:
- displayName: The display name of the check definition (e.g., 'Approval', 'Branch control')
- name: The camelCase name of the check definition (e.g., 'approval', 'branchControl')
- id: The unique identifier GUID of the check definition

## NOTES

- This function uses a static mapping of Azure DevOps check definition types
- The IDs are fixed and defined by Azure DevOps
- Supported check definitions:
  - Approval (26014962-64a0-49f4-885b-4b874119a5cc)
  - Pre-check approval (0f52a19b-c67e-468f-b8eb-0ae83b532c99)
  - Post-check approval (06441319-13fb-4756-b198-c2da116894a4)
  - Branch control (86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b)
  - Business hours (445fde2f-6c39-441c-807f-8a59ff2e075f)

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/>
