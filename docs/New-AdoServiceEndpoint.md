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

Creates a new Azure DevOps service endpoint (service connection).

## SYNTAX

### __AllParameterSets

```text
New-AdoServiceEndpoint [[-CollectionUri] <string>] [-Configuration] <PSCustomObject>
 [[-Version] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
- N/A

## DESCRIPTION

This function creates a new service endpoint (service connection) in an Azure DevOps project. The endpoint is created using a configuration object that defines the endpoint type, authorization, and project references. If a service endpoint with the same name already exists, the cmdlet retrieves and returns the existing endpoint.

## EXAMPLES

### EXAMPLE 1

#### PowerShell

```powershell
$config = [PSCustomObject]@{
    data = [PSCustomObject]@{
        creationMode = 'Manual'
        environment = 'AzureCloud'
        scopeLevel = 'Subscription'
        subscriptionId = '00000000-0000-0000-0000-000000000000'
        subscriptionName = 'my-subscription-1'
    }
    name = 'MyAzureConnection'
    type = 'AzureRM'
    url = 'https://management.azure.com/'
    authorization = [PSCustomObject]@{
        parameters = [PSCustomObject]@{
            serviceprincipalid = '11111111-1111-1111-1111-111111111111'
            tenantid = '22222222-2222-2222-2222-222222222222'
            scope = '/subscriptions/00000000-0000-0000-0000-000000000000'
        }
        scheme = 'WorkloadIdentityFederation'
    }
    isShared = $false
    serviceEndpointProjectReferences = [PSCustomObject[]]@(
        [PSCustomObject]@{
            name = 'MyAzureConnection'
            projectReference = [PSCustomObject]@{
                id = '33333333-3333-3333-3333-333333333333'
                name = 'my-project-1'
            }
        }
    )
}

$params = @{
    CollectionUri = 'https://dev.azure.com/myorg'
    Configuration = $config
}
New-AdoServiceEndpoint @params
```

Creates a new Azure Resource Manager service endpoint with Workload Identity Federation authentication.

### EXAMPLE 2

#### PowerShell

```powershell
$config = [PSCustomObject]@{
    name = 'MyGitHubConnection'
    type = 'GitHub'
    url = 'https://github.com'
    authorization = [PSCustomObject]@{
        parameters = [PSCustomObject]@{
            accessToken = 'ghp_token'
        }
        scheme = 'Token'
    }
    isShared = $false
    serviceEndpointProjectReferences = [PSCustomObject[]]@(
        [PSCustomObject]@{
            name = 'MyGitHubConnection'
            projectReference = [PSCustomObject]@{
                id = '33333333-3333-3333-3333-333333333333'
                name = 'my-project-1'
            }
        }
    )
}

New-AdoServiceEndpoint -Configuration $config
```

Creates a new GitHub service endpoint using a personal access token.

## PARAMETERS

### -CollectionUri

Optional. The URI of the Azure DevOps collection or Azure DevOps Server. If not provided, it uses the default collection URI from $env:DefaultAdoCollectionUri.

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
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Configuration

Mandatory. The service endpoint configuration object containing endpoint details, authorization, and project references.

```yaml
Type: System.Management.Automation.PSCustomObject
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

### -Version

Optional. The API version to use. Defaults to '7.1'.

```yaml
Type: System.String
DefaultValue: 7.1
SupportsWildcards: false
Aliases:
- ApiVersion
- Api
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- 7.1
- 7.2-preview.4
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

Service endpoint object with the following properties:
- id: The unique identifier of the service endpoint
- name: The name of the service endpoint
- type: The type of service endpoint (e.g., AzureRM, GitHub, Docker)
- description: The description of the service endpoint
- authorization: Authorization details including scheme and parameters
- url: The URL of the service endpoint
- isShared: Whether the endpoint is shared across projects
- isReady: Whether the endpoint is ready for use
- owner: The owner of the endpoint (library or agentcloud)
- data: Additional data associated with the endpoint
- serviceEndpointProjectReferences: Project references for the endpoint
- projectName: The project name extracted from configuration
- collectionUri: The collection URI

## NOTES

- The cmdlet extracts the project name from Configuration.serviceEndpointProjectReferences[0].projectReference.name.
- If a service endpoint with the same name already exists, the cmdlet returns the existing endpoint with a warning.
- The API call is made to the organization level endpoint (without project in the URI path).
- Supports ShouldProcess for WhatIf and Confirm parameters (high impact).
- Requires an active Azure account login. Use `Connect-AzAccount` to authenticate:

  ```powershell
  Connect-AzAccount -Tenant '<tenant-id>' -Subscription '<subscription-id>'
  ```

## RELATED LINKS

- <https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/create>
