<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: ''
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Disconnect-AdoOrganization
-->

<!-- cSpell: ignore hashtable dontshow -->

# Disconnect-AdoOrganization

## SYNOPSIS

Disconnect from the Azure DevOps organization.

## SYNTAX

### __AllParameterSets

```text
Disconnect-AdoOrganization [<CommonParameters>]
```

## ALIASES

- N/A

## DESCRIPTION

This function removes global variables related to the Azure DevOps connection, effectively disconnecting the session from the specified organization.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Disconnect-AdoOrganization
```

This disconnects from the currently connected Azure DevOps organization by removing the relevant variables.

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

- N/A

## RELATED LINKS

- N/A

