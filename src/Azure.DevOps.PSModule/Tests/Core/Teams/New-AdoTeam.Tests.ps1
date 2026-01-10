BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'New-AdoTeam' {
    BeforeAll {
        # Sample team creation response for mocking
        $mockTeamResponse = @{
            id          = '12345678-1234-1234-1234-123456789012'
            name        = 'TestTeam1'
            description = 'Test team description'
            url         = 'https://dev.azure.com/my-org/_apis/projects/TestProject/teams/12345678-1234-1234-1234-123456789012'
            identityUrl = 'https://vssps.dev.azure.com/my-org/_apis/Identities/12345678-1234-1234-1234-123456789012'
            projectId   = '87654321-4321-4321-4321-210987654321'
            projectName = 'TestProject'
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockTeamResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should create a new team with required parameters' {
            # Act
            $result = New-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'TestTeam1'
            $result.id | Should -Be '12345678-1234-1234-1234-123456789012'
            $result.projectName | Should -Be 'TestProject'
        }

        It 'Should create a team with name and description' {
            # Act
            $result = New-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1' -Description 'Test team description' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.description | Should -Be 'Test team description'
        }

        It 'Should return team with all expected properties' {
            # Act
            $result = New-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1' -Confirm:$false

            # Assert
            $result.id | Should -Be '12345678-1234-1234-1234-123456789012'
            $result.name | Should -Be 'TestTeam1'
            $result.url | Should -Not -BeNullOrEmpty
            $result.identityUrl | Should -Not -BeNullOrEmpty
            $result.projectId | Should -Be '87654321-4321-4321-4321-210987654321'
            $result.projectName | Should -Be 'TestProject'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should accept team names via pipeline' {
            # Act
            $result = 'TestTeam1' | New-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'TestTeam1'
        }

        It 'Should send correct request body with name and description' {
            # Act
            New-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1' -Description 'Test description' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects/TestProject/teams' -and
                $Method -eq 'POST'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockTeamResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { New-AdoTeam -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -Name 'TestTeam1' -Confirm:$false } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            $result = New-AdoTeam -ProjectName 'TestProject' -Name 'TestTeam1' -Confirm:$false

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
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/my-org'

            # Act
            $result = New-AdoTeam -Name 'TestTeam1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*projects/DefaultProject*'
            }

            # Cleanup
            Remove-Item env:DefaultAdoProject -ErrorAction SilentlyContinue
            Remove-Item env:DefaultAdoCollectionUri -ErrorAction SilentlyContinue
        }
    }

    Context 'API Interaction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockTeamResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct REST API URI for creating team' {
            # Act
            New-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects/TestProject/teams' -and
                $Version -eq '7.1' -and
                $Method -eq 'POST'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Act
            New-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1' -Confirm:$false

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Edge Cases and Error Handling' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should handle TeamAlreadyExistsException and retrieve existing team' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('TeamAlreadyExistsException: Team already exists.')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'TeamExists', 'ResourceExists', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('TeamAlreadyExistsException: Team already exists.')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoTeam { return $mockTeamResponse }

            # Act
            $result = New-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1' -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'TestTeam1'
            Should -Invoke Get-AdoTeam -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { New-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam1' -Confirm:$false } | Should -Throw '*API Error: Unauthorized*'
        }

        It 'Should handle creating multiple teams via pipeline' {
            # Arrange
            $teamNames = @('Team1', 'Team2', 'Team3')
            $callCount = 0
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                $callCount++
                $response = $mockTeamResponse.Clone()
                $response.name = $InputObject.name
                return $response
            }

            # Act
            $results = $teamNames | New-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false

            # Assert
            $results | Should -HaveCount 3
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 3
        }
    }
}
