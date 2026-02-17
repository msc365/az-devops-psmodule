<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/add
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 02/13/2026
PlatyPS schema version: 2024-05-01
title: New-AdoCheckBusinessHours
-->

<!-- markdownlint-disable MD024 -->
<!-- cSpell: ignore dontshow -->

# New-AdoCheckBusinessHours

## SYNOPSIS

Create a new business hours check for a specific resource.

## SYNTAX

### ByResourceName

```text
New-AdoCheckBusinessHours -ResourceType <string> -ResourceName <string>
 [[-CollectionUri] <string>] [[-ProjectName] <string>] [[-DisplayName] <string>]
 [[-BusinessDays] <string[]>] [[-TimeZone] <string>] [[-StartTime] <string>]
 [[-EndTime] <string>] [[-Timeout] <int>] [[-Version] <string>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByResourceId

```text
New-AdoCheckBusinessHours -ResourceType <string> -ResourceId <string>
 [[-CollectionUri] <string>] [[-ProjectName] <string>] [[-DisplayName] <string>]
 [[-BusinessDays] <string[]>] [[-TimeZone] <string>] [[-StartTime] <string>]
 [[-EndTime] <string>] [[-Timeout] <int>] [[-Version] <string>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function creates a new business hours check for a specified resource within an Azure DevOps project.
When existing configuration is found, it will be returned instead of creating a new one.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    DisplayName   = 'Business Hours'
    ResourceType  = 'environment'
    ResourceName  = 'my-environment-tst'
    BusinessDays  = @('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
    TimeZone      = 'UTC'
    StartTime     = '04:00'
    EndTime       = '11:00'
    Timeout       = 1440
}
New-AdoCheckBusinessHours @params
```

Creates a new business hours check for the specified environment name with default parameters.

### EXAMPLE 2

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'my-project-1'
    DisplayName   = 'Business Hours'
    ResourceType  = 'environment'
    ResourceId    = '00000000-0000-0000-0000-000000000100'
    BusinessDays  = @('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
    TimeZone      = 'UTC'
    StartTime     = '04:00'
    EndTime       = '11:00'
    Timeout       = 1440
}
New-AdoCheckBusinessHours @params
```

Creates a new business hours check for the specified environment ID with default parameters.

## PARAMETERS

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

Optional.
The name or id of the project.

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

### -DisplayName

Optional.
The name of the business hours check.
Default is 'Business Hours'.

```yaml
Type: System.String
DefaultValue: Business Hours
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

### -ResourceId

Mandatory.
The ID of the resource to which the check will be applied.
If not provided, the function will attempt to resolve the ID based on the ResourceType and ResourceName.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByResourceId
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ResourceName

Mandatory.
The name of the resource to which the check will be applied.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByResourceName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ResourceType

Mandatory.
The type of resource to which the check will be applied.
Valid values are 'endpoint', 'environment', 'variablegroup', 'repository'.

```yaml
Type: System.String
DefaultValue: ''
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
AcceptedValues:
- endpoint
- environment
- variablegroup
- repository
HelpMessage: ''
```

### -BusinessDays

Optional.
An array of business days.
Valid values are 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'.
Default is Monday to Friday.

```yaml
Type: System.String[]
DefaultValue: "@('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')"
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- Monday
- Tuesday
- Wednesday
- Thursday
- Friday
- Saturday
- Sunday
HelpMessage: ''
```

### -TimeZone

Optional.
The time zone for the business hours as Windows Standard Time Zone IDs.
Default is 'UTC'.

To see the list of valid time zone IDs, run the following command:
[System.TimeZoneInfo]::GetSystemTimeZones() | Select-Object -ExpandProperty Id | Out-String

```yaml
Type: System.String
DefaultValue: UTC
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
AcceptedValues:
- Afghanistan Standard Time
- Alaskan Standard Time
- Aleutian Standard Time
- Arab Standard Time
- Arabian Standard Time
- Atlantic Standard Time
- AUS Central Standard Time
- AUS Eastern Standard Time
- Central America Standard Time
- Central Asia Standard Time
- Central Europe Standard Time
- Central European Standard Time
- Central Pacific Standard Time
- Central Standard Time
- Central Standard Time (Mexico)
- China Standard Time
- E. Africa Standard Time
- E. Australia Standard Time
- E. Europe Standard Time
- E. South America Standard Time
- Eastern Standard Time
- Eastern Standard Time (Mexico)
- Egypt Standard Time
- FLE Standard Time
- GMT Standard Time
- Greenwich Standard Time
- GTB Standard Time
- Hawaiian Standard Time
- India Standard Time
- Iran Standard Time
- Israel Standard Time
- Jordan Standard Time
- Korea Standard Time
- Mountain Standard Time
- Mountain Standard Time (Mexico)
- New Zealand Standard Time
- Pacific SA Standard Time
- Pacific Standard Time
- Pacific Standard Time (Mexico)
- Romance Standard Time
- Russian Standard Time
- SA Pacific Standard Time
- SE Asia Standard Time
- Singapore Standard Time
- Tokyo Standard Time
- US Eastern Standard Time
- US Mountain Standard Time
- UTC
- UTC+12
- UTC+13
- UTC-02
- UTC-08
- UTC-09
- UTC-11
- W. Australia Standard Time
- W. Central Africa Standard Time
- W. Europe Standard Time
- West Asia Standard Time
HelpMessage: ''
```

### -StartTime

Optional.
The start time for business hours in HH:mm format.
Default is '04:00'.

```yaml
Type: System.String
DefaultValue: 04:00
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

### -EndTime

Optional.
The end time for business hours in HH:mm format.
Default is '11:00'.

```yaml
Type: System.String
DefaultValue: 11:00
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

### -Timeout

Optional.
The timeout in minutes for the approval check.
Default is 1440 (1 day).

```yaml
Type: System.Int32
DefaultValue: 1440
SupportsWildcards: false
Aliases: []
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

### -Version

Optional.
The API version to use for the request.
Default is '7.2-preview.1'.
The -preview flag must be supplied in the api-version for such requests.

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
- 7.1-preview.1
- 7.2-preview.1
HelpMessage: The -preview flag must be supplied in the api-version for such requests.
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

- When a business hours check with the same configuration already exists, the existing check is returned with a warning
- Only 'environment' resource type is currently supported
- The check uses the 'evaluateBusinessHours' task definition
- The retry interval is automatically set to 5 minutes
- Requires authentication to Azure DevOps. Use `Set-AdoDefault` to configure default organization and project values.
- The cmdlet automatically retrieves authentication through `Invoke-AdoRestMethod` which calls `New-AdoAuthHeader`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/add>
