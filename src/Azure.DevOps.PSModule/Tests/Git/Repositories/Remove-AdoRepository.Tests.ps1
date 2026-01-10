BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Remove-AdoRepository' {
    BeforeAll {
        # Sample repository data for mocking Get-AdoRepository
        $mockRepository = @{
            id            = '12345678-1234-1234-1234-123456789012'
            name          = 'TestRepo1'
            project       = @{
                id   = '87654321-4321-4321-4321-210987654321'
                name = 'TestProject'
            }
            defaultBranch = 'refs/heads/main'
            url           = 'https://dev.azure.com/my-org/TestProject/_apis/git/repositories/12345678-1234-1234-1234-123456789012'
            remoteUrl     = 'https://dev.azure.com/my-org/TestProject/_git/TestRepo1'
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoRepository { return $mockRepository }
        }

        It 'Should remove a repository by ID' {
            # Act
            Remove-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name '12345678-1234-1234-1234-123456789012' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'DELETE'
            }
        }

        It 'Should remove a repository by name' {
            # Act
            Remove-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestRepo1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'DELETE'
            }
        }

        It 'Should accept repository names via pipeline' {
            # Act
            'TestRepo1' | Remove-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'DELETE'
            }
        }

        It 'Should resolve repository name to ID before deletion' {
            # Act
            Remove-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestRepo1' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoRepository -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Name -eq 'TestRepo1'
            }
        }

        It 'Should not call Get-AdoRepository when Name is a GUID' {
            # Act
            Remove-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name '12345678-1234-1234-1234-123456789012' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoRepository -ModuleName Azure.DevOps.PSModule -Times 0
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoRepository { return $mockRepository }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Remove-AdoRepository -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -Name 'TestRepo1' -Confirm:$false } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            Remove-AdoRepository -ProjectName 'TestProject' -Name '12345678-1234-1234-1234-123456789012' -Confirm:$false

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
            Remove-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -Name '12345678-1234-1234-1234-123456789012' -Confirm:$false

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
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoRepository { return $mockRepository }
        }

        It 'Should construct correct REST API URI with repository ID' {
            # Act
            Remove-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name '12345678-1234-1234-1234-123456789012' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/git/repositories/12345678-1234-1234-1234-123456789012' -and
                $Version -eq '7.1' -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Act
            Remove-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestRepo1' -Confirm:$false

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Edge Cases and Error Handling' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoRepository { return $mockRepository }
        }

        It 'Should warn when repository does not exist (NotFoundException)' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('NotFoundException: The repository with ID NonExistentRepo does not exist.')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'RepositoryNotFound', 'ObjectNotFound', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('NotFoundException: The repository with ID NonExistentRepo does not exist.')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act & Assert - Should write warning but not throw
            { Remove-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'NonExistentRepo' -WarningAction SilentlyContinue -Confirm:$false } | Should -Not -Throw
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { Remove-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name '12345678-1234-1234-1234-123456789012' -Confirm:$false } | Should -Throw '*API Error: Unauthorized*'
        }

        It 'Should skip deletion when repository ID cannot be resolved' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoRepository { return $null }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { }

            # Act
            Remove-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'NonExistentRepo' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 0
        }
    }
}
