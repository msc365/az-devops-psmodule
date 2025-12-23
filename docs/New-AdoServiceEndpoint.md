<!--
document type: cmdlet
external help file: Azure.DevOps.PSModule-Help.xml
HelpUri: https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/create?view=azure-devops
Locale: en-NL
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: New-AdoServiceEndpoint
-->

<!-- cSpell: ignore dontshow -->

# New-AdoServiceEndpoint

## SYNOPSIS

Create a new service endpoint in an Azure DevOps project.

## SYNTAX

### __AllParameterSets

```text
New-AdoServiceEndpoint [-Configuration] <string> [[-ApiVersion] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function creates a new service endpoint in an Azure DevOps project through REST API.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$config = [ordered]@{
    data                             = [ordered]@{
        creationMode     = 'Manual'
        environment      = 'AzureCloud'
        scopeLevel       = 'Subscription'
        subscriptionId   = '00000000-0000-0000-0000-000000000000'
        subscriptionName = 'sub-alz-workload-dev-weu'
        # scopeLevel          = 'ManagementGroup'
        # managementGroupId   = '11111111-1111-1111-1111-111111111111'
        # managementGroupName = 'Tenant Root Group'
    }
    name                             = 'id-msc-adortagnt-prd'
    type                             = 'AzureRM'
    url                              = '<https://management.azure.com/>'
    authorization                    = [ordered]@{
        parameters = [ordered]@{
            serviceprincipalid = '22222222-2222-2222-2222-222222222222'
            tenantid           = '11111111-1111-1111-1111-111111111111'
            scope              = '/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/rg-my-avengers-weu'
        }
        scheme     = 'WorkloadIdentityFederation'
    }
    isShared                         = $false
    serviceEndpointProjectReferences = @(
        [ordered]@{
            name             = 'id-msc-adortagnt-prd'
            projectReference = [ordered]@{
                id   = '33333333-3333-3333-3333-333333333333'
                name = 'my-project'
            }
        }
    )
} | ConvertTo-Json -Depth 4

New-AdoServiceEndpoint -Configuration $objConfig
```

This example demonstrates how to create a new Azure Resource Manager service endpoint in an Azure DevOps project using a configuration object.

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
  Position: 1
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
The configuration JSON for the service endpoint.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
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

The created service endpoint object.

## NOTES

- Requires an active connection to Azure DevOps using `Connect-AdoOrganization`.

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/create?view=azure-devops>
