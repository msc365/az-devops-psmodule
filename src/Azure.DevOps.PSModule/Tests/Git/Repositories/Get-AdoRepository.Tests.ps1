BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoRepository' {
    BeforeAll {
        # Sample repository data for mocking
        $mockRepositories = @{
            value = @(
                @{
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
                @{
                    id            = '22222222-2222-2222-2222-222222222222'
                    name          = 'TestRepo2'
                    project       = @{
                        id   = '87654321-4321-4321-4321-210987654321'
                        name = 'TestProject'
                    }
                    defaultBranch = 'refs/heads/master'
                    url           = 'https://dev.azure.com/my-org/TestProject/_apis/git/repositories/22222222-2222-2222-2222-222222222222'
                    remoteUrl     = 'https://dev.azure.com/my-org/TestProject/_git/TestRepo2'
                }
            )
        }

        $mockSingleRepository = @{
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
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockRepositories }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should retrieve all repositories when no Name parameter is provided' {
            # Act
            $result = Get-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $result | Should -HaveCount 2
            $result[0].name | Should -Be 'TestRepo1'
            $result[1].name | Should -Be 'TestRepo2'
        }

        It 'Should retrieve a specific repository when Name parameter is provided' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleRepository }

            # Act
            $result = Get-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestRepo1'

            # Assert
            $result | Should -HaveCount 1
            $result.name | Should -Be 'TestRepo1'
            $result.id | Should -Be '12345678-1234-1234-1234-123456789012'
        }

        It 'Should return repository with all expected properties' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleRepository }

            # Act
            $result = Get-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestRepo1'

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
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleRepository }

            # Act
            $result = 'TestRepo1' | Get-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'TestRepo1'
        }

        It 'Should support IncludeLinks parameter' {
            # Act
            Get-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -IncludeLinks

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*includeLinks=*true*'
            }
        }

        It 'Should support IncludeHidden parameter' {
            # Act
            Get-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -IncludeHidden

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*includeHidden=*true*'
            }
        }

        It 'Should support IncludeAllUrls parameter' {
            # Act
            Get-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -IncludeAllUrls

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*includeAllUrls=*true*'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockRepositories }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Get-AdoRepository -CollectionUri 'invalid-uri' -ProjectName 'TestProject' } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            $result = Get-AdoRepository -ProjectName 'TestProject'

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
            $result = Get-AdoRepository -CollectionUri 'https://dev.azure.com/my-org'

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
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockRepositories }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct REST API URI for listing repositories' {
            # Act
            Get-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/git/repositories' -and
                $Version -eq '7.1' -and
                $Method -eq 'GET'
            }
        }

        It 'Should construct correct REST API URI for specific repository' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleRepository }

            # Act
            Get-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestRepo1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/git/repositories/TestRepo1' -and
                $Method -eq 'GET'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Act
            Get-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Edge Cases and Error Handling' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should handle empty repository list from API' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return @{ value = @() } }

            # Act
            $result = Get-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should warn when repository does not exist (NotFoundException)' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('NotFoundException: The repository with ID NonExistentRepo does not exist.')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'RepositoryNotFound', 'ObjectNotFound', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('NotFoundException: The repository with ID NonExistentRepo does not exist.')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act & Assert - Should write warning but not throw
            { Get-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'NonExistentRepo' -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { Get-AdoRepository -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' } | Should -Throw '*API Error: Unauthorized*'
        }
    }
}
