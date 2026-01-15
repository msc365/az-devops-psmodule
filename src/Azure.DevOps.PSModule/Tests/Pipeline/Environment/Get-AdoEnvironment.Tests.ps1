BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoEnvironment' {
    BeforeAll {
        # Sample environment data for mocking
        $mockEnvironments = @{
            value = @(
                @{
                    id             = 1
                    name           = 'TestEnvironment1'
                    description    = 'Test environment 1'
                    createdBy      = @{ id = 'user1' }
                    createdOn      = '2024-01-01T00:00:00Z'
                    lastModifiedBy = @{ id = 'user1' }
                    lastModifiedOn = '2024-01-02T00:00:00Z'
                }
                @{
                    id             = 2
                    name           = 'TestEnvironment2'
                    description    = 'Test environment 2'
                    createdBy      = @{ id = 'user2' }
                    createdOn      = '2024-01-03T00:00:00Z'
                    lastModifiedBy = @{ id = 'user2' }
                    lastModifiedOn = '2024-01-04T00:00:00Z'
                }
            )
        }

        $mockSingleEnvironment = @{
            id             = 1
            name           = 'TestEnvironment1'
            description    = 'Test environment 1'
            createdBy      = @{ id = 'user1' }
            createdOn      = '2024-01-01T00:00:00Z'
            lastModifiedBy = @{ id = 'user1' }
            lastModifiedOn = '2024-01-02T00:00:00Z'
            resources      = @(
                @{ id = 'res1'; name = 'Resource1' }
            )
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockEnvironments }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should retrieve all environments when no parameters are provided' {
            # Act
            $result = Get-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $result | Should -HaveCount 2
            $result[0].name | Should -Be 'TestEnvironment1'
            $result[1].name | Should -Be 'TestEnvironment2'
        }

        It 'Should retrieve a specific environment by Id' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleEnvironment }

            # Act
            $result = Get-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1

            # Assert
            $result | Should -HaveCount 1
            $result.name | Should -Be 'TestEnvironment1'
            $result.id | Should -Be 1
        }

        It 'Should return environment with all expected properties' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleEnvironment }

            # Act
            $result = Get-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1

            # Assert
            $result.id | Should -Be 1
            $result.name | Should -Be 'TestEnvironment1'
            $result.description | Should -Be 'Test environment 1'
            $result.createdBy.id | Should -Be 'user1'
            $result.createdOn | Should -Be '2024-01-01T00:00:00Z'
            $result.lastModifiedBy.id | Should -Be 'user1'
            $result.lastModifiedOn | Should -Be '2024-01-02T00:00:00Z'
            $result.projectName | Should -Be 'TestProject'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should accept environment Ids via pipeline' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleEnvironment }

            # Act
            $result = 1 | Get-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
        }

        It 'Should filter by Name parameter' {
            # Act
            Get-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestEnvironment1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*name=TestEnvironment1*'
            }
        }

        It 'Should support Top parameter for pagination' {
            # Act
            Get-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Top 5

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*$top=5*'
            }
        }

        It 'Should include resourceReferences when Expands parameter is set' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleEnvironment }

            # Act
            $result = Get-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1 -Expands 'resourceReferences'

            # Assert
            $result.resources | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*expands=resourceReferences*'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockEnvironments }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Get-AdoEnvironment -CollectionUri 'invalid-uri' -ProjectName 'TestProject' } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            $result = Get-AdoEnvironment -ProjectName 'TestProject'

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
            $result = Get-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org'

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
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockEnvironments }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct REST API URI for listing environments' {
            # Act
            Get-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/pipelines/environments' -and
                $Version -eq '7.2-preview.1' -and
                $Method -eq 'GET'
            }
        }

        It 'Should construct correct REST API URI for specific environment by Id' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleEnvironment }

            # Act
            Get-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/pipelines/environments/1' -and
                $Method -eq 'GET'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Act
            Get-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should handle empty environment list from API' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return @{ value = @() } }

            # Act
            $result = Get-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should warn when environment does not exist (EnvironmentNotFoundException)' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('EnvironmentNotFoundException')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'EnvironmentNotFound', 'ObjectNotFound', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('EnvironmentNotFoundException: The environment with ID 999 does not exist.')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act & Assert - Should write warning but not throw
            { Get-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 999 -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { Get-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' } | Should -Throw '*API Error: Unauthorized*'
        }
    }
}
