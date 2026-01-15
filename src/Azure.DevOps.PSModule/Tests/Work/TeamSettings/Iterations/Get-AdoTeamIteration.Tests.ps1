BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoTeamIteration' {
    BeforeAll {
        # Sample iteration data for mocking
        $mockIterationsList = @{
            value = @(
                @{
                    id         = '11111111-1111-1111-1111-111111111111'
                    name       = 'Sprint 1'
                    attributes = @{
                        startDate  = '2024-01-01T00:00:00Z'
                        finishDate = '2024-01-14T23:59:59Z'
                        timeFrame  = 'past'
                    }
                    url        = 'https://dev.azure.com/my-org/_apis/work/teamsettings/iterations/11111111-1111-1111-1111-111111111111'
                }
                @{
                    id         = '22222222-2222-2222-2222-222222222222'
                    name       = 'Sprint 2'
                    attributes = @{
                        startDate  = '2024-01-15T00:00:00Z'
                        finishDate = '2024-01-28T23:59:59Z'
                        timeFrame  = 'current'
                    }
                    url        = 'https://dev.azure.com/my-org/_apis/work/teamsettings/iterations/22222222-2222-2222-2222-222222222222'
                }
                @{
                    id         = '33333333-3333-3333-3333-333333333333'
                    name       = 'Sprint 3'
                    attributes = @{
                        startDate  = '2024-01-29T00:00:00Z'
                        finishDate = '2024-02-11T23:59:59Z'
                        timeFrame  = 'future'
                    }
                    url        = 'https://dev.azure.com/my-org/_apis/work/teamsettings/iterations/33333333-3333-3333-3333-333333333333'
                }
            )
        }

        $mockSingleIteration = @{
            id         = '22222222-2222-2222-2222-222222222222'
            name       = 'Sprint 2'
            attributes = @{
                startDate  = '2024-01-15T00:00:00Z'
                finishDate = '2024-01-28T23:59:59Z'
                timeFrame  = 'current'
            }
            url        = 'https://dev.azure.com/my-org/_apis/work/teamsettings/iterations/22222222-2222-2222-2222-222222222222'
        }

        $mockCurrentIterationsList = @{
            value = @(
                @{
                    id         = '22222222-2222-2222-2222-222222222222'
                    name       = 'Sprint 2'
                    attributes = @{
                        startDate  = '2024-01-15T00:00:00Z'
                        finishDate = '2024-01-28T23:59:59Z'
                        timeFrame  = 'current'
                    }
                    url        = 'https://dev.azure.com/my-org/_apis/work/teamsettings/iterations/22222222-2222-2222-2222-222222222222'
                }
            )
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockIterationsList }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should retrieve all team iterations' {
            # Act
            $result = Get-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam'

            # Assert
            $result | Should -HaveCount 3
            $result[0].name | Should -Be 'Sprint 1'
            $result[1].name | Should -Be 'Sprint 2'
            $result[2].name | Should -Be 'Sprint 3'
        }

        It 'Should retrieve iteration by ID' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleIteration }

            # Act
            $result = Get-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -Id '22222222-2222-2222-2222-222222222222'

            # Assert
            $result | Should -HaveCount 1
            $result.id | Should -Be '22222222-2222-2222-2222-222222222222'
            $result.name | Should -Be 'Sprint 2'
        }

        It 'Should filter iterations by current timeframe' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCurrentIterationsList }

            # Act
            $result = Get-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -TimeFrame 'current'

            # Assert
            $result | Should -HaveCount 1
            $result.name | Should -Be 'Sprint 2'
            $result.attributes.timeFrame | Should -Be 'current'
        }

        It 'Should construct correct URI for listing iterations' {
            # Act
            Get-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/TestTeam/_apis/work/teamsettings/iterations'
            }
        }

        It 'Should construct correct URI for specific iteration' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleIteration }

            # Act
            Get-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -Id '22222222-2222-2222-2222-222222222222'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/TestTeam/_apis/work/teamsettings/iterations/22222222-2222-2222-2222-222222222222'
            }
        }

        It 'Should return iteration with all expected properties' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleIteration }

            # Act
            $result = Get-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -Id '22222222-2222-2222-2222-222222222222'

            # Assert
            $result.id | Should -Be '22222222-2222-2222-2222-222222222222'
            $result.name | Should -Be 'Sprint 2'
            $result.attributes | Should -Not -BeNullOrEmpty
            $result.team | Should -Be 'TestTeam'
            $result.project | Should -Be 'TestProject'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should use default CollectionUri from environment' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'
            $env:DefaultAdoProject = 'DefaultProject'

            # Act
            Get-AdoTeamIteration -TeamName 'TestTeam'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like 'https://dev.azure.com/default-org/DefaultProject/*'
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should use correct API version by default' {
            # Act
            Get-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should accept pipeline input via TeamName' {
            # Arrange
            $teamInput = [PSCustomObject]@{
                TeamName      = 'TestTeam'
                CollectionUri = 'https://dev.azure.com/my-org'
                ProjectName   = 'TestProject'
            }

            # Act
            $result = $teamInput | Get-AdoTeamIteration

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockIterationsList }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Get-AdoTeamIteration -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -TeamName 'TestTeam' } | Should -Throw
        }

        It 'Should include timeframe query parameter when specified' {
            # Act
            Get-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -TimeFrame 'future'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -eq '$timeframe=future'
            }
        }

        It 'Should handle mandatory TeamName parameter via metadata' {
            # Arrange
            $metadata = (Get-Command Get-AdoTeamIteration).Parameters['TeamName'].Attributes | Where-Object { $_ -is [Parameter] }

            # Assert
            $metadata.Mandatory | Should -Be $true
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should handle NotFoundException for non-existent iteration' {
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
            $result = Get-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -Id 'nonexistent-id' -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should propagate non-NotFoundException errors' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'Unexpected error' }

            # Act & Assert
            { Get-AdoTeamIteration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -ErrorAction Stop } | Should -Throw 'Unexpected error'
        }
    }
}
