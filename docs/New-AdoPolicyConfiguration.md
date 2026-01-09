<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/configurations/create
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 01/05/2026
PlatyPS schema version: 2024-05-01
title: New-AdoPolicyConfiguration
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# New-AdoPolicyConfiguration

## SYNOPSIS

Create a new policy configuration for an Azure DevOps project.

## SYNTAX

### __AllParameterSets

```text
New-AdoPolicyConfiguration [[-CollectionUri] <string>] [[-ProjectName] <string>] [-Configuration] <PSCustomObject> [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet creates a new policy configuration for an Azure DevOps project. The configuration must be provided as a PSCustomObject or hashtable containing all required policy settings.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
}

$config = [PSCustomObject]@{
    isEnabled = $true
    isBlocking = $true
    type = @{
        id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
    }
    settings = @{
        minimumApproverCount = 1
        creatorVoteCounts = $true
        allowDownvotes = $false
        resetOnSourcePush = $false
        requireVoteOnLastIteration = $false
        resetRejectionsOnSourcePush = $false
        blockLastPusherVote = $false
        requireVoteOnEachIteration = $false
        scope = @(
            @{
                repositoryId = $null
                refName = $null
                matchKind = 'DefaultBranch'
            }
        )
    }
}

New-AdoPolicyConfiguration @params -Configuration $config
```

Creates a new minimum approver count policy configuration in the specified project.

## PARAMETERS

### -CollectionUri

The collection URI of the Azure DevOps collection/organization, e.g., <https://dev.azure.com/my-org>.
Defaults to $env:DefaultAdoCollectionUri.

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

### -ProjectName

The ID or name of the project.
Defaults to $env:DefaultAdoProject.

```yaml
Type: System.String
DefaultValue: $env:DefaultAdoProject
SupportsWildcards: false
Aliases:
- ProjectId
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

### -Configuration

The configuration object for the policy as a PSCustomObject. Must include the policy type ID and all required settings.

```yaml
Type: PSCustomObject
DefaultValue: 
SupportsWildcards: false
Aliases: []
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

### -Version

The API version to use for the request.

```yaml
Type: System.String
DefaultValue: 7.1
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
- 7.1
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

Returns the created policy configuration object with the following properties:
- id: The unique identifier of the created policy configuration
- type: The policy type object containing the type ID
- revision: The revision number of the configuration
- isEnabled: Whether the policy is enabled
- isBlocking: Whether the policy is blocking
- isDeleted: Whether the policy is deleted
- settings: The policy-specific settings object
- createdBy: The user who created the configuration
- createdDate: The date the configuration was created
- projectName: The project name where the configuration was created
- collectionUri: The collection URI of the Azure DevOps organization

## NOTES

- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.

- If a policy configuration with the same settings already exists, a warning is displayed and the cmdlet continues execution.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/configurations/create>
