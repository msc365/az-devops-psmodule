BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'New-AdoRepository' {
    BeforeAll {
        # Sample project data for mocking
        $mockProject = @{
            id          = '87654321-4321-4321-4321-210987654321'
            name        = 'TestProject'
            description = 'Test Project Description'
            url         = 'https://dev.azure.com/my-org/_apis/projects/87654321-4321-4321-4321-210987654321'
        }

        # Sample repository data for mocking successful creation
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
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockRepository }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
        }

        It 'Should create a new repository with valid parameters' {
            # Act
            $result = New-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestRepo1' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'TestRepo1'
            $result.id | Should -Be '12345678-1234-1234-1234-123456789012'
        }

        It 'Should return repository with all expected properties' {
            # Act
            $result = New-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestRepo1' -Confirm:$false

            # Assert
            $result.id | Should -Be '12345678-1234-1234-1234-123456789012'
            $result.name | Should -Be 'TestRepo1'
            $result.defaultBranch | Should -Be 'refs/heads/main'
            $result.url | Should -Not -BeNullOrEmpty
            $result.remoteUrl | Should -Not -BeNullOrEmpty
            $result.projectName | Should -Be 'TestProject'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should accept repository names via pipeline' {
            # Act
            $result = 'TestRepo1' | New-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'TestRepo1'
        }

        It 'Should resolve project name to project ID' {
            # Act
            New-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestRepo1' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Name -eq 'TestProject'
            }
        }

        It 'Should not call Get-AdoProject when ProjectName is a GUID' {
            # Act
            New-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName '87654321-4321-4321-4321-210987654321' -Name 'TestRepo1' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule -Times 0
        }

        It 'Should support SourceRef parameter' {
            # Act
            New-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestRepo1' -SourceRef 'refs/heads/develop' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*sourceRef=refs/heads/develop*'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockRepository }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { New-AdoRepository -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -Name 'TestRepo1' -Confirm:$false } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            $result = New-AdoRepository -ProjectName 'TestProject' -Name 'TestRepo1' -Confirm:$false

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
            $result = New-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestRepo1' -Confirm:$false

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
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockRepository }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
        }

        It 'Should construct correct REST API URI' {
            # Act
            New-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestRepo1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/git/repositories' -and
                $Version -eq '7.1' -and
                $Method -eq 'POST'
            }
        }

        It 'Should use POST method when creating repository' {
            # Act
            New-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestRepo1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'POST'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Act
            New-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestRepo1' -Confirm:$false

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Edge Cases and Error Handling' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
        }

        It 'Should handle repository already exists error and attempt to get existing repository' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('RepositoryAlreadyExists: A repository with the name TestRepo1 already exists.')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'RepositoryAlreadyExists', 'ResourceExists', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('RepositoryAlreadyExists: A repository with the name TestRepo1 already exists.')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoRepository { return $mockRepository }

            # Act
            $result = New-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestRepo1' -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'TestRepo1'
            Should -Invoke Get-AdoRepository -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { New-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestRepo1' -Confirm:$false } | Should -Throw '*API Error: Unauthorized*'
        }

        It 'Should skip repository creation when project ID cannot be resolved' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $null }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockRepository }

            # Act
            $result = New-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'NonExistentProject' -Name 'TestRepo1' -Confirm:$false

            # Assert
            $result | Should -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 0
        }
    }
}
