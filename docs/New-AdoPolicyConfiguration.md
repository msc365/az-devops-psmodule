<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/configurations/create?view=azure-devops
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: New-AdoPolicyConfiguration
-->

# New-AdoPolicyConfiguration

## SYNOPSIS

Create a new policy configuration for an Azure DevOps project.

## SYNTAX

### __AllParameterSets

```text
New-AdoPolicyConfiguration [-ProjectId] <string> [-Configuration] <string> [[-ApiVersion] <string>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function creates a new policy configuration for an Azure DevOps project through REST API.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$config = @{
    "isEnabled": true,
    "isBlocking": true,
    "type": @{
        "id": "fa4e907d-c16b-4a4c-9dfa-4906e5d171dd"
    },
    "settings": @{
        "minimumApproverCount": 1,
        "creatorVoteCounts": true,
        "allowDownvotes": false,
        "resetOnSourcePush": false,
        "requireVoteOnLastIteration": false,
        "resetRejectionsOnSourcePush": false,
        "blockLastPusherVote": false,
        "requireVoteOnEachIteration": false,
        "scope": @(
            {
                "repositoryId": null,
                "refName": null,
                "matchKind": "DefaultBranch"
            }
        )
    }
} | ConvertTo-Json -Depth 5 -Compress

$policy = New-AdoPolicyConfiguration -ProjectName 'my-project' -Configuration $config
```

## PARAMETERS

### -ApiVersion

Optional.
The API version to use.

```yaml
Type: System.String
DefaultValue: 7.1
SupportsWildcards: false
Aliases:
- api
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

### -Configuration

Mandatory.
The configuration JSON for the policy.

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
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ProjectId

Mandatory.
The ID or name of the project.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- ProjectName
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

- N/A

## OUTPUTS

### System.Object

The created policy configuration object.

## NOTES

- Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/configurations/create?view=azure-devops>
