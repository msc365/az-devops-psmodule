# Testing Guidelines

## Running Tests

### Recommended Test Execution

When running Pester tests, especially through GitHub Copilot or automated tools, use **Normal** or **Minimal** output to prevent output buffer overflow and potential VS Code freezes:

```powershell
# Recommended: Normal output (shows summary and failures)
Invoke-Pester -Path .\src\Azure.DevOps.PSModule\Tests\Core\Projects\Get-AdoProject.Tests.ps1 -Output Normal

# Alternative: Minimal output (only shows summary)
Invoke-Pester -Path .\src\Azure.DevOps.PSModule\Tests\Core\Projects\Get-AdoProject.Tests.ps1 -Output Minimal

# Avoid: Detailed output can cause freezes when run through Copilot Agent
Invoke-Pester -Path .\src\Azure.DevOps.PSModule\Tests\Core\Projects\Get-AdoProject.Tests.ps1 -Output Detailed
```

### Why This Matters

- **Detailed output** generates extensive logging that can overwhelm the output buffer when tests are executed through GitHub Copilot Agent or other integrated tools
- **Normal output** provides sufficient information for debugging while maintaining performance
- **Minimal output** is best for CI/CD pipelines or when you only need pass/fail status

### Running All Tests

```powershell
# Run all tests with normal output
Invoke-Pester -Path .\src\Azure.DevOps.PSModule\Tests\ -Output Normal

# Run all tests in a specific category
Invoke-Pester -Path .\src\Azure.DevOps.PSModule\Tests\Core\ -Output Normal

# Run specific test file
Invoke-Pester -Path .\src\Azure.DevOps.PSModule\Tests\Core\Projects\Get-AdoProject.Tests.ps1 -Output Normal

# Run with coverage (Pester v5 configuration syntax)
$config = New-PesterConfiguration
$config.Run.Path = '.\src\Azure.DevOps.PSModule\Tests\'
$config.Run.PassThru = $true
$config.CodeCoverage.Enabled = $true
# Target only module source files (Public, Private folders and .psm1)
$config.CodeCoverage.Path = @(
    '.\src\Azure.DevOps.PSModule\Public\**\*.ps1'
    '.\src\Azure.DevOps.PSModule\Private\**\*.ps1'
    '.\src\Azure.DevOps.PSModule\*.psm1'
)
$config.CodeCoverage.OutputFormat = 'JaCoCo'  # Generates coverage.xml
$config.CodeCoverage.OutputPath = 'coverage.xml'
$config.Output.Verbosity = 'Normal'
$result = Invoke-Pester -Configuration $config

# View coverage summary in console
$result.CodeCoverage | Format-List

```

### Using Build Tasks

The workspace includes predefined tasks that can be run from VS Code's Task Runner:

#### Test Task (with Output Selection)
The Test task will prompt you to select an output level (Detailed, Normal, Minimal, or None) before running:

```powershell
# Runs PSake Test task with interactive output selection
Task: Test
```

#### Direct Command Line Usage
You can also run the build script directly with your preferred output level:

```powershell
# Run tests with Normal output (recommended)
Invoke-PSake src/Build.ps1 -taskList Test -parameters @{Output='Normal'}

# Run tests with Detailed output
Invoke-PSake src/Build.ps1 -taskList Test -parameters @{Output='Detailed'}

# Run tests with Minimal output
Invoke-PSake src/Build.ps1 -taskList Test -parameters @{Output='Minimal'}
```

#### Pester Task
Direct Pester invocation without PSake:

```powershell
# Runs Pester directly with Detailed output
Task: Pester
```

Note: The Pester task uses Detailed output by default. If running through Copilot Agent, use the Test task with Normal output instead.

## Test Structure

### Folder Organization

Tests are organized in category folders with nested subfolders by functionality:

