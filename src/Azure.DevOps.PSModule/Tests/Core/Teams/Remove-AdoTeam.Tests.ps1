BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Remove-AdoTeam' {
    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should remove a team with required parameters' {
            # Act
            Remove-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should remove a team by ID' {
            # Act
            Remove-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name '12345678-1234-1234-1234-123456789012' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*12345678-1234-1234-1234-123456789012*'
            }
        }

        It 'Should accept team names via pipeline' {
            # Act
            'TestTeam1' | Remove-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should remove multiple teams via pipeline' {
            # Arrange
            $teamNames = @('Team1', 'Team2', 'Team3')

            # Act
            $teamNames | Remove-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false

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
            { Remove-AdoTeam -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -Name 'TestTeam1' -Confirm:$false } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            Remove-AdoTeam -ProjectName 'TestProject' -Name 'TestTeam1' -Confirm:$false

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
            Remove-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestTeam1' -Confirm:$false

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
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct REST API URI for deleting team' {
            # Act
            Remove-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects/TestProject/teams/TestTeam1' -and
                $Version -eq '7.1' -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Act
            Remove-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1' -Confirm:$false

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should use correct API version when specified' {
            # Act
            Remove-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1' -Version '7.2-preview.3' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.2-preview.3'
            }
        }
    }

    Context 'Edge Cases and Error Handling' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should warn when team does not exist (NotFoundException)' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('NotFoundException: Team does not exist.')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'TeamNotFound', 'ObjectNotFound', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('NotFoundException: Team does not exist.')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act & Assert - Should write warning but not throw
            { Remove-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'NonExistentTeam' -WarningAction SilentlyContinue -Confirm:$false } | Should -Not -Throw
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { Remove-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1' -Confirm:$false } | Should -Throw '*API Error: Unauthorized*'
        }

        It 'Should handle removing team with special characters in name' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { }

            # Act
            Remove-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'Team-With-Dashes_And_Underscores' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*Team-With-Dashes_And_Underscores*'
            }
        }

        It 'Should handle multiple team removals successfully' {
            # Arrange
            $callCount = 0
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                $callCount++
            }

            # Act
            @('Team1', 'Team2', 'Team3') | Remove-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 3
        }
    }
}
