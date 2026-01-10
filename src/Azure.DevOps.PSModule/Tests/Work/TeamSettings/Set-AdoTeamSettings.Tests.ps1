BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Set-AdoTeamSettings' {
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

        It 'Should update team settings with bugs behavior' {
            # Act
            $result = Set-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -Name 'my-team-1' -BugsBehavior 'asRequirements' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.bugsBehavior | Should -Be 'asRequirements'
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should update team settings with working days' {
            # Act
            $result = Set-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -Name 'my-team-1' -WorkingDays @('monday', 'tuesday', 'wednesday') -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'PATCH'
            }
        }

        It 'Should construct correct URI with team name' {
            # Act
            Set-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam' -BugsBehavior 'off' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/TestTeam/_apis/work/teamsettings'
            }
        }

        It 'Should update backlog iteration' {
            # Act
            $result = Set-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -Name 'my-team-1' -BacklogIteration '12345678-1234-1234-1234-123456789012' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should update backlog visibilities' {
            # Arrange
            $visibilities = @{
                'Microsoft.EpicCategory'        = $false
                'Microsoft.FeatureCategory'     = $true
                'Microsoft.RequirementCategory' = $true
            }

            # Act
            $result = Set-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -Name 'my-team-1' -BacklogVisibilities $visibilities -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should update default iteration macro' {
            # Act
            $result = Set-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -Name 'my-team-1' -DefaultIterationMacro '@currentIteration' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should update default iteration' {
            # Act
            $result = Set-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -Name 'my-team-1' -DefaultIteration '87654321-4321-4321-4321-210987654321' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should update multiple settings simultaneously' {
            # Act
            $result = Set-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -Name 'my-team-1' -BugsBehavior 'asTasks' -WorkingDays @('monday', 'wednesday', 'friday') -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'PATCH'
            }
        }

        It 'Should use correct API version by default' {
            # Act
            Set-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam' -BugsBehavior 'off' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should accept custom API version' {
            # Act
            Set-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam' -BugsBehavior 'off' -Version '7.2-preview.1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should accept pipeline input with Name parameter' {
            # Arrange
            $teamInput = [PSCustomObject]@{
                CollectionUri = 'https://dev.azure.com/my-org'
                ProjectName   = 'my-project-1'
                Name          = 'my-team-1'
                BugsBehavior  = 'asRequirements'
            }

            # Act
            $result = $teamInput | Set-AdoTeamSettings -Confirm:$false

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
                BugsBehavior  = 'asRequirements'
            }

            # Act
            $result = $teamInput | Set-AdoTeamSettings -Confirm:$false

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
            { Set-AdoTeamSettings -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -Name 'TestTeam' -BugsBehavior 'off' -Confirm:$false } | Should -Throw
        }

        It 'Should use correct HTTP method' {
            # Act
            Set-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam' -BugsBehavior 'off' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'PATCH'
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
            $result = Set-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'NonExistentTeam' -BugsBehavior 'off' -Confirm:$false -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should propagate non-NotFoundException errors' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'Unexpected API error' }

            # Act & Assert
            { Set-AdoTeamSettings -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Name 'TestTeam' -BugsBehavior 'off' -Confirm:$false -ErrorAction Stop } | Should -Throw 'Unexpected API error'
        }
    }
}
