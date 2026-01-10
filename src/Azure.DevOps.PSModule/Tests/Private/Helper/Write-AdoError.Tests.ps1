BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Write-AdoError' -Tag 'Private' {
    BeforeAll {
        $mockErrorMessage = 'This is a test error message'
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
            }
        }

        It 'Should throw terminating error with provided message' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockErrorMessage = 'This is a test error message'

                # Act & Assert
                { Write-AdoError -Message $mockErrorMessage } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        It 'Should create ErrorRecord with correct exception' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockErrorMessage = 'This is a test error message'

                # Act & Assert
                try {
                    Write-AdoError -Message $mockErrorMessage
                } catch {
                    $_.Exception.Message | Should -Be $mockErrorMessage
                    $_.Exception.GetType().Name | Should -Be 'Exception'
                }
            }
        }

        It 'Should set ErrorCategory to OperationStopped' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockErrorMessage = 'This is a test error message'

                # Act & Assert
                try {
                    Write-AdoError -Message $mockErrorMessage
                } catch {
                    $_.CategoryInfo.Category | Should -Be 'OperationStopped'
                }
            }
        }

        It 'Should set TargetObject in ErrorRecord' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockErrorMessage = 'This is a test error message'

                # Act & Assert
                try {
                    Write-AdoError -Message $mockErrorMessage
                } catch {
                    $_.TargetObject | Should -Be 'TargetObject'
                }
            }
        }

        It 'Should set ErrorId in ErrorRecord' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockErrorMessage = 'This is a test error message'

                # Act & Assert
                try {
                    Write-AdoError -Message $mockErrorMessage
                } catch {
                    $_.FullyQualifiedErrorId | Should -Match 'ErrorID'
                }
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
            }
        }

        It 'Should handle long error messages' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $longMessage = 'Error: ' + ('x' * 1000)

                # Act & Assert
                { Write-AdoError -Message $longMessage } | Should -Throw -ExpectedMessage $longMessage
            }
        }

        It 'Should handle messages with special characters' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $specialMessage = 'Error with special chars: test!test'

                # Act & Assert
                { Write-AdoError -Message $specialMessage } | Should -Throw -ExpectedMessage $specialMessage
            }
        }

        It 'Should handle multiline error messages' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $multilineMessage = "Line 1`nLine 2`nLine 3"

                # Act & Assert
                { Write-AdoError -Message $multilineMessage } | Should -Throw
            }
        }
    }

    Context 'Pipeline Support Tests' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
            }
        }

        It 'Should accept message from pipeline by value' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockErrorMessage = 'This is a test error message'

                # Act & Assert
                { $mockErrorMessage | Write-AdoError } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        It 'Should accept message from pipeline by property name' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockErrorMessage = 'This is a test error message'
                $messageObject = [PSCustomObject]@{ Message = $mockErrorMessage }

                # Act & Assert
                { $messageObject | Write-AdoError } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        It 'Should process multiple messages from pipeline' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $messages = @('Error 1', 'Error 2', 'Error 3')

                # Act & Assert
                # Only the first error will be thrown as it's terminating
                { $messages | Write-AdoError } | Should -Throw -ExpectedMessage 'Error 1'
            }
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
            }
        }

        It 'Should be terminating error' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockErrorMessage = 'This is a test error message'
                $errorThrown = $false

                # Act
                try {
                    Write-AdoError -Message $mockErrorMessage
                    # This line should never be reached
                    $errorThrown = $false
                } catch {
                    $errorThrown = $true
                }

                # Assert
                $errorThrown | Should -Be $true
            }
        }

        It 'Should stop execution immediately' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockErrorMessage = 'This is a test error message'
                $executionContinued = $false

                # Act
                try {
                    Write-AdoError -Message $mockErrorMessage
                    $executionContinued = $true
                } catch {
                    # Error was caught
                }

                # Assert
                $executionContinued | Should -Be $false
            }
        }
    }
}
