<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/memberships/get
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Get-AdoMembership
-->

# Get-AdoMembership

## SYNOPSIS

Get membership relationships

## SYNTAX

### GetMembership

```text
Get-AdoMembership [[-CollectionUri] <string>] [-SubjectDescriptor] <string[]>
 [-ContainerDescriptor] <string> [[-Version] <string>] [<CommonParameters>]
```

### ListMemberships

```text
Get-AdoMembership [[-CollectionUri] <string>] [-SubjectDescriptor] <string[]>
 [[-Depth] <int32>] [[-Direction] <string>] [[-Version] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet retrieves the membership relationships between a specified subject and container in Azure DevOps or
get all the memberships where this descriptor is a member in the relationship.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri       = 'https://vssps.dev.azure.com/my-org'
    SubjectDescriptor   = 'aadgp.00000000-0000-0000-0000-000000000000'
    ContainerDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
}
Get-AdoMembership @params
```

Retrieves the membership relationship between the specified subject and container.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri       = 'https://vssps.dev.azure.com/my-org'
    ContainerDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
}
@('aadgp.00000000-0000-0000-0000-000000000002', 'aadgp.00000000-0000-0000-0000-000000000003') | Get-AdoMembership @params
```

Retrieves the membership relationships for multiple subjects demonstrating pipeline input.

### EXAMPLE 3

#### PowerShell

```powershell
$params = @{
    CollectionUri     = 'https://vssps.dev.azure.com/my-org'
    SubjectDescriptor = 'aadgp.00000000-0000-0000-0000-000000000000'
    Depth             = 2
    Direction         = 'up'
}
Get-AdoMembership @params
```

Retrieves all groups for a user with a depth of 2.

### EXAMPLE 4

#### PowerShell

```powershell
$params = @{
    CollectionUri     = 'https://vssps.dev.azure.com/my-org'
    SubjectDescriptor = 'aadgp.00000000-0000-0000-0000-000000000000'
    Depth             = 2
    Direction         = 'down'
}
Get-AdoMembership @params
```

Retrieves all memberships of a group with a depth of 2.

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
  Position: Named
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
A descriptor to the child subject in the relationship.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
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

### -ContainerDescriptor

Optional.
A descriptor to the container in the relationship.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: GetMembership
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Depth

Optional.
The depth of memberships to retrieve when ContainerDescriptor is not specified.
Default is 1.

```yaml
Type: System.Int32
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListMemberships
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Direction

Optional.
The direction of memberships to retrieve when ContainerDescriptor is not specified.

The default value for direction is 'up' meaning return all memberships where the subject is a member (e.g. all groups the subject is a member of).
Alternatively, passing the direction as 'down' will return all memberships where the subject is a container (e.g. all members of the subject group).

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ListMemberships
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- up
- down
HelpMessage: ''
```

### -Version

Optional.
The API version to use for the request.
Default is '7.1-preview.1'.

```yaml
Type: System.String
DefaultValue: 7.1-preview.1
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
- 7.1-preview.1
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

## NOTES

- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/memberships/get>
- <https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/memberships/list>
