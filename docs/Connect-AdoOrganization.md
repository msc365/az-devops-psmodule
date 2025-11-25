<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: ''
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Connect-AdoOrganization
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Connect-AdoOrganization

## SYNOPSIS

Connect to an Azure DevOps organization.

## SYNTAX

### __AllParameterSets

```text
Connect-AdoOrganization [-Organization] <string> [[-PersonalAccessToken] <securestring>]
 [[-ApiVersion] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function connects to an Azure DevOps organization using a personal access token (PAT) or a service principal when no PAT is provided.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Connect-AdoOrganization -Organization 'my-org'
```

Connects to the specified Azure DevOps organization using a service principal.

### EXAMPLE 2

#### PowerShell

```powershell
Connect-AdoOrganization -Organization 'my-org' -PersonalAccessToken $PAT
```

Connects to the specified Azure DevOps organization using the provided personal access token (PAT).

## PARAMETERS

### -ApiVersion

Optional.
The API version to use.

```yaml
Type: System.String
DefaultValue: 7.1
SupportsWildcards: false
Aliases:
- Api
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Organization

Mandatory.
The name of the Azure DevOps organization.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Org
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

### -PersonalAccessToken

Optional.
The personal access token (PAT) to use for the authentication.
If not provided, the token is retrieved using Get-Token.

```yaml
Type: System.Security.SecureString
DefaultValue: ''
SupportsWildcards: false
Aliases:
- PAT
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

- N/A

## OUTPUTS

### System.String

A message indicating the connection status.

## NOTES

This function requires the Az.Accounts cmdlet.

## RELATED LINKS

- N/A
