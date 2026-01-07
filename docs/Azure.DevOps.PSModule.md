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

| Command | Description |
| --- | --- |
| **Connection and Authentication** | |
| &nbsp; • &nbsp; [Connect-AdoOrganization](Connect-AdoOrganization.md) | Connect to an Azure DevOps organization. |
| &nbsp; • &nbsp; [Disconnect-AdoOrganization](Disconnect-AdoOrganization.md) | Disconnect from the Azure DevOps organization. |
| &nbsp; • &nbsp; [Get-AdoAccessToken](Get-AdoAccessToken.md) | Get secure access token for Azure DevOps service principal. |
| &nbsp; • &nbsp; [Get-AdoContext](Get-AdoContext.md) | Get the current Azure DevOps connection context. |
| **Default Context** | |
| &nbsp; • &nbsp; [Get-AdoDefault](Get-AdoDefault.md) | Get default Azure DevOps environment variables. |
| &nbsp; • &nbsp; [Set-AdoDefault](Set-AdoDefault.md) | Set default Azure DevOps environment variables. |
| &nbsp; • &nbsp; [Remove-AdoDefault](Remove-AdoDefault.md) | Remove default Azure DevOps environment variables. |
| **Features** | |
| &nbsp; • &nbsp; [Get-AdoFeatureState](Get-AdoFeatureState.md) | Get the feature states for an Azure DevOps project. |
| &nbsp; • &nbsp; [Set-AdoFeatureState](Set-AdoFeatureState.md) | Set the feature state for an Azure DevOps project feature. |
| **Groups and Security** | |
| &nbsp; • &nbsp; [Get-AdoGroup](Get-AdoGroup.md) | Get a single or multiple groups in an Azure DevOps organization. |
| &nbsp; • &nbsp; [Add-AdoGroupMember](Add-AdoGroupMember.md) | Adds an Entra ID group as member of a group. |
| &nbsp; • &nbsp; [Get-AdoMembership](Get-AdoMembership.md) | Get the membership relationship between a subject and a container in Azure DevOps. |
| &nbsp; • &nbsp; [Get-AdoDescriptor](Get-AdoDescriptor.md) | Resolve a storage key to a descriptor. |
| **Approvals And Checks** | |
| &nbsp; • &nbsp; [Get-AdoCheckConfiguration](Get-AdoCheckConfiguration.md) | Get check configurations for pipeline resources in Azure DevOps. |
| &nbsp; • &nbsp; [New-AdoCheckConfiguration](New-AdoCheckConfiguration.md) | Create a new check configuration for pipeline resources in Azure DevOps. |
| &nbsp; • &nbsp; [Remove-AdoCheckConfiguration](Remove-AdoCheckConfiguration.md) | Remove a check configuration from pipeline resources in Azure DevOps. |
| &nbsp; • &nbsp; [New-AdoCheckApproval](New-AdoCheckApproval.md) | Create a new approval check for a specific resource. |
| &nbsp; • &nbsp; [New-AdoCheckBranchControl](New-AdoCheckBranchControl.md) | Create a new branch control check for a specific resource. |
| &nbsp; • &nbsp; [New-AdoCheckBusinessHours](New-AdoCheckBusinessHours.md) | Create a new business hours check for a specific resource. |
| &nbsp; • &nbsp; [Resolve-AdoCheckConfigDefinitionRef](Resolve-AdoCheckConfigDefinitionRef.md) | Resolve a check definition reference by its name or ID. |
| **Environments** | |
| &nbsp; • &nbsp; [Get-AdoEnvironment](Get-AdoEnvironment.md) | Get a list of Azure DevOps Pipeline Environments with optional name filtering. |
| &nbsp; • &nbsp; [New-AdoEnvironment](New-AdoEnvironment.md) | Create a new Azure DevOps Pipeline Environment. |
| &nbsp; • &nbsp; [Set-AdoEnvironment](Set-AdoEnvironment.md) | Update an Azure DevOps Pipeline Environment by its ID. |
| &nbsp; • &nbsp; [Remove-AdoEnvironment](Remove-AdoEnvironment.md) | Remove an Azure DevOps Pipeline Environment by its ID. |
| **Policies** | |
| &nbsp; • &nbsp; [Get-AdoPolicyConfiguration](Get-AdoPolicyConfiguration.md) | Gets policy configurations for an Azure DevOps project. |
| &nbsp; • &nbsp; [New-AdoPolicyConfiguration](New-AdoPolicyConfiguration.md) | Create a new policy configuration for an Azure DevOps project. |
| &nbsp; • &nbsp; [Set-AdoPolicyConfiguration](Set-AdoPolicyConfiguration.md) | Update a policy configuration for an Azure DevOps project. |
| &nbsp; • &nbsp; [Get-AdoPolicyType](Get-AdoPolicyType.md) | Retrieves Azure DevOps policy type details. |
| **Projects and Process** | |
| &nbsp; • &nbsp; [Get-AdoProject](Get-AdoProject.md) | Get project details with optional list and filter capabilities. |
| &nbsp; • &nbsp; [New-AdoProject](New-AdoProject.md) | Create a new project in an Azure DevOps organization. |
| &nbsp; • &nbsp; [Set-AdoProject](Set-AdoProject.md) | Updates an existing Azure DevOps project through REST API. |
| &nbsp; • &nbsp; [Remove-AdoProject](Remove-AdoProject.md) | Remove a project from an Azure DevOps organization. |
| &nbsp; • &nbsp; [Get-AdoProcess](Get-AdoProcess.md) | Get the process details. |
| **Repositories** | |
| &nbsp; • &nbsp; [Get-AdoRepository](Get-AdoRepository.md) | Get the repository. |
| &nbsp; • &nbsp; [New-AdoRepository](New-AdoRepository.md) | Create a new repository in an Azure DevOps project. |
| &nbsp; • &nbsp; [Remove-AdoRepository](Remove-AdoRepository.md) | Remove a repository from an Azure DevOps project. |
| **Service Endpoints** | |
| &nbsp; • &nbsp; [Get-AdoServiceEndpoint](Get-AdoServiceEndpoint.md) | Retrieves Azure DevOps service endpoint details by name. |
| &nbsp; • &nbsp; [New-AdoServiceEndpoint](New-AdoServiceEndpoint.md) | Creates a new service endpoint in an Azure DevOps project. |
| &nbsp; • &nbsp; [Remove-AdoServiceEndpoint](Remove-AdoServiceEndpoint.md) | Removes a service endpoint from Azure DevOps projects. |
| **Teams** | |
| &nbsp; • &nbsp; [Get-AdoTeam](Get-AdoTeam.md) | Get teams or the team details for a given Azure DevOps project. |
| &nbsp; • &nbsp; [New-AdoTeam](New-AdoTeam.md) | Create a new team in an Azure DevOps project. |
| &nbsp; • &nbsp; [Set-AdoTeam](Set-AdoTeam.md) | Update a team in an Azure DevOps project. |
| &nbsp; • &nbsp; [Remove-AdoTeam](Remove-AdoTeam.md) | Remove a team from an Azure DevOps project. |
| &nbsp; • &nbsp; [Get-AdoTeamSettings](Get-AdoTeamSettings.md) | Retrieves the settings for a team in an Azure DevOps project. |
| &nbsp; • &nbsp; [Set-AdoTeamSettings](Set-AdoTeamSettings.md) | Updates the settings for a team in Azure DevOps. |
| &nbsp; • &nbsp; [Add-AdoTeamIteration](Add-AdoTeamIteration.md) | Adds an iteration to a team in Azure DevOps. |
| &nbsp; • &nbsp; [Get-AdoTeamIteration](Get-AdoTeamIteration.md) | Retrieves Azure DevOps team iteration details. |
| &nbsp; • &nbsp; [Get-AdoTeamFieldValue](Get-AdoTeamFieldValue.md) | Gets the team field value settings for a team in an Azure DevOps project. |
| &nbsp; • &nbsp; [Set-AdoTeamFieldValue](Set-AdoTeamFieldValue.md) | Sets the team field value settings for a team in an Azure DevOps project. |
| **Work Item Tracking** | |
| &nbsp; • &nbsp; [Get-AdoClassificationNode](Get-AdoClassificationNode.md) | Gets classification nodes for a project in Azure DevOps. |
| &nbsp; • &nbsp; [New-AdoClassificationNode](New-AdoClassificationNode.md) | Creates a new classification node for a project in Azure DevOps. |
| &nbsp; • &nbsp; [Set-AdoClassificationNode](Set-AdoClassificationNode.md) | Updates a classification node for a project in Azure DevOps. |
| &nbsp; • &nbsp; [Remove-AdoClassificationNode](Remove-AdoClassificationNode.md) | Removes a classification node from a project in Azure DevOps. |