```text
src/Azure.DevOps.PSModule/Tests/
├── Core/                          # Core ADO functionality
│   ├── Processes/                 # Process-related cmdlets
│   ├── Projects/                  # Project-related cmdlets
│   └── Teams/                     # Team-related cmdlets
├── Feature/                       # Feature management tests
│   └── FeatureStatesQuery/        # Feature state cmdlets
├── Git/                           # Git repository tests
│   └── Repositories/              # Repository-related cmdlets
├── Graph/                         # Graph API tests
│   ├── Descriptors/               # Descriptor-related cmdlets
│   ├── Groups/                    # Group-related cmdlets
│   └── Memberships/               # Membership-related cmdlets
├── Helper/                        # Helper function tests
├── Pipeline/                      # Pipeline tests
│   ├── Check/                     # Check configuration cmdlets
│   └── Environment/               # Environment-related cmdlets
├── Policy/                        # Policy tests
│   ├── Configurations/            # Policy configuration cmdlets
│   └── Types/                     # Policy type cmdlets
├── Private/                       # Private helper function tests
├── ServiceEndpoint/               # Service endpoint tests
│   └── EndPoints/                 # Endpoint-related cmdlets
├── Work/                          # Work tracking tests
│   └── TeamSettings/              # Team settings cmdlets
│       ├── Iterations/            # Team iteration cmdlets
│       └── TeamFieldValues/       # Team field value cmdlets
└── WorkItemTracking/              # Work item tests
    └── ClassificationNodes/       # Classification node cmdlets
```

### Test File Patterns

**Reference test files** demonstrating modern best practices:
- **Get cmdlets**: `Core/Projects/Get-AdoProject.Tests.ps1`
- **New cmdlets**: `Core/Projects/New-AdoProject.Tests.ps1`
- **Set cmdlets**: `Core/Projects/Set-AdoProject.Tests.ps1`
- **Remove cmdlets**: `Core/Projects/Remove-AdoProject.Tests.ps1`

### Pester Structure

Tests follow Pester best practices:

- `BeforeAll`: Module import and mock setup
- `Describe`: Groups related tests for a cmdlet
- `Context`: Groups tests for specific scenarios
- `It`: Individual test cases

**Modern Best Practices** (see Set-AdoProject.Tests.ps1):
- Use parameterized tests with `-ForEach` for similar scenarios
- Avoid script-level state variables
- Use context-specific mock overrides instead of complex conditional mocks
- Keep BeforeAll mocks simple and predictable

## Writing Tests

### Module Import for Nested Folders

When creating tests in nested subfolders, use relative paths to navigate to the module:

```powershell
BeforeAll {
    # For tests in Tests/<Category>/<Subcategory>/
    # Example: Tests/Core/Projects/
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}
```

**Path Navigation by Folder Depth:**
- Tests in `Tests/<Category>/<Subcategory>/`: Use `..\..\..\'` (3 levels up)
- Tests in `Tests/<Category>/<Subcategory>/<Subsubcategory>/`: Use `..\..\..\..\'` (4 levels up)
- Tests in `Tests/<Category>/` (root level): Use `..\..\'` (2 levels up)

The pattern goes up to the Tests folder, then to Azure.DevOps.PSModule folder, then references the .psd1 file.

### Mock Best Practices

1. Mock at the module level: `-ModuleName Azure.DevOps.PSModule`
2. Create realistic error conditions with proper exception types
3. Use parameter filters to verify call behavior
4. Reset mocks between contexts if needed
5. Use simple, predictable mocks in BeforeAll blocks
6. Override mocks in specific contexts when needed for edge cases

### Error Handling Tests

When testing error handling, ensure mocks create exceptions that match production error patterns:

```powershell
Azure.DevOps.PSModule -MockWith {
    $exception = [System.Net.WebException]::new('Error message')
    $exception | Add-Member -NotePropertyName 'StatusCode' -NotePropertyValue 'NotFound' -Force
    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
        $exception,
        'ErrorId',
        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
        $targetObject
    )
    throw $errorRecord
}
```

### Test Organization Guidelines

1. **Nested Structure**: Tests are organized by functionality in nested folders (e.g., `Core/Projects/`, `WorkItemTracking/ClassificationNodes/`)
2. **One cmdlet per file**: Each test file focuses on a single cmdlet (e.g., `Get-AdoProject.Tests.ps1`)
3. **Consistent naming**: Test files follow the pattern `<Verb>-<Noun>.Tests.ps1`
4. **Related tests together**: Keep related cmdlets in the same subfolder (e.g., all project cmdlets in `Core/Projects/`)
