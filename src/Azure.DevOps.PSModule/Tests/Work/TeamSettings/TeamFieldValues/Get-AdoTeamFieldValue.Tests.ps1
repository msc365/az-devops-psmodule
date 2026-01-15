BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoTeamFieldValue' {
    BeforeAll {
        # Sample team field value data for mocking
        $mockTeamFieldValue = @{
            defaultValue = 'my-project-1\my-team-1'
            field        = @{
                referenceName = 'System.AreaPath'
                url           = 'https://dev.azure.com/my-org/_apis/wit/fields/System.AreaPath'
            }
            values       = @(
                @{
                    value           = 'my-project-1\my-team-1'
                    includeChildren = $false
                }
                @{
                    value           = 'my-project-1\my-team-1\SubArea'
                    includeChildren = $true
                }
            )
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockTeamFieldValue }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should retrieve team field values for specified team' {
            # Act
            $result = Get-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -TeamName 'my-team-1'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.defaultValue | Should -Be 'my-project-1\my-team-1'
            $result.field.referenceName | Should -Be 'System.AreaPath'
            $result.values | Should -HaveCount 2
        }

        It 'Should retrieve team field values for default team when TeamName not specified' {
            # Act
            $result = Get-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/my-project-1/_apis/work/teamsettings/teamfieldvalues'
            }
        }

        It 'Should construct correct URI with team name' {
            # Act
            Get-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/TestTeam/_apis/work/teamsettings/teamfieldvalues'
            }
        }

        It 'Should return team field value with all expected properties' {
            # Act
            $result = Get-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -TeamName 'my-team-1'

            # Assert
            $result.defaultValue | Should -Be 'my-project-1\my-team-1'
            $result.field | Should -Not -BeNullOrEmpty
            $result.values | Should -Not -BeNullOrEmpty
            $result.projectName | Should -Be 'my-project-1'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should return correct field reference information' {
            # Act
            $result = Get-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -TeamName 'my-team-1'

            # Assert
            $result.field.referenceName | Should -Be 'System.AreaPath'
            $result.field.url | Should -Be 'https://dev.azure.com/my-org/_apis/wit/fields/System.AreaPath'
        }

        It 'Should return values with includeChildren property' {
            # Act
            $result = Get-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -TeamName 'my-team-1'

            # Assert
            $result.values[0].includeChildren | Should -Be $false
            $result.values[1].includeChildren | Should -Be $true
        }

        It 'Should use correct API version by default' {
            # Act
            Get-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should use default CollectionUri from environment' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'
            $env:DefaultAdoProject = 'DefaultProject'

            # Act
            Get-AdoTeamFieldValue

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like 'https://dev.azure.com/default-org/DefaultProject/*'
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should accept pipeline input with TeamName' {
            # Arrange
            $teamInput = [PSCustomObject]@{
                CollectionUri = 'https://dev.azure.com/my-org'
                ProjectName   = 'my-project-1'
                TeamName      = 'my-team-1'
            }

            # Act
            $result = $teamInput | Get-AdoTeamFieldValue

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
            $result = $teamInput | Get-AdoTeamFieldValue

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*my-project-1/my-team-1/*'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockTeamFieldValue }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Get-AdoTeamFieldValue -CollectionUri 'invalid-uri' -ProjectName 'TestProject' } | Should -Throw
        }

        It 'Should use correct HTTP method' {
            # Act
            Get-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

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
            $result = Get-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'NonExistentTeam' -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should propagate non-NotFoundException errors' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'Unexpected API error' }

            # Act & Assert
            { Get-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ErrorAction Stop } | Should -Throw 'Unexpected API error'
        }
    }
}
