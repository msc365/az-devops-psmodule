<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: 
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 12/31/2025
PlatyPS schema version: 2024-05-01
title: Remove-AdoDefault
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Remove-AdoDefault

## SYNOPSIS

Remove default Azure DevOps environment variables.

## SYNTAX

### __AllParameterSets

```text
Remove-AdoDefault [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function removes the default Azure DevOps environment variables from the current session.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Remove-AdoDefault
```

Removes the default Azure DevOps environment variables from the current session.

## PARAMETERS

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

- N/A

## NOTES

This function clears the environment variables set by Set-AdoDefault from the current session.

## RELATED LINKS

- [Get-AdoDefault](Get-AdoDefault.md)
- [Set-AdoDefault](Set-AdoDefault.md)
