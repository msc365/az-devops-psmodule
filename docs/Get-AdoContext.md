<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: ''
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Get-AdoContext
-->

<!-- cSpell: ignore hashtable dontshow -->

# Get-AdoContext

## SYNOPSIS

Get the current Azure DevOps connection context.

## SYNTAX

### __AllParameterSets

```text
Get-AdoContext [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function retrieves the current connection context for Azure DevOps, including the organization name and connection status.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Get-AdoContext
```

Retrieves the current Azure DevOps connection context.

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

- N/A

## OUTPUTS

### System.Collections.Hashtable

## NOTES

- Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.

## RELATED LINKS

- N/A
