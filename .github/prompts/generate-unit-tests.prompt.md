---
agent: 'agent'
description: 'Generate unit tests for selected functions or methods'
---

## Task

Analyze the selected function/method and generate focused unit tests that thoroughly validate its behavior.

## Test Generation Strategy

1. **Core Functionality Tests**
   - Test the main purpose/expected behavior
   - Verify return values with typical inputs
   - Test with realistic data scenarios

2. **Input Validation Tests**
   - Test with invalid input types
   - Test with null/undefined values
   - Test with empty strings/arrays/objects
   - Test boundary values (min/max, zero, negative numbers)

3. **Error Handling Tests**
   - Test expected exceptions are thrown
   - Verify error messages are meaningful
   - Test graceful handling of edge cases

4. **Side Effects Tests** (if applicable)
   - Verify external calls are made correctly
   - Test state changes
   - Validate interactions with dependencies

## Test Structure Requirements

- Use existing project testing framework and patterns, pester is default for PowerShell
- Each context has a single BeforeEach block that sets up common mocks
- Follow AAA pattern: Arrange, Act, Assert
- Write descriptive test names that explain the scenario
- Group related tests in describe/context blocks
- Mock external dependencies cleanly
- Always add `-Confirm:$false` to cmdlets supporting ShouldProcess
- Always mock `Start-Sleep` in BeforeEach blocks to prevent delays
- Use proper `ErrorRecord` objects for error testing, not hashtables
- Test mandatory parameters via metadata, not by omitting them
- Mock all external dependencies consistently in BeforeEach blocks

### Test Priority (Most to Least Essential)

**Always Include (Most Essential):**
- Core functionality - main purpose of cmdlet
- Required parameter validation - mandatory parameters
- Invalid input handling - invalid URIs, malformed data
- API interaction - URI construction, HTTP methods
- Error handling - specific exceptions, error propagation
- Pipeline support - accepting input via pipeline
- ID resolution - GUID vs name handling (if applicable)
- Async operations - polling/status checking (if applicable)

**Skip When Max Tests Reached (Less Essential):**
- Parameter aliases - enforced by PowerShell runtime
- ValidateSet attributes - enforced by PowerShell automatically
- API version parameters - stable, rarely changes
- WhatIf support - framework-level functionality
- Verbose logging - informational only
- Helper function calls - tested indirectly
- Duplicate pagination scenarios - keep one representative
- Output object property validation - covered in core tests

Target function: ${input:function_name:Which function or method should be tested?}
Target folder: ${input:target_folder:Which folder contains the functions or methods that should be tested?}
Output folder: ${input:output_folder:Where should the generated tests be saved?}
Testing framework: ${input:framework:Which framework? (pester/jest/vitest/mocha/pytest/rspec/etc)}

## Guidelines

- Create folder structure mirroring source if needed
- Generate maximum 12-15 focused tests cases per cmdlet, covering the most important scenarios
- Include realistic test data, not just simple examples
- Add comments for complex test setup or assertions
- Ensure tests are independent and can run in any order
- Focus on testing behavior, not implementation details
- Use Invoke-Pester to validate test syntax if applicable
- **CRITICAL:** Never use `-Output Detailed` when running Invoke-Pester - it freezes the terminal

Create tests that give confidence the function works correctly and help catch regressions.
