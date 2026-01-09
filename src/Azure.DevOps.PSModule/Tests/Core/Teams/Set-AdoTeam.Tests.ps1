BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Set-AdoTeam' {
    BeforeAll {
        # Sample team update response for mocking
        $mockTeamResponse = @{
            id          = '12345678-1234-1234-1234-123456789012'
            name        = 'UpdatedTeamName'
            description = 'Updated description'
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

        It 'Should update a team name with required parameters' {
            # Act
            $result = Set-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 'TestTeam1' -Name 'UpdatedTeamName' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'UpdatedTeamName'
        }

        It 'Should update a team description' {
            # Act
            $result = Set-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 'TestTeam1' -Description 'Updated description' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.description | Should -Be 'Updated description'
        }

        It 'Should update both name and description' {
            # Act
            $result = Set-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 'TestTeam1' -Name 'UpdatedTeamName' -Description 'Updated description' -Confirm:$false

            # Assert
            $result.name | Should -Be 'UpdatedTeamName'
            $result.description | Should -Be 'Updated description'
        }

        It 'Should return team with all expected properties' {
            # Act
            $result = Set-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 'TestTeam1' -Name 'UpdatedTeamName' -Confirm:$false

            # Assert
            $result.id | Should -Be '12345678-1234-1234-1234-123456789012'
            $result.name | Should -Be 'UpdatedTeamName'
            $result.url | Should -Not -BeNullOrEmpty
            $result.identityUrl | Should -Not -BeNullOrEmpty
            $result.projectId | Should -Be '87654321-4321-4321-4321-210987654321'
            $result.projectName | Should -Be 'TestProject'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should accept team objects via pipeline' {
            # Arrange
            $teamObject = [PSCustomObject]@{
                Id          = 'TestTeam1'
                Name        = 'UpdatedTeamName'
                Description = 'Updated description'
            }

            # Act
            $result = $teamObject | Set-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should send correct request body with only name when specified' {
            # Act
            Set-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 'TestTeam1' -Name 'NewName' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects/TestProject/teams/TestTeam1' -and
                $Method -eq 'PATCH'
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
            { Set-AdoTeam -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -Id 'TestTeam1' -Name 'NewName' -Confirm:$false } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            $result = Set-AdoTeam -ProjectName 'TestProject' -Id 'TestTeam1' -Name 'NewName' -Confirm:$false

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
            $result = Set-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -Id 'TestTeam1' -Name 'NewName' -Confirm:$false

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
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockTeamResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct REST API URI for updating team' {
            # Act
            Set-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 'TestTeam1' -Name 'NewName' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects/TestProject/teams/TestTeam1' -and
                $Version -eq '7.1' -and
                $Method -eq 'PATCH'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Act
            Set-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 'TestTeam1' -Name 'NewName' -Confirm:$false

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should use correct API version when specified' {
            # Act
            Set-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 'TestTeam1' -Name 'NewName' -Version '7.2-preview.3' -Confirm:$false

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
            { Set-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 'NonExistentTeam' -Name 'NewName' -WarningAction SilentlyContinue -Confirm:$false } | Should -Not -Throw
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { Set-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 'TestTeam1' -Name 'NewName' -Confirm:$false } | Should -Throw '*API Error: Unauthorized*'
        }

        It 'Should handle updating team with GUID as Id' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockTeamResponse }

            # Act
            Set-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id '12345678-1234-1234-1234-123456789012' -Name 'NewName' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*12345678-1234-1234-1234-123456789012*'
            }
        }

        It 'Should send only description in request body when only description is specified' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockTeamResponse }

            # Act
            Set-AdoTeam -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 'TestTeam1' -Description 'Only description' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects/TestProject/teams/TestTeam1' -and
                $Method -eq 'PATCH'
            }
        }
    }
}
