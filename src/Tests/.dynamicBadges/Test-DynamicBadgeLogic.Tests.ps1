BeforeAll {
    . $PSScriptRoot/Test-DynamicBadgeLogic.ps1
}

Describe 'Test-DynamicBadgeLogic' {

    Context 'Basic Functionality' {

        It 'Should return success status for valid input' {
            $result = Test-DynamicBadgeLogic -InputData 'test' -BadgeType 'success'
            $result.Status | Should -Be 'Success'
        }

        It 'Should calculate correct value' {
            $result = Test-DynamicBadgeLogic -InputData 'test' -BadgeType 'success'
            $result.Value | Should -Be 142
        }

        It 'Should include input data in output' {
            $result = Test-DynamicBadgeLogic -InputData 'test123' -BadgeType 'success'
            $result.Input | Should -Be 'test123'
        }
    }

    Context 'Badge Type Tests' {

        It 'Should handle warning badge type correctly' {
            # This test will FAIL because function returns "WRONG_VALUE"
            $result = Test-DynamicBadgeLogic -InputData 'test' -BadgeType 'warning'
            $result | Should -Be 'EXPECTED_VALUE'
        }

        It 'Should handle error badge type without throwing' {
            # This test will FAIL because function tries to divide by zero
            { Test-DynamicBadgeLogic -InputData 'test' -BadgeType 'error' } | Should -Not -Throw
        }

        It 'Should return correct badge type in output' {
            $result = Test-DynamicBadgeLogic -InputData 'test' -BadgeType 'info'
            $result.Type | Should -Be 'info'
        }
    }

    Context 'Parameter Validation' {

        It 'Should accept empty InputData' {
            { Test-DynamicBadgeLogic -InputData '' -BadgeType 'success' } | Should -Not -Throw
        }

        It 'Should fail with null BadgeType' {
            # This test will FAIL - intentionally checking wrong condition
            $result = Test-DynamicBadgeLogic -InputData 'test' -BadgeType $null
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should validate required parameters exist' {
            # This test will FAIL - parameters are not mandatory
            { Test-DynamicBadgeLogic } | Should -Throw
        }
    }

    Context 'Output Structure' {

        It 'Should return hashtable with correct properties' {
            $result = Test-DynamicBadgeLogic -InputData 'test' -BadgeType 'success'
            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'Status'
            $result.Keys | Should -Contain 'Value'
        }

        It 'Should have exactly 5 properties in output' {
            # This test will FAIL - output only has 4 properties
            $result = Test-DynamicBadgeLogic -InputData 'test' -BadgeType 'success'
            $result.Keys.Count | Should -Be 5
        }
    }
}
