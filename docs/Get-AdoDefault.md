<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: 
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 12/31/2025
PlatyPS schema version: 2024-05-01
title: Get-AdoDefault
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoDefault

## SYNOPSIS

Get default Azure DevOps environment variables.

## SYNTAX

### __AllParameterSets

```text
Get-AdoDefault [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function gets the default Azure DevOps environment variables from the current session.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Get-AdoDefault
```

Gets the default Azure DevOps organization and project context.

## PARAMETERS

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

This function retrieves the default values from session environment variables set by Set-AdoDefault.

## RELATED LINKS

- [Set-AdoDefault](Set-AdoDefault.md)
- [Remove-AdoDefault](Remove-AdoDefault.md)
