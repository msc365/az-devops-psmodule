BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoProcess' {
    BeforeAll {
        # Sample process data for mocking
        $mockProcesses = @{
            value = @(
                @{
                    id          = 'adcc42ab-9882-485e-a3ed-7678f01f66bc'
                    name        = 'Agile'
                    description = 'This template is flexible and will work great for most teams using Agile planning methods.'
                    url         = 'https://dev.azure.com/my-org/_apis/process/processes/adcc42ab-9882-485e-a3ed-7678f01f66bc'
                    type        = 'system'
                    isDefault   = $true
                }
                @{
                    id          = '6b724908-ef14-45cf-84f8-768b5384da45'
                    name        = 'Scrum'
                    description = 'This template is for teams who follow the Scrum framework.'
                    url         = 'https://dev.azure.com/my-org/_apis/process/processes/6b724908-ef14-45cf-84f8-768b5384da45'
                    type        = 'system'
                    isDefault   = $false
                }
                @{
                    id          = '27450541-8e31-4150-9947-dc59f998fc01'
                    name        = 'CMMI'
                    description = 'This template is for formal project methods and tracking.'
                    url         = 'https://dev.azure.com/my-org/_apis/process/processes/27450541-8e31-4150-9947-dc59f998fc01'
                    type        = 'system'
                    isDefault   = $false
                }
                @{
                    id          = 'b8a3a935-7e91-48b8-a94c-606d37c3e9f2'
                    name        = 'Basic'
                    description = 'This template is for teams starting with Azure Boards.'
                    url         = 'https://dev.azure.com/my-org/_apis/process/processes/b8a3a935-7e91-48b8-a94c-606d37c3e9f2'
                    type        = 'system'
                    isDefault   = $false
                }
            )
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockProcesses }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should retrieve all processes when no Name parameter is provided' {
            # Act
            $result = Get-AdoProcess -CollectionUri 'https://dev.azure.com/my-org'

            # Assert
            $result | Should -HaveCount 4
            $result[0].name | Should -Be 'Agile'
            $result[1].name | Should -Be 'Scrum'
            $result[2].name | Should -Be 'CMMI'
            $result[3].name | Should -Be 'Basic'
        }

        It 'Should retrieve a specific process when Name parameter is provided' {
            # Act
            $result = Get-AdoProcess -CollectionUri 'https://dev.azure.com/my-org' -Name 'Agile'

            # Assert
            $result | Should -HaveCount 1
            $result.name | Should -Be 'Agile'
            $result.id | Should -Be 'adcc42ab-9882-485e-a3ed-7678f01f66bc'
        }

        It 'Should return process with all expected properties' {
            # Act
            $result = Get-AdoProcess -CollectionUri 'https://dev.azure.com/my-org' -Name 'Scrum'

            # Assert
            $result.id | Should -Be '6b724908-ef14-45cf-84f8-768b5384da45'
            $result.name | Should -Be 'Scrum'
            $result.description | Should -Be 'This template is for teams who follow the Scrum framework.'
            $result.url | Should -Be 'https://dev.azure.com/my-org/_apis/process/processes/6b724908-ef14-45cf-84f8-768b5384da45'
            $result.type | Should -Be 'system'
            $result.isDefault | Should -Be $false
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should accept process names via pipeline' {
            # Act
            $result = @('Agile', 'Scrum') | Get-AdoProcess -CollectionUri 'https://dev.azure.com/my-org'

            # Assert
            $result | Should -HaveCount 2
            $result[0].name | Should -Be 'Agile'
            $result[1].name | Should -Be 'Scrum'
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockProcesses }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Get-AdoProcess -CollectionUri 'invalid-uri' } | Should -Throw
        }

        It 'Should accept only valid process names' {
            # Act & Assert - The ValidateSet should prevent invalid names
            { Get-AdoProcess -CollectionUri 'https://dev.azure.com/my-org' -Name 'InvalidProcess' } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            $result = Get-AdoProcess -Name 'Agile'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*dev.azure.com/default-org*'
            }

            # Cleanup
            Remove-Item env:DefaultAdoCollectionUri -ErrorAction SilentlyContinue
        }

        It 'Should validate API version parameter' {
            # Act & Assert - The ValidateSet should prevent invalid versions
            { Get-AdoProcess -CollectionUri 'https://dev.azure.com/my-org' -Version '8.0' } | Should -Throw
        }
    }

    Context 'API Interaction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockProcesses }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct REST API URI' {
            # Act
            Get-AdoProcess -CollectionUri 'https://dev.azure.com/my-org'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/process/processes' -and
                $Version -eq '7.1' -and
                $Method -eq 'GET'
            }
        }

        It 'Should use specified API version' {
            # Act
            Get-AdoProcess -CollectionUri 'https://dev.azure.com/my-org' -Version '7.2-preview.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should call Confirm-Default to validate collection URI default' {
            # Act
            Get-AdoProcess -CollectionUri 'https://dev.azure.com/my-org'

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Edge Cases and Error Handling' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should return empty result when process name does not match' {
            # Arrange - Mock with a process that won't match
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return @{
                    value = @(
                        @{
                            id          = 'test-id'
                            name        = 'NotTheOneWeWant'
                            description = 'Test'
                            url         = 'https://test'
                            type        = 'system'
                            isDefault   = $false
                        }
                    )
                }
            }

            # Act
            $result = Get-AdoProcess -CollectionUri 'https://dev.azure.com/my-org' -Name 'Agile'

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should handle empty process list from API' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return @{ value = @() } }

            # Act
            $result = Get-AdoProcess -CollectionUri 'https://dev.azure.com/my-org'

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should propagate errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { Get-AdoProcess -CollectionUri 'https://dev.azure.com/my-org' } | Should -Throw '*API Error: Unauthorized*'
        }
    }

    Context 'Verbose and Debug Output Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockProcesses }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should write verbose messages when Verbose flag is used' {
            # Act - Capture verbose output
            $verboseOutput = Get-AdoProcess -CollectionUri 'https://dev.azure.com/my-org' -Verbose 4>&1

            # Assert - Verbose messages should be written
            $verboseOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } | Should -Not -BeNullOrEmpty
        }
    }
}
