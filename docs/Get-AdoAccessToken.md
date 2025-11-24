<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: ''
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Get-AdoAccessToken
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoAccessToken

## SYNOPSIS

Get secure access token for Azure DevOps service principal.

## SYNTAX

### __AllParameterSets

```text
Get-AdoAccessToken [[-TenantId] <string>] [<CommonParameters>]
```

## ALIASES

- N/A

## DESCRIPTION

The function gets an access token for the Azure DevOps service principal using the current Azure context or a specified tenant ID.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Get-AdoAccessToken
```

This example retrieves an access token for Azure DevOps using the tenant ID from the current Azure context.

### EXAMPLE 2

#### PowerShell

```powershell
Get-AdoAccessToken -TenantId "00000000-0000-0000-0000-000000000000"
```

This example retrieves an access token for Azure DevOps using the specified tenant ID.

## PARAMETERS

### -TenantId

The tenant ID to use for retrieving the access token.
If not specified, the tenant ID from the current Azure context is used.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
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

### System.Security.SecureString

## NOTES

Please make sure the context matches the current Azure environment.
You may refer to the value of `(Get-AzContext).Environment`.

## RELATED LINKS

- N/A
