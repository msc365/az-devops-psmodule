<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pushes/get
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 02/10/2026
PlatyPS schema version: 2024-05-01
title: New-AdoPushInitialCommit
-->

# New-AdoPushInitialCommit

## SYNOPSIS

Creates a new initial commit in a specified Azure DevOps repository.

## SYNTAX

### __AllParameterSets

```text
New-AdoPushInitialCommit [[-CollectionUri] <string>] [[-ProjectName] <string>]
 [-RepositoryName] <string> [[-BranchName] <string>] [[-Message] <string>] [[-Files] <Object[]>]
 [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This cmdlet allows you to create an initial commit in a specified Azure DevOps repository.
You can specify the content of the commit, the commit message, and the branch to which the commit will be pushed.

## EXAMPLES

### EXAMPLE 1

```powershell
$params = @{
    CollectionUri  = '<https://dev.azure.com/my-org>'
    ProjectName    = 'my-project-1'
    RepositoryName = 'my-repository-1'
    BranchName     = 'main'
    Message        = 'Initial commit'
    Files          = @(
        @{
            path        = '/README.md'
            content     = (Get-Content -Path 'C:/_tmp/README.md' -Raw)
            contentType = 'rawtext'
        },
        @{
            path        = '/devops/pipeline/ci.yml'
            content     = (Get-Content -Path 'C:/_tmp/ci.yml' -Raw)
            contentType = 'rawtext'
        },
        @{
            path        = '/.assets/tools.zip'
            content     = [Convert]::ToBase64String([IO.File]::ReadAllBytes('C:/_tmp/tools.zip'))
            contentType = 'base64encoded'
        }
    )
}
New-AdoPushInitialCommit @params
```

Creates a new initial commit with the specified content in the specified repository and branch.

## PARAMETERS

### -BranchName

Optional.
The name of the branch to which the initial commit will be pushed.
Default is 'main'.

```yaml
Type: System.String
DefaultValue: main
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -CollectionUri

Optional.
The collection URI of the Azure DevOps collection/organization, e.g., <https://dev.azure.com/my-org>.

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

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Files

Optional.
An array of file objects to include in the initial commit.
Each file object should have the following properties:
- path: The path to the file in the repository.
- content: The content of the file.
- contentType: The type of content ('rawtext' or 'base64encoded').

Default is a single file with path '/README.md' and content '# Initial Commit'.

```yaml
Type: System.Object[]
DefaultValue: >- 
  @(
    @{
      path        = '/README.md'
      content     = '# Initial Commit'
      contentType = 'rawtext'
    }
  )
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 5
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Message

Optional.
The commit message for the initial commit.
Default is 'Initial commit'.

```yaml
Type: System.String
DefaultValue: Initial commit
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ProjectName

Mandatory.
The ID or name of the project.

```yaml
Type: System.String
DefaultValue: $env:DefaultAdoProject
SupportsWildcards: false
Aliases:
- ProjectId
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -RepositoryName

Mandatory.
The name or ID of the repository.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- RepositoryId
ParameterSets:
- Name: (All)
  Position: 2
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
Default is '7.1'.

```yaml
Type: System.String
DefaultValue: 7.1
SupportsWildcards: false
Aliases:
- ApiVersion
ParameterSets:
- Name: (All)
  Position: 6
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
ParameterSets:
- Name: (All)
  Position: Named
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

### PSCustomObject

A custom object containing details about the push operation.

```text
[PSCustomObject]@{
    pushId        = The ID of the push operation.
    commits       = The commits included in the push.
    refUpdates    = The reference updates for the push.
    pushedBy      = The user who initiated the push.
    date          = The date and time of the push.
    projectName   = The name of the project.
    collectionUri = The URI of the Azure DevOps collection.
}
```

## NOTES
- N/A

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pushes/get>
