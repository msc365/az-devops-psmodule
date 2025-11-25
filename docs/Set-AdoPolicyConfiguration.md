<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/configurations/update?view=azure-devops
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Set-AdoPolicyConfiguration
-->

<!-- cSpell: ignore dontshow -->

# Set-AdoPolicyConfiguration

## SYNOPSIS

Update a policy configuration for an Azure DevOps project.

## SYNTAX

### __AllParameterSets

```text
Set-AdoPolicyConfiguration [-ProjectId] <string> [-ConfigurationId] <int> [-Configuration] <Object>
 [[-ApiVersion] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function updates a policy configuration for an Azure DevOps project through REST API.

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
  }

Set-AdoPolicyConfiguration -ProjectName 'my-project' -ConfigurationId 24 -Configuration $config
```

Sets the policy configuration with ID 24 in the 'my-project' project using the specified configuration.

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
  Position: 3
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
The configuration object for the policy.

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ConfigurationId

Mandatory.
The ID of the configuration.

```yaml
Type: System.Int32
DefaultValue: 0
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

### System.String

## NOTES

- The configuration object should be a valid JSON object.
- Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/configurations/update?view=azure-devops>
