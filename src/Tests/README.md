# Testing Guidelines

## Running Tests

### Recommended Test Execution

When running Pester tests, especially through GitHub Copilot or automated tools, use **Normal** or **Minimal** output to prevent output buffer overflow and potential VS Code freezes:

```powershell
# Recommended: Normal output (shows summary and failures)
Invoke-Pester -Path .\src\Tests\Core\Projects\Get-AdoProject.Tests.ps1 -Output Normal

# Alternative: Minimal output (only shows summary)
Invoke-Pester -Path .\src\Tests\Core\Projects\Get-AdoProject.Tests.ps1 -Output Minimal

# Avoid: Detailed output can cause freezes when run through Copilot Agent
Invoke-Pester -Path .\src\Tests\Core\Projects\Get-AdoProject.Tests.ps1 -Output Detailed
```

### Why This Matters

- **Detailed output** generates extensive logging that can overwhelm the output buffer when tests are executed through GitHub Copilot Agent or other integrated tools
- **Normal output** provides sufficient information for debugging while maintaining performance
- **Minimal output** is best for CI/CD pipelines or when you only need pass/fail status

### Running All Tests

```powershell
# Run all tests with normal output
Invoke-Pester -Path .\src\Tests\ -Output Normal

# Run all tests in a specific category
Invoke-Pester -Path .\src\Tests\Core\ -Output Normal

# Run specific test file
Invoke-Pester -Path .\src\Tests\Core\Projects\Get-AdoProject.Tests.ps1 -Output Normal

# Run with coverage
Invoke-Pester -Path .\src\Tests\ -CodeCoverage .\src\Azure.DevOps.PSModule\**\*.ps1 -Output Normal
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

Tests are organized in category folders that mirror the source code structure:

```text
src/Tests/
├── Authorization/         # Authentication and token tests
├── Core/                  # Core ADO functionality
│   └── Projects/          # Project-related cmdlets
├── Feature/               # Feature management tests
├── Git/                   # Git repository tests
├── Graph/                 # Graph API tests
├── Helper/                # Helper function tests
├── Pipeline/              # Pipeline tests
├── Policy/                # Policy tests
├── ServiceEndpoint/       # Service endpoint tests
├── Work/                  # Work tracking tests
└── WorkItemTracking/      # Work item tests
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

When creating tests in category subfolders, ensure the module path correctly navigates to the src directory:

```powershell
BeforeAll {
    $moduleName = 'Azure.DevOps.PSModule'
    
    # For tests in src/Tests/<Category>/
    $modulePath = Join-Path -Path (Get-Item $PSScriptRoot).Parent.Parent.FullName -ChildPath $moduleName
    
    # For tests in src/Tests/<Category>/<Subcategory>/
    $modulePath = Join-Path -Path (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName -ChildPath $moduleName
    
    # Only remove and re-import if module is not loaded or loaded from different path
    $loadedModule = Get-Module -Name $moduleName -ErrorAction SilentlyContinue
    if ($loadedModule -and $loadedModule.Path -ne (Join-Path $modulePath "$moduleName.psm1")) {
        Remove-Module -Name $moduleName -Force
        $loadedModule = $null
    }
    
    # Import the module if not already loaded
    if (-not $loadedModule) {
        Import-Module $modulePath -Force -ErrorAction Stop
    }
}
```

### Mock Best Practices

1. Mock at the module level: `-ModuleName $moduleName`
2. Create realistic error conditions with proper exception types
3. Use parameter filters to verify call behavior
4. Reset mocks between contexts if needed

### Error Handling Tests

When testing error handling, ensure mocks create exceptions that match production error patterns:

```powershell
Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
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
