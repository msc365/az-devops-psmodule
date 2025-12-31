<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/create
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: New-AdoGroup
-->

<!-- cSpell: ignore dontshow -->

# New-AdoGroup

## SYNOPSIS

Adds an AAD Group as member of a group.

## SYNTAX

### __AllParameterSets

```text
New-AdoGroup [[-CollectionUri] <string>] [-GroupDescriptor] <string> [-GroupId] <string[]>
 [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- Descriptor (for GroupDescriptor)
- OriginId (for GroupId)

## DESCRIPTION

This cmdlet adds an AAD Group as member of a group in Azure DevOps.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri   = 'https://vssps.dev.azure.com/my-org'
    GroupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000000'
    GroupId         = '00000000-0000-0000-0000-000000000000'
}
New-AdoGroup @params
```

Adds an AAD Group as member of a group.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri   = 'https://vssps.dev.azure.com/my-org'
    GroupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000000'
}
@('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002') | New-AdoGroup @params
```

Adds multiple AAD Groups as members demonstrating pipeline input.

## PARAMETERS

### -CollectionUri

Optional.
The collection URI of the Azure DevOps collection/organization, e.g., <https://vssps.dev.azure.com/myorganization>.

```yaml
Type: System.String
DefaultValue: ($env:DefaultAdoCollectionUri -replace 'https://', 'https://vssps.')
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

### -GroupDescriptor

Mandatory.
A comma separated list of descriptors referencing groups you want the graph group to join.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Descriptor
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -GroupId

Mandatory.
The OriginId of the entra group to add as a member.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- OriginId
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

### -Version

Optional.
The API version to use for the request.
Default is '7.2-preview.1'.

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
- 7.2-preview.1
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

An object representing the added group.

## NOTES

- Requires an active Azure account login. Use `Connect-AzAccount` to authenticate:

  ```powershell
  Connect-AzAccount -Tenant '<tenant-id>' -Subscription '<subscription-id>'
  ```

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/create>
