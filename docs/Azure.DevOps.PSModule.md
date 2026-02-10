<!--
document type: module
Help Version: 0.0.1
HelpInfoUri: 
Locale: en-US
Module Guid: 734c3172-da46-4f59-a2e8-0bc3eeaa27bb
Module Name: Azure.DevOps.PSModule
ms.date: 11/01/2025
PlatyPS schema version: 2024-05-01
title: Azure.DevOps.PSModule Module
-->

# Azure.DevOps.PSModule Module

This PowerShell module wraps the Azure DevOps REST API into clean, task-oriented cmdlets. It simplifies automation and scripting across your DevOps workflows, making it easier to manage pipelines, repositories, builds, releases, and work items directly from PowerShell.

## Index

| Command | Description |
| --- | --- |
| [Add-AdoGroupMember](Add-AdoGroupMember.md) | Adds an Entra ID group as member of a group. |
| [Add-AdoTeamIteration](Add-AdoTeamIteration.md) | Adds an iteration to a team in Azure DevOps. |
| [Get-AdoCheckConfiguration](Get-AdoCheckConfiguration.md) | Get check configurations for pipeline resources in Azure DevOps. |
| [Get-AdoClassificationNode](Get-AdoClassificationNode.md) | Gets classification nodes for a project in Azure DevOps. |
| [Get-AdoDefault](Get-AdoDefault.md) | Get default Azure DevOps environment variables. |
| [Get-AdoDescriptor](Get-AdoDescriptor.md) | Resolve a storage key to a descriptor. |
| [Get-AdoEnvironment](Get-AdoEnvironment.md) | Get a list of Azure DevOps Pipeline Environments with optional name filtering. |
| [Get-AdoFeatureState](Get-AdoFeatureState.md) | Get the feature states for an Azure DevOps project. |
| [Get-AdoGroup](Get-AdoGroup.md) | Get a single or multiple groups in an Azure DevOps organization. |
| [Get-AdoMembership](Get-AdoMembership.md) | Get the membership relationship between a subject and a container in Azure DevOps. |
| [Get-AdoPolicyConfiguration](Get-AdoPolicyConfiguration.md) | Gets policy configurations for an Azure DevOps project. |
| [Get-AdoPolicyType](Get-AdoPolicyType.md) | Retrieves Azure DevOps policy type details. |
| [Get-AdoProcess](Get-AdoProcess.md) | Get the process details. |
| [Get-AdoProject](Get-AdoProject.md) | Get project details with optional list and filter capabilities. |
| [Get-AdoRepository](Get-AdoRepository.md) | Get the repository. |
| [Get-AdoServiceEndpoint](Get-AdoServiceEndpoint.md) | Retrieves Azure DevOps service endpoint details by name. |
| [Get-AdoTeam](Get-AdoTeam.md) | Get teams or the team details for a given Azure DevOps project. |
| [Get-AdoTeamFieldValue](Get-AdoTeamFieldValue.md) | Gets the team field value settings for a team in an Azure DevOps project. |
| [Get-AdoTeamIteration](Get-AdoTeamIteration.md) | Retrieves Azure DevOps team iteration details. |
| [Get-AdoTeamSettings](Get-AdoTeamSettings.md) | Retrieves the settings for a team in an Azure DevOps project. |
| [Get-AdoUserEntitlement](Get-AdoUserEntitlement.md) | Get a paged set of user entitlements matching the filter criteria. |
| [New-AdoCheckApproval](New-AdoCheckApproval.md) | Create a new approval check for a specific resource. |
| [New-AdoCheckBranchControl](New-AdoCheckBranchControl.md) | Create a new branch control check for a specific resource. |
| [New-AdoCheckBusinessHours](New-AdoCheckBusinessHours.md) | Create a new business hours check for a specific resource. |
| [New-AdoCheckConfiguration](New-AdoCheckConfiguration.md) | Create a new check configuration for pipeline resources in Azure DevOps. |
| [New-AdoClassificationNode](New-AdoClassificationNode.md) | Creates a new classification node for a project in Azure DevOps. |
| [New-AdoEnvironment](New-AdoEnvironment.md) | Create a new Azure DevOps Pipeline Environment. |
| [New-AdoPolicyConfiguration](New-AdoPolicyConfiguration.md) | Create a new policy configuration for an Azure DevOps project. |
| [New-AdoProject](New-AdoProject.md) | Create a new project in an Azure DevOps organization. |
| [New-AdoPushInitialCommit](New-AdoPushInitialCommit.md) | Creates a new initial commit in a specified Azure DevOps repository. |
| [New-AdoRepository](New-AdoRepository.md) | Create a new repository in an Azure DevOps project. |
| [New-AdoServiceEndpoint](New-AdoServiceEndpoint.md) | Creates a new service endpoint in an Azure DevOps project. |
| [New-AdoTeam](New-AdoTeam.md) | Create a new team in an Azure DevOps project. |
| [Remove-AdoCheckConfiguration](Remove-AdoCheckConfiguration.md) | Remove a check configuration from pipeline resources in Azure DevOps. |
| [Remove-AdoClassificationNode](Remove-AdoClassificationNode.md) | Removes a classification node from a project in Azure DevOps. |
| [Remove-AdoDefault](Remove-AdoDefault.md) | Remove default Azure DevOps environment variables. |
| [Remove-AdoEnvironment](Remove-AdoEnvironment.md) | Remove an Azure DevOps Pipeline Environment by its ID. |
| [Remove-AdoProject](Remove-AdoProject.md) | Remove a project from an Azure DevOps organization. |
| [Remove-AdoRepository](Remove-AdoRepository.md) | Remove a repository from an Azure DevOps project. |
| [Remove-AdoServiceEndpoint](Remove-AdoServiceEndpoint.md) | Removes a service endpoint from Azure DevOps projects. |
| [Remove-AdoTeam](Remove-AdoTeam.md) | Remove a team from an Azure DevOps project. |
| [Resolve-AdoDefinitionRef](Resolve-AdoDefinitionRef.md) | Resolve a check definition reference by its name or ID. |
| [Set-AdoClassificationNode](Set-AdoClassificationNode.md) | Updates a classification node for a project in Azure DevOps. |
| [Set-AdoDefault](Set-AdoDefault.md) | Set default Azure DevOps environment variables. |
| [Set-AdoEnvironment](Set-AdoEnvironment.md) | Update an Azure DevOps Pipeline Environment by its ID. |
| [Set-AdoFeatureState](Set-AdoFeatureState.md) | Set the feature state for an Azure DevOps project feature. |
| [Set-AdoPolicyConfiguration](Set-AdoPolicyConfiguration.md) | Update a policy configuration for an Azure DevOps project. |
| [Set-AdoProject](Set-AdoProject.md) | Updates an existing Azure DevOps project through REST API. |
| [Set-AdoTeam](Set-AdoTeam.md) | Update a team in an Azure DevOps project. |
| [Set-AdoTeamFieldValue](Set-AdoTeamFieldValue.md) | Sets the team field value settings for a team in an Azure DevOps project. |
| [Set-AdoTeamSettings](Set-AdoTeamSettings.md) | Updates the settings for a team in Azure DevOps. |
