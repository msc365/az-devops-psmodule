<!-- omit from toc -->
# Automating Azure DevOps Tasks [`PowerShell`]

<!-- cSpell: words psake psmodule -->
<!-- markdownlint-disable no-duplicate-heading -->

[![github-latest](https://img.shields.io/github/v/release/msc365/az-devops-psmodule?include_prereleases&color=blue&logo=github&label=release)](https://github.com/msc365/az-devops-psmodule/releases)
[![ps-gallery-latest](https://img.shields.io/powershellgallery/v/Azure.DevOps.PSModule?include_prereleases&color=blue&label=ps-gallery)](https://www.powershellgallery.com/packages/Azure.DevOps.PSModule)
[![ps-gallery-downloads](https://img.shields.io/powershellgallery/dt/Azure.DevOps.PSModule.svg)](https://www.powershellgallery.com/packages/Azure.DevOps.PSModule)
[![github-issues](https://img.shields.io/github/issues/msc365/az-devops-psmodule?logo=github)](https://github.com/msc365/az-devops-psmodule/issues)
[![github-license](https://img.shields.io/github/license/msc365/az-devops-psmodule?label=licence&color=purple)](LICENSE)

[![pester-tests](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/msc365admin/49cbfa1538653138a1f2c4e452d7b4b4/raw/az-devops-psmodule-test-badge.json)](https://github.com/msc365/az-devops-psmodule/actions/workflows/pr-code-testing.yml)
[![code-coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/msc365admin/49cbfa1538653138a1f2c4e452d7b4b4/raw/az-devops-psmodule-coverage-badge.json)](https://github.com/msc365/az-devops-psmodule/actions/workflows/pr-code-testing.yml)
[![code-analysis](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/msc365admin/49cbfa1538653138a1f2c4e452d7b4b4/raw/az-devops-psmodule-analysis-badge.json)](https://github.com/msc365/az-devops-psmodule/actions/workflows/pr-code-testing.yml)

This repository provides a PowerShell module that wraps the Azure DevOps REST API into clean, task-oriented cmdlets. It simplifies automation and scripting across your DevOps workflows, making it easier to manage pipelines, repositories, builds, releases, and work items directly from PowerShell.

<!-- > [!WARNING]
> This module provides experimental features, allowing you to test and provide feedback on new functionalities before they become stable. These features are not finalized and may undergo breaking changes, so they are not recommended for production use. -->

<!-- omit from toc -->
## Features

- Intuitive PowerShell cmdlets for Azure DevOps REST API
- Secure authentication with Workload Identity Federation

<!-- omit from toc -->
## Use Cases

- Automating Azure DevOps tasks and resource deployments
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
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)

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

### Authentication

The module uses automatic authentication through Azure PowerShell. Simply sign in with `Connect-AzAccount`:

#### PowerShell

```powershell
$azAccountSplat = @{
    TenantId       = '<YOUR_TENANT_ID>'
    SubscriptionId = '<YOUR_SUBSCRIPTION_ID>'
}
Connect-AzAccount @azAccountSplat
```

The module will automatically obtain the required authentication tokens when you execute cmdlets. Make sure your Azure account has the required permissions in Azure DevOps.

### Get project details

#### PowerShell

```powershell
Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1'
```

This gets the project as a `[PSCustomObject]` with all available details.

### Set default session context (optional)

To avoid repeating `-CollectionUri` and `-ProjectName` parameters, you can set session defaults:

#### PowerShell

```powershell
# Call cmdlets without specifying these parameters
Set-AdoDefault -Organization 'my-org' -Project 'my-project-1'

# Get a team by its name in 'my-project-1'
Get-AdoTeam -Name 'my-team-1'

# Get all environments from 'my-project-1'
Get-AdoEnvironment
```

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

## Contributing

We welcome fixes, features, and documentation updates from the community. Please review [CONTRIBUTING.md](CONTRIBUTING.md) for the safety, testing, and workflow expectations before opening a pull request.

## Support

This project uses GitHub Issues to track bugs and feature requests.
Please [search the existing issues](https://github.com/msc365/az-devops-psmodule/issues?q=is%3Aissue) before filing
new issues to avoid duplicates.

- For latest unreleased changes, please see [CHANGELOG](CHANGELOG.md).
- For new issues, file your bug or feature request as a [new issue](https://github.com/msc365/az-devops-psmodule/issues/new/choose).
- For help and questions, please raise an issue or start a [new discussion](https://github.com/msc365/az-devops-psmodule/discussions).

## License

![logo small martin swinkels cloud](.assets/logo-small.png)  
Part of Martin's Cloud on GitHub

Copyright (c) 2025 MSc365.eu by Martin Swinkels

This project is published under the MIT license.  
See [MIT License](LICENSE) for details.

<!-- omit from toc -->
## Disclaimer

This repository is provided "**as is**" and is subject to **limited support**. While reasonable efforts
have been made to ensure its usefulness, there are **no warranties or guarantees** regarding accuracy,
reliability, security, or ongoing maintenance. By using this code, you acknowledge and agree that you
do so at your own risk. It is your responsibility to validate, test, and ensure suitability for your specific
use case, particularly in production environments. We welcome community contributions and feedback to improve
the project; however, official support will limited.

<!-- omit from toc -->
## Liability

Under no circumstances shall the authors, contributors, or affiliated organizations be held liable for
any direct, indirect, incidental, or consequential damages arising from the use of this repository, including
but not limited to loss of data, business interruption, or system failures.
Use of this code implies acceptance of these terms.

<!-- omit from toc -->
## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft
sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.
