<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: ''
Locale: nl-NL
Module Name: Azure.DevOps.PSModule
ms.date: 02-22-2026
PlatyPS schema version: 2024-05-01
title: Get-AdoStorageKey
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# Get-AdoStorageKey

## SYNOPSIS

Resolve a descriptor to a storage key in an Azure DevOps organization.

## SYNTAX

### __AllParameterSets

```powershell
Get-AdoStorageKey [[-CollectionUri] <string>] [-SubjectDescriptor] <string> [[-Version] <string>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function resolve a descriptor to a storage key in an Azure DevOps organization through REST API.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
Get-AdoStorageKey -SubjectDescriptor 'aad.00000000-0000-0000-0000-000000000000'
```

Resolve a descriptor to a storage key using the default collection URI from environment variable.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri     = 'https://dev.azure.com/my-org'
    SubjectDescriptor = 'aad.00000000-0000-0000-0000-000000000000'
}
Get-AdoStorageKey @params
```

Resolve a descriptor to a storage key.

### EXAMPLE 3

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
}
@(
    'aad.00000000-0000-0000-0000-000000000001',
    'aad.00000000-0000-0000-0000-000000000002'
) | Get-AdoStorageKey @params
```

Resolves multiple descriptors to their corresponding storage keys, demonstrating pipeline input.

## PARAMETERS

### -CollectionUri

Optional.
The collection URI of the Azure DevOps collection/organization, e.g., <https://vssps.dev.azure.com/my-org>.

```yaml
Type: System.String
DefaultValue: $env:DefaultAdoCollectionUri
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -SubjectDescriptor

Mandatory.
The descriptor of the Graph entity to resolve.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Version

The API version to use.
Default is '7.2-preview.1'.
The -preview flag must be supplied in the api-version for this request to work.

```yaml
Type: System.String
DefaultValue: 7.2-preview.1
SupportsWildcards: false
Aliases:
- ApiVersion
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- '7.1'
- '7.2-preview.1'
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

### PSCustomObject

## NOTES

- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/storage-keys/get>
