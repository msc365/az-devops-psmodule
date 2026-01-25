BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Add-AdoTeamIteration' {
    BeforeAll {
        # Sample iteration response data for mocking
        $mockIterationResponse = @{
            id         = '11111111-1111-1111-1111-111111111111'
            name       = 'Sprint 1'
            attributes = @{
                startDate  = '2024-01-01T00:00:00Z'
                finishDate = '2024-01-14T23:59:59Z'
                timeFrame  = 'current'
            }
            url        = 'https://dev.azure.com/my-org/_apis/work/teamsettings/iterations/11111111-1111-1111-1111-111111111111'
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockIterationResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should add iteration to team successfully' {
            # Act
            $result = Add-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -Id '11111111-1111-1111-1111-111111111111' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be '11111111-1111-1111-1111-111111111111'
            $result.name | Should -Be 'Sprint 1'
        }

        It 'Should construct correct API URI' {
            # Act
            Add-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -Id '11111111-1111-1111-1111-111111111111' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/TestTeam/_apis/work/teamsettings/iterations'
            }
        }

        It 'Should use POST method' {
            # Act
            Add-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -Id '11111111-1111-1111-1111-111111111111' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'POST'
            }
        }

        It 'Should return iteration with all expected properties' {
            # Act
            $result = Add-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -Id '11111111-1111-1111-1111-111111111111' -Confirm:$false

            # Assert
            $result.id | Should -Be '11111111-1111-1111-1111-111111111111'
            $result.name | Should -Be 'Sprint 1'
            $result.attributes | Should -Not -BeNullOrEmpty
            $result.teamName | Should -Be 'TestTeam'
            $result.projectName | Should -Be 'TestProject'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should use default API version 7.1' {
            # Act
            Add-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -Id '11111111-1111-1111-1111-111111111111' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should use custom API version when specified' {
            # Act
            Add-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -Id '11111111-1111-1111-1111-111111111111' -Version '7.2-preview.1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should use default CollectionUri from environment' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'
            $env:DefaultAdoProject = 'DefaultProject'

            # Act
            Add-AdoTeamIteration -TeamName 'TestTeam' -Id '11111111-1111-1111-1111-111111111111' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like 'https://dev.azure.com/default-org/DefaultProject/*'
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should accept iteration ID via pipeline' {
            # Arrange
            $iterationId = '11111111-1111-1111-1111-111111111111'

            # Act
            $result = $iterationId | Add-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be '11111111-1111-1111-1111-111111111111'
        }

        It 'Should accept iteration object with properties via pipeline' {
            # Arrange
            $iteration = [PSCustomObject]@{
                Id            = '11111111-1111-1111-1111-111111111111'
                TeamName      = 'TestTeam'
                ProjectName   = 'TestProject'
                CollectionUri = 'https://dev.azure.com/my-org'
            }

            # Act
            $result = $iteration | Add-AdoTeamIteration -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockIterationResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Add-AdoTeamIteration -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -TeamName 'TestTeam' -Id '11111111-1111-1111-1111-111111111111' -Confirm:$false } | Should -Throw
        }

        It 'Should handle mandatory TeamName parameter via metadata' {
            # Arrange
            $metadata = (Get-Command Add-AdoTeamIteration).Parameters['TeamName'].Attributes | Where-Object { $_ -is [Parameter] }

            # Assert
            $metadata.Mandatory | Should -Be $true
        }

        It 'Should handle mandatory Id parameter via metadata' {
            # Arrange
            $metadata = (Get-Command Add-AdoTeamIteration).Parameters['Id'].Attributes | Where-Object { $_ -is [Parameter] }

            # Assert
            $metadata.Mandatory | Should -Be $true
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should handle InvalidTeamSettingsIterationException' {
            # Arrange
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [Exception]::new('Invalid iteration'),
                'InvalidTeamSettingsIterationException',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $null
            )
            $errorRecord.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message": "InvalidTeamSettingsIterationException"}')

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act
            $result = Add-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -Id 'invalid-iteration-id' -Confirm:$false -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should propagate non-iteration-specific errors' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'Unexpected API error' }

            # Act & Assert
            { Add-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -Id '11111111-1111-1111-1111-111111111111' -Confirm:$false -ErrorAction Stop } | Should -Throw 'Unexpected API error'
        }
    }
}
