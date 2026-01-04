<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: 
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 12/31/2025
PlatyPS schema version: 2024-05-01
title: Set-AdoDefault
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Set-AdoDefault

## SYNOPSIS

Set default Azure DevOps environment variables.

## SYNTAX

### __AllParameterSets

```text
Set-AdoDefault [-Organization] <string> [[-Project] <string>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function sets the default Azure DevOps environment variables for the current session.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Set-AdoDefault -Organization 'my-org' -Project 'my-project-1'
```

Sets the default Azure DevOps organization to 'my-org', CollectionUri to "<https://dev.azure.com/my-org>", and Project to 'my-project-1'.

## PARAMETERS

### -Organization

Mandatory.
The name of the Azure DevOps organization.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Project

Optional.
The name of the Azure DevOps project.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Shows what would happen if the cmdlet runs. The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
Aliases: wi
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
Aliases: cf
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

Returns an object with the following properties:
- Organization: The default Azure DevOps organization name
- CollectionUri: The default Azure DevOps collection URI
- ProjectName: The default Azure DevOps project name

## NOTES

This function sets environment variables for the current session only. These defaults are used by other cmdlets in the module when parameters are not explicitly provided.

## RELATED LINKS

- [Get-AdoDefault](Get-AdoDefault.md)
- [Remove-AdoDefault](Remove-AdoDefault.md)
