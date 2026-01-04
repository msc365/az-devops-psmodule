<!-- omit from toc -->
# Azure DevOps PowerShell Module

<!-- cSpell: words psake psmodule -->
<!-- markdownlint-disable no-duplicate-heading -->

[![GitHub release (latest)](https://img.shields.io/github/v/release/msc365/az-devops-psmodule?include_prereleases&logo=github&color=blue)](https://github.com/msc365/az-devops-psmodule/releases)
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/Azure.DevOps.PSModule?include_prereleases&color=blue)](https://www.powershellgallery.com/packages/Azure.DevOps.PSModule)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/Azure.DevOps.PSModule.svg)](https://www.powershellgallery.com/packages/Azure.DevOps.PSModule)
[![license](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)

This repository provides a PowerShell module that wraps the Azure DevOps REST API into clean, task-oriented cmdlets. It simplifies automation and scripting across your DevOps workflows, making it easier to manage pipelines, repositories, builds, releases, and work items directly from PowerShell.

> [!NOTE]
> We are currently working on major changes to elevate this project with better PowerShell best practices, comprehensive unit tests, and improved documentation. The first result was the **v0.2.0-alpha1** release last week, followed by the current **v0.2.0-alpha2** release. An upcoming **v0.2.0-alpha3** release will test all available functions to ensure they conform to the new patterns and improvements. See the [releases page](https://github.com/msc365/az-devops-psmodule/releases) for the latest detailed information. Your feedback during this alpha phase is highly appreciated!

<!-- > [!WARNING]
> This module provides experimental features, allowing you to test and provide feedback on new functionalities before they become stable. These features are not finalized and may undergo breaking changes, so they are not recommended for production use. -->

<!-- omit from toc -->
## Features

- Intuitive PowerShell cmdlets for Azure DevOps REST API
- Secure authentication with Workload Identity Federation

<!-- omit from toc -->
## Use Cases

- Automate DevOps workflows and resource deployments
- Accelerate onboarding and standardization for cloud teams
- Implement end-to-end governance from CI/CD pipelines to Azure Resource Manager

> [!TIP]
> See the [msc365/az-devops-governance](https://github.com/msc365/az-devops-governance) repository for sample scripts that demonstrate a complete Azure governance model. These examples showcase how to implement end-to-end governance from CI/CD pipelines to Azure Resource Manager deployments, aligning with best practices for enterprise-grade cloud architecture.

<!-- omit from toc -->
## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Commands](#commands)
- [Requirements](#requirements)
- [Development](#development)
- [License](#license)
- [Disclaimer](#disclaimer)

## Installation

### PowerShell Gallery (recommended)

```powershell
# Install for current user
Install-Module -Name Azure.DevOps.PSModule -Scope CurrentUser -Force

# Install prerelease
Install-Module -Name Azure.DevOps.PSModule -Scope CurrentUser -AllowPrerelease -Force

# Install for all users (requires admin)
Install-Module -Name Azure.DevOps.PSModule -Scope AllUsers -Force
```

### From Source

```powershell
# Clone the repository
git clone 'https://github.com/msc365/az-devops-psmodule.git'
cd 'az-devops-psmodule'

# Import the module
Import-Module -Name '.\src\Azure.DevOps.PSModule' -Force

# Verify the module
Get-Module -Name 'Azure.DevOps.PSModule'

# List all commands imported from the Azure DevOps module
Get-Command -Name '*-Ado*'

```

## Quick Start

### Sign in to Azure

To sign in, use the Connect-AzAccount cmdlet.

```powershell
  $azAccountSplat = @{
      TenantId = '<YOUR_TENANT_ID>'
      SubscriptionId = '<YOUR_SUBSCRIPTION_ID>'
  }
  Connect-AzAccount @azAccountSplat
```

### Connect

#### PowerShell

```powershell
Connect-AdoOrganization -Organization 'my-org' -PAT '******'
```

This connects to an Azure DevOps organization using a personal access token (PAT). If you don't provide a PAT, the module will attempt to authenticate using the Azure DevOps service principal. Make sure the service principal (Azure Account) used has the required permissions in Azure DevOps.

### Get project details

#### PowerShell

```powershell
Get-AdoProject -ProjectId 'my-project-1'
```

This gets the project as a `<System.Object>` with all available details.

## Commands

See all available [Commands](docs/Azure.DevOps.PSModule.md) documentation for more detailed information.

## Requirements

- **PowerShell**: 7.4 or later
- **Az.Accounts**: 3.0.5 or later

## Development

### Building the Module

```powershell
# Run tests
Invoke-psake .\src\Build.ps1 -taskList Test

# Build module
Invoke-psake .\src\Build.ps1 -taskList Build

# Build and publish
Invoke-psake .\src\Build.ps1 -taskList Publish
```

### Clean up

```powershell
# Clean up module dir
Invoke-psake .\src\Build.ps1 -taskList Clean
```

## License

![logo small martin swinkels cloud](.assets/logo-small.png)  
<small>Part of Martin's Cloud on GitHub</small>

[MIT License](LICENSE) | Copyright (c) 2025 MSc365.eu by Martin Swinkels

## Disclaimer

Sample only – this is not an official supported module. Use at your own risk.
