BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoProject' {
    BeforeAll {
        # Sample project data for mocking
        $mockProjects = @{
            value = @(
                @{
                    id           = '12345678-1234-1234-1234-123456789012'
                    name         = 'TestProject1'
                    description  = 'First test project'
                    visibility   = 'Private'
                    state        = 'wellFormed'
                    defaultTeam  = @{
                        id   = 'team-id-1'
                        name = 'TestProject1 Team'
                    }
                    capabilities = @{
                        versioncontrol  = @{
                            sourceControlType = 'Git'
                        }
                        processTemplate = @{
                            templateTypeId = 'adcc42ab-9882-485e-a3ed-7678f01f66bc'
                        }
                    }
                }
                @{
                    id          = '87654321-4321-4321-4321-210987654321'
                    name        = 'TestProject2'
                    description = 'Second test project'
                    visibility  = 'Public'
                    state       = 'wellFormed'
                    defaultTeam = @{
                        id   = 'team-id-2'
                        name = 'TestProject2 Team'
                    }
                }
            )
        }

        $mockSingleProject = @{
            id          = '12345678-1234-1234-1234-123456789012'
            name        = 'TestProject1'
            description = 'First test project'
            visibility  = 'Private'
            state       = 'wellFormed'
            defaultTeam = @{
                id   = 'team-id-1'
                name = 'TestProject1 Team'
            }
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockProjects }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should retrieve all projects when no Name parameter is provided' {
            # Act
            $result = Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org'

            # Assert
            $result | Should -HaveCount 2
            $result[0].name | Should -Be 'TestProject1'
            $result[1].name | Should -Be 'TestProject2'
        }

        It 'Should retrieve a specific project when Name parameter is provided' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleProject }

            # Act
            $result = Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject1'

            # Assert
            $result | Should -HaveCount 1
            $result.name | Should -Be 'TestProject1'
            $result.id | Should -Be '12345678-1234-1234-1234-123456789012'
        }

        It 'Should return project with all expected properties' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleProject }

            # Act
            $result = Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject1'

            # Assert
            $result.id | Should -Be '12345678-1234-1234-1234-123456789012'
            $result.name | Should -Be 'TestProject1'
            $result.description | Should -Be 'First test project'
            $result.visibility | Should -Be 'Private'
            $result.state | Should -Be 'wellFormed'
            $result.defaultTeam | Should -Not -BeNullOrEmpty
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should accept project IDs via pipeline' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleProject }

            # Act
            $result = '12345678-1234-1234-1234-123456789012' | Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be '12345678-1234-1234-1234-123456789012'
        }

        It 'Should include capabilities when IncludeCapabilities switch is used' {
            # Arrange
            $mockWithCapabilities = $mockSingleProject.Clone()
            $mockWithCapabilities.capabilities = @{
                versioncontrol  = @{ sourceControlType = 'Git' }
                processTemplate = @{ templateTypeId = 'adcc42ab-9882-485e-a3ed-7678f01f66bc' }
            }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockWithCapabilities }

            # Act
            $result = Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject1' -IncludeCapabilities

            # Assert
            $result.capabilities | Should -Not -BeNullOrEmpty
            $result.capabilities.versioncontrol.sourceControlType | Should -Be 'Git'
        }

        It 'Should support pagination with Top parameter' {
            # Act
            Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Top 5

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*$top=5*'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockProjects }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Get-AdoProject -CollectionUri 'invalid-uri' } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            $result = Get-AdoProject

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*dev.azure.com/default-org*'
            }

            # Cleanup
            Remove-Item env:DefaultAdoCollectionUri -ErrorAction SilentlyContinue
        }

        It 'Should accept valid StateFilter values' {
            # Act
            Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -StateFilter 'wellFormed'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*stateFilter=wellFormed*'
            }
        }
    }

    Context 'API Interaction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockProjects }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct REST API URI for listing projects' {
            # Act
            Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects' -and
                $Version -eq '7.1' -and
                $Method -eq 'GET'
            }
        }

        It 'Should construct correct REST API URI for specific project' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleProject }

            # Act
            Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects/TestProject1' -and
                $Method -eq 'GET'
            }
        }

        It 'Should call Confirm-Default to validate collection URI default' {
            # Act
            Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org'

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Edge Cases and Error Handling' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should handle empty project list from API' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return @{ value = @() } }

            # Act
            $result = Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org'

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should warn when project does not exist (ProjectDoesNotExistWithNameException)' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('ProjectDoesNotExistWithNameException: The project with ID NonExistentProject does not exist.')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'ProjectDoesNotExist', 'ObjectNotFound', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('ProjectDoesNotExistWithNameException: The project with ID NonExistentProject does not exist.')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act & Assert - Should write warning but not throw
            { Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'NonExistentProject' -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org' } | Should -Throw '*API Error: Unauthorized*'
        }

        It 'Should iterate over continuation tokens returned by the API' {
            # Arrange
            $firstPage = @{
                value             = @($mockProjects.value[0])
                continuationToken = 'token123'
            }
            $secondPage = @{
                value             = @($mockProjects.value[1])
                continuationToken = $null
            }
            $script:invokeCount = 0

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                $script:invokeCount++
                if ($script:invokeCount -eq 1) {
                    return $firstPage
                }
                return $secondPage
            }

            # Act
            $result = Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Top 1

            # Assert
            $result | Should -HaveCount 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*continuationToken=token123*'
            }
        }

        It 'Should reuse base query parameters when paging' {
            # Arrange
            $firstPage = @{
                value             = @($mockProjects.value[0])
                continuationToken = 'token123'
            }
            $secondPage = @{
                value             = @($mockProjects.value[1])
                continuationToken = $null
            }
            $script:invokeCount = 0

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                $script:invokeCount++
                if ($script:invokeCount -eq 1) {
                    return $firstPage
                }
                return $secondPage
            }

            # Act
            Get-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Top 1

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -eq '$top=1'
            }
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -eq '$top=1&continuationToken=token123'
            }
        }
    }
}
