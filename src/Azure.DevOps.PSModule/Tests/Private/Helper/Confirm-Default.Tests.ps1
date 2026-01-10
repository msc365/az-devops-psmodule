BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Confirm-Default' -Tag 'Private' {
    BeforeAll {
        $mockValidDefaults = @{
            Organization  = 'my-org'
            Project       = 'my-project'
            CollectionUri = 'https://dev.azure.com/my-org'
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
            }
        }

        It 'Should pass validation when all defaults have values' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockValidDefaults = @{
                    Organization  = 'my-org'
                    Project       = 'my-project'
                    CollectionUri = 'https://dev.azure.com/my-org'
                }

                # Act & Assert
                { Confirm-Default -Defaults $mockValidDefaults } | Should -Not -Throw
            }
        }

        It 'Should validate single parameter successfully' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $singleDefault = @{ Organization = 'my-org' }

                # Act & Assert
                { Confirm-Default -Defaults $singleDefault } | Should -Not -Throw
            }
        }

        It 'Should validate multiple parameters successfully' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $multipleDefaults = @{
                    Organization = 'org1'
                    Project      = 'project1'
                    Repository   = 'repo1'
                }

                # Act & Assert
                { Confirm-Default -Defaults $multipleDefaults } | Should -Not -Throw
            }
        }

        It 'Should return without output when validation passes' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockValidDefaults = @{
                    Organization  = 'my-org'
                    Project       = 'my-project'
                    CollectionUri = 'https://dev.azure.com/my-org'
                }

                # Act
                $result = Confirm-Default -Defaults $mockValidDefaults

                # Assert
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
            }
        }

        It 'Should throw error when parameter value is null' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $nullDefault = @{ Organization = $null }

                # Act & Assert
                { Confirm-Default -Defaults $nullDefault } | Should -Throw '*Organization*required*Set-AdoDefault*'
            }
        }

        It 'Should throw error when parameter value is empty string' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $emptyDefault = @{ Project = '' }

                # Act & Assert
                { Confirm-Default -Defaults $emptyDefault } | Should -Throw '*Project*required*Set-AdoDefault*'
            }
        }

        It 'Should identify the specific missing parameter in error message' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $missingParam = @{ CollectionUri = '' }

                # Act & Assert
                { Confirm-Default -Defaults $missingParam } | Should -Throw '*CollectionUri*'
            }
        }

        It 'Should throw on first missing parameter when multiple are empty' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $multipleEmpty = @{
                    Organization = ''
                    Project      = ''
                }

                # Act & Assert
                { Confirm-Default -Defaults $multipleEmpty } | Should -Throw '*required*'
            }
        }

        It 'Should suggest using Set-AdoDefault in error message' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $emptyDefault = @{ Organization = '' }

                # Act & Assert
                { Confirm-Default -Defaults $emptyDefault } | Should -Throw '*Set-AdoDefault*'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
            }
        }

        It 'Should handle empty hashtable' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $emptyHash = @{}

                # Act & Assert
                { Confirm-Default -Defaults $emptyHash } | Should -Not -Throw
            }
        }

        It 'Should handle defaults with whitespace-only values' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $whitespaceDefault = @{ Organization = '   ' }

                # Act & Assert
                # Whitespace is not considered null or empty by [string]::IsNullOrEmpty
                { Confirm-Default -Defaults $whitespaceDefault } | Should -Not -Throw
            }
        }

        It 'Should handle defaults with special characters in values' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $specialChars = @{ Organization = 'org!@#$%^&*()' }

                # Act & Assert
                { Confirm-Default -Defaults $specialChars } | Should -Not -Throw
            }
        }

        It 'Should validate when all parameters are provided and valid' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $completeDefaults = @{
                    Organization  = 'test-org'
                    Project       = 'test-project'
                    CollectionUri = 'https://dev.azure.com/test-org'
                    Repository    = 'test-repo'
                }

                # Act & Assert
                { Confirm-Default -Defaults $completeDefaults } | Should -Not -Throw
            }
        }
    }

    Context 'Edge Cases' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
            }
        }

        It 'Should handle parameter names with various casing' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $variousCasing = @{
                    organization  = 'my-org'
                    PROJECT       = 'my-project'
                    CollectionUri = 'https://dev.azure.com/my-org'
                }

                # Act & Assert
                { Confirm-Default -Defaults $variousCasing } | Should -Not -Throw
            }
        }

        It 'Should validate numeric string values' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $numericValues = @{
                    BuildId = '12345'
                    Version = '1.0'
                }

                # Act & Assert
                { Confirm-Default -Defaults $numericValues } | Should -Not -Throw
            }
        }
    }
}
