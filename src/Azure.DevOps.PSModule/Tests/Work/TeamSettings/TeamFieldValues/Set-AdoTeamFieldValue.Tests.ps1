BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Set-AdoTeamFieldValue' {
    BeforeAll {
        # Sample response data for mocking
        $mockTeamFieldValueResponse = @{
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
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockTeamFieldValueResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should update team field values for specified team' {
            # Arrange
            $values = @(
                @{
                    value           = 'my-project-1\my-team-1'
                    includeChildren = $false
                }
            )

            # Act
            $result = Set-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -TeamName 'my-team-1' -DefaultValue 'my-project-1\my-team-1' -Values $values -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.defaultValue | Should -Be 'my-project-1\my-team-1'
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should update team field values for default team when TeamName not specified' {
            # Arrange
            $values = @(
                @{
                    value           = 'my-project-1'
                    includeChildren = $true
                }
            )

            # Act
            $result = Set-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -DefaultValue 'my-project-1' -Values $values -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/my-project-1/_apis/work/teamsettings/teamfieldvalues'
            }
        }

        It 'Should construct correct URI with team name' {
            # Arrange
            $values = @(
                @{
                    value           = 'TestProject\TestTeam'
                    includeChildren = $false
                }
            )

            # Act
            Set-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'TestTeam' -DefaultValue 'TestProject\TestTeam' -Values $values -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/TestTeam/_apis/work/teamsettings/teamfieldvalues'
            }
        }

        It 'Should use correct HTTP method' {
            # Arrange
            $values = @(
                @{
                    value           = 'TestProject'
                    includeChildren = $false
                }
            )

            # Act
            Set-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -DefaultValue 'TestProject' -Values $values -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'PATCH'
            }
        }

        It 'Should return team field value with all expected properties' {
            # Arrange
            $values = @(
                @{
                    value           = 'my-project-1\my-team-1'
                    includeChildren = $false
                }
            )

            # Act
            $result = Set-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -TeamName 'my-team-1' -DefaultValue 'my-project-1\my-team-1' -Values $values -Confirm:$false

            # Assert
            $result.defaultValue | Should -Be 'my-project-1\my-team-1'
            $result.field | Should -Not -BeNullOrEmpty
            $result.values | Should -Not -BeNullOrEmpty
            $result.projectName | Should -Be 'my-project-1'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should support multiple field values' {
            # Arrange
            $values = @(
                @{
                    value           = 'my-project-1\my-team-1'
                    includeChildren = $false
                }
                @{
                    value           = 'my-project-1\my-team-1\SubArea'
                    includeChildren = $true
                }
            )

            # Act
            $result = Set-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'my-project-1' -TeamName 'my-team-1' -DefaultValue 'my-project-1\my-team-1' -Values $values -Confirm:$false

            # Assert
            $result.values | Should -HaveCount 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should use correct API version by default' {
            # Arrange
            $values = @(
                @{
                    value           = 'TestProject'
                    includeChildren = $false
                }
            )

            # Act
            Set-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -DefaultValue 'TestProject' -Values $values -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should use default CollectionUri from environment' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'
            $env:DefaultAdoProject = 'DefaultProject'
            $values = @(
                @{
                    value           = 'DefaultProject'
                    includeChildren = $false
                }
            )

            # Act
            Set-AdoTeamFieldValue -DefaultValue 'DefaultProject' -Values $values -Confirm:$false

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
                DefaultValue  = 'my-project-1\my-team-1'
                Values        = @(
                    @{
                        value           = 'my-project-1\my-team-1'
                        includeChildren = $false
                    }
                )
            }

            # Act
            $result = $teamInput | Set-AdoTeamFieldValue -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should accept pipeline input using TeamId and ProjectId aliases' {
            # Arrange
            $teamInput = [PSCustomObject]@{
                CollectionUri = 'https://dev.azure.com/my-org'
                ProjectId     = 'my-project-1'
                TeamId        = 'my-team-1'
                DefaultValue  = 'my-project-1\my-team-1'
                Values        = @(
                    @{
                        value           = 'my-project-1\my-team-1'
                        includeChildren = $false
                    }
                )
            }

            # Act
            $result = $teamInput | Set-AdoTeamFieldValue -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*my-project-1/my-team-1/*'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockTeamFieldValueResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should validate CollectionUri format' {
            # Arrange
            $values = @(
                @{
                    value           = 'TestProject'
                    includeChildren = $false
                }
            )

            # Act & Assert
            { Set-AdoTeamFieldValue -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -DefaultValue 'TestProject' -Values $values -Confirm:$false } | Should -Throw
        }

        It 'Should validate mandatory DefaultValue parameter via metadata' {
            # Arrange
            $metadata = (Get-Command Set-AdoTeamFieldValue).Parameters['DefaultValue'].Attributes | Where-Object { $_ -is [Parameter] }

            # Assert
            $metadata.Mandatory | Should -Be $true
        }

        It 'Should validate mandatory Values parameter via metadata' {
            # Arrange
            $metadata = (Get-Command Set-AdoTeamFieldValue).Parameters['Values'].Attributes | Where-Object { $_ -is [Parameter] }

            # Assert
            $metadata.Mandatory | Should -Be $true
        }

        It 'Should throw error when value property is missing' {
            # Arrange
            $values = @(
                @{
                    includeChildren = $false
                }
            )

            # Act & Assert
            { Set-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -DefaultValue 'TestProject' -Values $values -Confirm:$false -ErrorAction Stop } | Should -Throw "*'value' property is required*"
        }

        It 'Should throw error when value property is empty' {
            # Arrange
            $values = @(
                @{
                    value           = ''
                    includeChildren = $false
                }
            )

            # Act & Assert
            { Set-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -DefaultValue 'TestProject' -Values $values -Confirm:$false -ErrorAction Stop } | Should -Throw "*'value' property is required*"
        }

        It 'Should throw error when includeChildren property is missing' {
            # Arrange
            $values = @(
                @{
                    value = 'TestProject'
                }
            )

            # Act & Assert
            { Set-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -DefaultValue 'TestProject' -Values $values -Confirm:$false -ErrorAction Stop } | Should -Throw "*'includeChildren' property must be of type bool*"
        }

        It 'Should throw error when includeChildren property is not boolean' {
            # Arrange
            $values = @(
                @{
                    value           = 'TestProject'
                    includeChildren = 'true'
                }
            )

            # Act & Assert
            { Set-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -DefaultValue 'TestProject' -Values $values -Confirm:$false -ErrorAction Stop } | Should -Throw "*'includeChildren' property must be of type bool*"
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

            $values = @(
                @{
                    value           = 'NonExistent\Team'
                    includeChildren = $false
                }
            )

            # Act
            $result = Set-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -TeamName 'NonExistentTeam' -DefaultValue 'NonExistent\Team' -Values $values -Confirm:$false -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should propagate non-NotFoundException errors' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'Unexpected API error' }

            $values = @(
                @{
                    value           = 'TestProject'
                    includeChildren = $false
                }
            )

            # Act & Assert
            { Set-AdoTeamFieldValue -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -DefaultValue 'TestProject' -Values $values -Confirm:$false -ErrorAction Stop } | Should -Throw 'Unexpected API error'
        }
    }
}
