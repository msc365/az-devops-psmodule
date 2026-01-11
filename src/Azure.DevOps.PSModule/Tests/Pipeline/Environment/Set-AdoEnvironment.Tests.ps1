BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Set-AdoEnvironment' {
    BeforeAll {
        # Sample environment update response
        $mockUpdatedEnvironment = @{
            id             = 1
            name           = 'UpdatedEnvironment'
            description    = 'Updated description'
            createdBy      = @{ id = 'user1' }
            createdOn      = '2024-01-01T00:00:00Z'
            lastModifiedBy = @{ id = 'user2' }
            lastModifiedOn = '2024-01-05T00:00:00Z'
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockUpdatedEnvironment }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should update environment with name and description' {
            # Act
            $result = Set-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1 -Name 'UpdatedEnvironment' -Description 'Updated description' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            $result.name | Should -Be 'UpdatedEnvironment'
            $result.description | Should -Be 'Updated description'
        }

        It 'Should update environment with only required parameters' {
            # Act
            $result = Set-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1 -Name 'UpdatedEnvironment' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            $result.name | Should -Be 'UpdatedEnvironment'
        }

        It 'Should return environment with all expected properties' {
            # Act
            $result = Set-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1 -Name 'UpdatedEnvironment' -Description 'Test' -Confirm:$false

            # Assert
            $result.id | Should -Be 1
            $result.name | Should -Be 'UpdatedEnvironment'
            $result.description | Should -Be 'Updated description'
            $result.createdBy.id | Should -Be 'user1'
            $result.createdOn | Should -Be '2024-01-01T00:00:00Z'
            $result.lastModifiedBy.id | Should -Be 'user2'
            $result.lastModifiedOn | Should -Be '2024-01-05T00:00:00Z'
            $result.projectName | Should -Be 'TestProject'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should accept environment objects via pipeline' {
            # Act
            $inputObject = [PSCustomObject]@{
                Id          = 1
                Name        = 'UpdatedEnvironment'
                Description = 'Updated description'
            }
            $result = $inputObject | Set-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
        }

        It 'Should support EnvironmentId alias for Id parameter' {
            # Act
            $result = Set-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -EnvironmentId 1 -Name 'UpdatedEnvironment' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
        }

        It 'Should support EnvironmentName alias for Name parameter' {
            # Act
            $result = Set-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1 -EnvironmentName 'UpdatedEnvironment' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'UpdatedEnvironment'
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockUpdatedEnvironment }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Set-AdoEnvironment -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -Id 1 -Name 'TestEnv' -Confirm:$false } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            $result = Set-AdoEnvironment -ProjectName 'TestProject' -Id 1 -Name 'TestEnv' -Confirm:$false

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
            $result = Set-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -Id 1 -Name 'TestEnv' -Confirm:$false

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
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockUpdatedEnvironment }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct REST API URI for updating environment' {
            # Act
            Set-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1 -Name 'UpdatedEnvironment' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/pipelines/environments/1' -and
                $Version -eq '7.2-preview.1' -and
                $Method -eq 'PATCH'
            }
        }

        It 'Should send correct body with name and description' {
            # Act
            Set-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1 -Name 'UpdatedEnvironment' -Description 'Updated description' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Body.Name -eq 'UpdatedEnvironment' -and
                $Body.Description -eq 'Updated description'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Act
            Set-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1 -Name 'UpdatedEnvironment' -Confirm:$false

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
            { Set-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 999 -Name 'TestEnv' -WarningAction SilentlyContinue -Confirm:$false } | Should -Not -Throw
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { Set-AdoEnvironment -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1 -Name 'TestEnv' -Confirm:$false } | Should -Throw '*API Error: Unauthorized*'
        }
    }
}
