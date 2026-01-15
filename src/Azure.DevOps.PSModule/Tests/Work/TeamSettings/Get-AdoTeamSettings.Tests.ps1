BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoTeamSettings' {
    BeforeAll {
        # Sample team settings data for mocking
        $mockTeamSettings = @{
            backlogIteration      = @{
                id   = '12345678-1234-1234-1234-123456789012'
                name = 'Sprint 1'
            }
            backlogVisibilities   = @{
                'Microsoft.EpicCategory'        = $true
                'Microsoft.FeatureCategory'     = $true
                'Microsoft.RequirementCategory' = $true
            }
            bugsBehavior          = 'asRequirements'
            defaultIteration      = @{
                id   = '87654321-4321-4321-4321-210987654321'
                name = 'Sprint 2'
            }
            defaultIterationMacro = '@currentIteration'
            workingDays           = @('monday', 'tuesday', 'wednesday', 'thursday', 'friday')
            url                   = 'https://dev.azure.com/my-org/my-project-1/my-team-1/_apis/work/teamsettings'
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockTeamSettings }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should retrieve team settings for specified team' {
            # Act
            $result = Get-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -Name 'my-team-1'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.bugsBehavior | Should -Be 'asRequirements'
            $result.workingDays | Should -HaveCount 5
            $result.projectName | Should -Be 'my-project-1'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should construct correct URI with team name' {
            # Act
            Get-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/TestTeam/_apis/work/teamsettings'
            }
        }

        It 'Should return team settings with all expected properties' {
            # Act
            $result = Get-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -Name 'my-team-1'

            # Assert
            $result.backlogIteration | Should -Not -BeNullOrEmpty
            $result.backlogVisibilities | Should -Not -BeNullOrEmpty
            $result.bugsBehavior | Should -Be 'asRequirements'
            $result.defaultIteration | Should -Not -BeNullOrEmpty
            $result.defaultIterationMacro | Should -Be '@currentIteration'
            $result.workingDays | Should -Not -BeNullOrEmpty
            $result.url | Should -Not -BeNullOrEmpty
        }

        It 'Should return backlog iteration with correct structure' {
            # Act
            $result = Get-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -Name 'my-team-1'

            # Assert
            $result.backlogIteration.id | Should -Be '12345678-1234-1234-1234-123456789012'
            $result.backlogIteration.name | Should -Be 'Sprint 1'
        }

        It 'Should return backlog visibilities for all categories' {
            # Act
            $result = Get-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -Name 'my-team-1'

            # Assert
            $result.backlogVisibilities.'Microsoft.EpicCategory' | Should -Be $true
            $result.backlogVisibilities.'Microsoft.FeatureCategory' | Should -Be $true
            $result.backlogVisibilities.'Microsoft.RequirementCategory' | Should -Be $true
        }

        It 'Should use correct API version by default' {
            # Act
            Get-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should accept custom API version' {
            # Act
            Get-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam' -Version '7.2-preview.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should use default CollectionUri and ProjectName from environment' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'
            $env:DefaultAdoProject = 'DefaultProject'

            # Act
            Get-AdoTeamSettings -Name 'TestTeam'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like 'https://dev.azure.com/default-org/DefaultProject/*'
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should accept pipeline input with Name parameter' {
            # Arrange
            $teamInput = [PSCustomObject]@{
                CollectionUri = 'https://dev.azure.com/my-org'
                ProjectName   = 'my-project-1'
                Name          = 'my-team-1'
            }

            # Act
            $result = $teamInput | Get-AdoTeamSettings

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should accept pipeline input using TeamId alias' {
            # Arrange
            $teamInput = [PSCustomObject]@{
                CollectionUri = 'https://dev.azure.com/my-org'
                ProjectId     = 'my-project-1'
                TeamId        = 'my-team-1'
            }

            # Act
            $result = $teamInput | Get-AdoTeamSettings

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*my-project-1/my-team-1/*'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockTeamSettings }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Get-AdoTeamSettings -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -Name 'TestTeam' } | Should -Throw
        }

        It 'Should use correct HTTP method' {
            # Act
            Get-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'GET'
            }
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should handle NotFoundException gracefully' {
            # Arrange
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [Exception]::new('Not found'),
                'NotFoundException',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )
            $errorRecord.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message": "NotFoundException"}')

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act
            $result = Get-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'NonExistentTeam' -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should propagate non-NotFoundException errors' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'Unexpected API error' }

            # Act & Assert
            { Get-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam' -ErrorAction Stop } | Should -Throw 'Unexpected API error'
        }
    }
}
