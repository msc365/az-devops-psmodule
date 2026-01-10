BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Remove-AdoEnvironment' {
    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should remove environment by Id' {
            # Act
            { Remove-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1 -Confirm:$false } | Should -Not -Throw

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should accept environment Ids via pipeline' {
            # Act
            { 1 | Remove-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false } | Should -Not -Throw

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should handle multiple environment Ids via pipeline' {
            # Act
            { @(1, 2, 3) | Remove-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false } | Should -Not -Throw

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 3
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Remove-AdoEnvironment -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -Id 1 -Confirm:$false } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            Remove-AdoEnvironment -ProjectName 'TestProject' -Id 1 -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*dev.azure.com/default-org*'
            }

            # Cleanup
            Remove-Item env:DefaultAdoCollectionUri -ErrorAction SilentlyContinue
        }

        It 'Should use default ProjectName from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoProject = 'DefaultProject'

            # Act
            Remove-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -Id 1 -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*DefaultProject*'
            }

            # Cleanup
            Remove-Item env:DefaultAdoProject -ErrorAction SilentlyContinue
        }
    }

    Context 'API Interaction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct REST API URI for deleting environment' {
            # Act
            Remove-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1 -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/pipelines/environments/1' -and
                $Version -eq '7.2-preview.1' -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Act
            Remove-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1 -Confirm:$false

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should warn when environment does not exist (EnvironmentNotFoundException)' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('EnvironmentNotFoundException')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'EnvironmentNotFound', 'ObjectNotFound', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('EnvironmentNotFoundException: The environment with ID 999 does not exist.')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act & Assert - Should write warning but not throw
            { Remove-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 999 -WarningAction SilentlyContinue -Confirm:$false } | Should -Not -Throw
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { Remove-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1 -Confirm:$false } | Should -Throw '*API Error: Unauthorized*'
        }
    }
}
