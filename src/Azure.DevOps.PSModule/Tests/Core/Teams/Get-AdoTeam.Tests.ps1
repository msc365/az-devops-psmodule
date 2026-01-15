BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoTeam' {
    BeforeAll {
        # Sample team data for mocking
        $mockTeams = @{
            value = @(
                @{
                    id          = '12345678-1234-1234-1234-123456789012'
                    name        = 'TestTeam1'
                    description = 'First test team'
                    url         = 'https://dev.azure.com/my-org/_apis/projects/TestProject/teams/12345678-1234-1234-1234-123456789012'
                    identityUrl = 'https://vssps.dev.azure.com/my-org/_apis/Identities/12345678-1234-1234-1234-123456789012'
                    projectId   = '87654321-4321-4321-4321-210987654321'
                    projectName = 'TestProject'
                }
                @{
                    id          = '22222222-2222-2222-2222-222222222222'
                    name        = 'TestTeam2'
                    description = 'Second test team'
                    url         = 'https://dev.azure.com/my-org/_apis/projects/TestProject/teams/22222222-2222-2222-2222-222222222222'
                    identityUrl = 'https://vssps.dev.azure.com/my-org/_apis/Identities/22222222-2222-2222-2222-222222222222'
                    projectId   = '87654321-4321-4321-4321-210987654321'
                    projectName = 'TestProject'
                }
            )
        }

        $mockSingleTeam = @{
            id          = '12345678-1234-1234-1234-123456789012'
            name        = 'TestTeam1'
            description = 'First test team'
            url         = 'https://dev.azure.com/my-org/_apis/projects/TestProject/teams/12345678-1234-1234-1234-123456789012'
            identityUrl = 'https://vssps.dev.azure.com/my-org/_apis/Identities/12345678-1234-1234-1234-123456789012'
            projectId   = '87654321-4321-4321-4321-210987654321'
            projectName = 'TestProject'
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockTeams }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should retrieve all teams when no Name parameter is provided' {
            # Act
            $result = Get-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $result | Should -HaveCount 2
            $result[0].name | Should -Be 'TestTeam1'
            $result[1].name | Should -Be 'TestTeam2'
        }

        It 'Should retrieve a specific team when Name parameter is provided' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleTeam }

            # Act
            $result = Get-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1'

            # Assert
            $result | Should -HaveCount 1
            $result.name | Should -Be 'TestTeam1'
            $result.id | Should -Be '12345678-1234-1234-1234-123456789012'
        }

        It 'Should return team with all expected properties' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleTeam }

            # Act
            $result = Get-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1'

            # Assert
            $result.id | Should -Be '12345678-1234-1234-1234-123456789012'
            $result.name | Should -Be 'TestTeam1'
            $result.description | Should -Be 'First test team'
            $result.url | Should -Not -BeNullOrEmpty
            $result.identityUrl | Should -Not -BeNullOrEmpty
            $result.projectId | Should -Be '87654321-4321-4321-4321-210987654321'
            $result.projectName | Should -Be 'TestProject'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should accept team names via pipeline' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleTeam }

            # Act
            $result = 'TestTeam1' | Get-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'TestTeam1'
        }

        It 'Should support pagination with Skip parameter' {
            # Act
            Get-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Skip 10

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*$skip=10*'
            }
        }

        It 'Should support pagination with Top parameter' {
            # Act
            Get-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Top 5

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*$top=5*'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockTeams }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Get-AdoTeam -CollectionUri 'invalid-uri' -ProjectName 'TestProject' } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            $result = Get-AdoTeam -ProjectName 'TestProject'

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
            $result = Get-AdoTeam -CollectionUri 'https://dev.azure.com/my-org'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*projects/DefaultProject*'
            }

            # Cleanup
            Remove-Item env:DefaultAdoProject -ErrorAction SilentlyContinue
        }
    }

    Context 'API Interaction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockTeams }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct REST API URI for listing teams' {
            # Act
            Get-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects/TestProject/teams' -and
                $Version -eq '7.1' -and
                $Method -eq 'GET'
            }
        }

        It 'Should construct correct REST API URI for specific team' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleTeam }

            # Act
            Get-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects/TestProject/teams/TestTeam1' -and
                $Method -eq 'GET'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Act
            Get-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Edge Cases and Error Handling' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should handle empty team list from API' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return @{ value = @() } }

            # Act
            $result = Get-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should warn when team does not exist (NotFoundException)' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('NotFoundException: The team with ID NonExistentTeam does not exist.')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'TeamNotFound', 'ObjectNotFound', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('NotFoundException: The team with ID NonExistentTeam does not exist.')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act & Assert - Should write warning but not throw
            { Get-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'NonExistentTeam' -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { Get-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' } | Should -Throw '*API Error: Unauthorized*'
        }
    }
}
