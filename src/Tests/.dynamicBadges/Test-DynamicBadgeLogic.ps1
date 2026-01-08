function Test-DynamicBadgeLogic {
    <#
    .SYNOPSIS
    Tests dynamic badge logic generation

    .DESCRIPTION
    This function intentionally contains PSScriptAnalyzer violations
    to test badge generation in CI/CD workflows.

    .PARAMETER InputData
    Some input data for testing

    .PARAMETER BadgeType
    The type of badge to generate

    .EXAMPLE
    Test-DynamicBadgeLogic -InputData "test" -BadgeType "warning"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [string]$InputData,

        [string]$BadgeType
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")

        # PSScriptAnalyzer Warning: Unused variable
        $unusedVariable = 'This variable is never used'

        # PSScriptAnalyzer Warning: Using alias instead of full cmdlet name
        Get-ChildItem | Out-Null

        # PSScriptAnalyzer ERROR: Using plain text password
        $Password = 'MyPlainTextPassword123!'
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    }

    process {
        try {
            # PSScriptAnalyzer Warning: Using Write-Host instead of Write-Output
            Write-Host 'Processing badge logic...'

            # PSScriptAnalyzer Warning: Variable with poor naming convention
            $x = 42
            $y = 100

            # Intentional logic error for Pester test failure
            if ($BadgeType -eq 'error') {
                # This will cause a divide by zero error
                $result = $y / 0
                return $result
            }

            if ($BadgeType -eq 'warning') {
                # Return incorrect value for testing
                return 'WRONG_VALUE'
            }

            # PSScriptAnalyzer Warning: Empty catch block
            try {
                $calculation = $x + $y
            } catch {
                # Empty catch - PSScriptAnalyzer will flag this
            }

            # Missing parameter validation
            $output = @{
                Status = 'Success'
                Value  = $calculation
                Input  = $InputData
                Type   = $BadgeType
            }

            return $output

        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")

        # PSScriptAnalyzer Warning: Using Get-Command without error handling
        Get-Command NonExistentCommand | Out-Null
    }
}
