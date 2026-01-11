BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'New-AdoEnvironment' {
    BeforeAll {
        # Sample environment creation response
        $mockCreatedEnvironment = @{
            id          = 1
            name        = 'NewEnvironment'
            description = 'New environment description'
            createdBy   = @{ id = 'user1' }
            createdOn   = '2024-01-01T00:00:00Z'
        }

        $mockExistingEnvironment = @{
            value = @(
                @{
                    id          = 2
                    name        = 'ExistingEnvironment'
                    description = 'Existing environment'
                    createdBy   = @{ id = 'user2' }
                    createdOn   = '2024-01-02T00:00:00Z'
                }
            )
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCreatedEnvironment }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should create a new environment with name and description' {
            # Act
            $result = New-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'NewEnvironment' -Description 'New environment description' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            $result.name | Should -Be 'NewEnvironment'
            $result.description | Should -Be 'New environment description'
        }

        It 'Should create environment with only name parameter' {
            # Act
            $result = New-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'NewEnvironment' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'NewEnvironment'
        }

        It 'Should return environment with all expected properties' {
            # Act
            $result = New-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'NewEnvironment' -Description 'Test' -Confirm:$false

            # Assert
            $result.id | Should -Be 1
            $result.name | Should -Be 'NewEnvironment'
            $result.description | Should -Be 'New environment description'
            $result.createdBy.id | Should -Be 'user1'
            $result.createdOn | Should -Be '2024-01-01T00:00:00Z'
            $result.projectName | Should -Be 'TestProject'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should accept environment names via pipeline' {
            # Act
            $result = 'NewEnvironment' | New-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'NewEnvironment'
        }

        It 'Should return existing environment when it already exists' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('EnvironmentExistsException')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'EnvironmentExists', 'ResourceExists', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('EnvironmentExistsException: Environment ExistingEnvironment already exists.')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                if ($Method -eq 'POST') {
                    throw $errorRecord
                } else {
                    return $mockExistingEnvironment
                }
            }

            # Act
            $result = New-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'ExistingEnvironment' -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 2
            $result.name | Should -Be 'ExistingEnvironment'
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCreatedEnvironment }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { New-AdoEnvironment -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -Name 'TestEnv' -Confirm:$false } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            $result = New-AdoEnvironment -ProjectName 'TestProject' -Name 'TestEnv' -Confirm:$false

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
            $result = New-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestEnv' -Confirm:$false

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
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCreatedEnvironment }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct REST API URI for creating environment' {
            # Act
            New-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestEnv' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/pipelines/environments' -and
                $Version -eq '7.2-preview.1' -and
                $Method -eq 'POST'
            }
        }

        It 'Should send correct body with name and description' {
            # Act
            New-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestEnv' -Description 'Test description' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Body.name -eq 'TestEnv' -and
                $Body.description -eq 'Test description'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Act
            New-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestEnv' -Confirm:$false

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should propagate errors other than EnvironmentExistsException' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { New-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestEnv' -Confirm:$false } | Should -Throw '*API Error: Unauthorized*'
        }
    }
}
