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

## Description

A PowerShell module that wraps the Azure DevOps REST API into clean, task-oriented cmdlets. It simplifies automation and scripting across your DevOps workflows, making it easier to manage pipelines, repositories, builds, releases, and work items directly from PowerShell.

## Azure.DevOps.PSModule

<!-- prompt
1. Consolidated all commands into the table: Move all the commands that are listed with '###' headers into the main table starting at line 29.
2. Maintain proper formatting: Each command must be properly formatted as a table row with:
- The command name as a link in the first column
- The description in the second column
3. Remove redundant headers: All the '###' header sections must be removed, eliminate the duplication and make the documentation cleaner and more organized.
-->

| Command | Description |
| --- | --- |
| [Connect-AdoOrganization](Connect-AdoOrganization.md) | Connect to an Azure DevOps organization. |
| [Disconnect-AdoOrganization](Disconnect-AdoOrganization.md) | Disconnect from the Azure DevOps organization. |
| [Get-AdoAccessToken](Get-AdoAccessToken.md) | Get secure access token for Azure DevOps service principal. |
| [Get-AdoClassificationNode](Get-AdoClassificationNode.md) | Gets classification nodes for a project in Azure DevOps. |
| [Get-AdoContext](Get-AdoContext.md) | Get the current Azure DevOps connection context. |
| [Get-AdoDescriptor](Get-AdoDescriptor.md) | Resolve a storage key to a descriptor. |
| [Get-AdoFeatureState](Get-AdoFeatureState.md) | Get the feature states for an Azure DevOps project. |
| [Get-AdoGroupList](Get-AdoGroupList.md) | Get groups in an Azure DevOps organization. |
| [Get-AdoPolicyConfiguration](Get-AdoPolicyConfiguration.md) | Gets policy configurations for an Azure DevOps project. |
| [Get-AdoPolicyConfigurationList](Get-AdoPolicyConfigurationList.md) | Gets policy configurations for an Azure DevOps project. |
| [Get-AdoPolicyType](Get-AdoPolicyType.md) | Gets policy types for an Azure DevOps project. |
| [Get-AdoPolicyTypeList](Get-AdoPolicyTypeList.md) | Gets a list of policy types for an Azure DevOps project. |
| [Get-AdoProcess](Get-AdoProcess.md) | Get the process details. |
| [Get-AdoProject](Get-AdoProject.md) | Get project details. |
| [Get-AdoProjectList](Get-AdoProjectList.md) | Get all projects. |
| [Get-AdoRepository](Get-AdoRepository.md) | Get the repository. |
| [Get-AdoServiceEndpointByName](Get-AdoServiceEndpointByName.md) | Get the service endpoint details for an Azure DevOps service endpoint. |
| [Get-AdoTeam](Get-AdoTeam.md) | Get teams or the team details for a given Azure DevOps project. |
| [Get-AdoTeamFieldValue](Get-AdoTeamFieldValue.md) | Gets the team field value settings for a team in an Azure DevOps project. |
| [Get-AdoTeamList](Get-AdoTeamList.md) | Get all teams for a given Azure DevOps project. |
| [Get-AdoTeamSettings](Get-AdoTeamSettings.md) | Gets the settings for a team in an Azure DevOps project. |
| [New-AdoClassificationNode](New-AdoClassificationNode.md) | Creates a new classification node for a project in Azure DevOps. |
| [New-AdoGroup](New-AdoGroup.md) | Create a new group in Azure DevOps. |
| [New-AdoProject](New-AdoProject.md) | Create a new project in an Azure DevOps organization. |
| [New-AdoRepository](New-AdoRepository.md) | Create a new repository in an Azure DevOps project. |
| [New-AdoServiceEndpoint](New-AdoServiceEndpoint.md) | Create a new service endpoint in an Azure DevOps project. |
| [New-AdoTeam](New-AdoTeam.md) | Create a new team in an Azure DevOps project. |
| [Remove-AdoClassificationNode](Remove-AdoClassificationNode.md) | Removes a classification node from a project in Azure DevOps. |
| [Remove-AdoProject](Remove-AdoProject.md) | Remove a project from an Azure DevOps organization. |
| [Remove-AdoRepository](Remove-AdoRepository.md) | Remove a repository from an Azure DevOps project. |
| [Remove-AdoServiceEndpoint](Remove-AdoServiceEndpoint.md) | Remove a service endpoint from an Azure DevOps project. |
| [Remove-AdoTeam](Remove-AdoTeam.md) | Remove a team from an Azure DevOps project. |
| [Set-AdoClassificationNode](Set-AdoClassificationNode.md) | Updates a classification node for a project in Azure DevOps. |
| [Set-AdoFeatureState](Set-AdoFeatureState.md) | Set the feature state for an Azure DevOps project feature. |
| [Set-AdoPolicyConfiguration](Set-AdoPolicyConfiguration.md) | Update a policy configuration for an Azure DevOps project. |
| [Set-AdoProject](Set-AdoProject.md) | Updates an existing Azure DevOps project through REST API. |
| [Set-AdoTeam](Set-AdoTeam.md) | Update a team in an Azure DevOps project. |
| [Set-AdoTeamSettings](Set-AdoTeamSettings.md) | Update the settings for a team in Azure DevOps. |
