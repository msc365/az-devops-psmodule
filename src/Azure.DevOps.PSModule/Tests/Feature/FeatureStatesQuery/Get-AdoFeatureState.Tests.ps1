BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoFeatureState' {
    BeforeAll {
        # Sample feature state data for mocking
        $mockFeatureStates = @{
            featureStates = @(
                @{
                    featureId = 'ms.vss-work.agile'
                    state     = 1
                }
                @{
                    featureId = 'ms.vss-code.version-control'
                    state     = 1
                }
                @{
                    featureId = 'ms.vss-build.pipelines'
                    state     = 0
                }
                @{
                    featureId = 'ms.vss-test-web.test'
                    state     = 1
                }
                @{
                    featureId = 'ms.azure-artifacts.feature'
                    state     = 0
                }
            )
        }

        $mockProject = @{
            id   = '12345678-1234-1234-1234-123456789012'
            name = 'TestProject'
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockFeatureStates }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should retrieve all feature states for a project' {
            # Act
            $result = Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $result | Should -HaveCount 5
            $result[0].feature | Should -Be 'Boards'
            $result[1].feature | Should -Be 'Repos'
            $result[2].feature | Should -Be 'Pipelines'
            $result[3].feature | Should -Be 'TestPlans'
            $result[4].feature | Should -Be 'Artifacts'
        }

        It 'Should return feature states with correct enabled/disabled values' {
            # Act
            $result = Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $result[0].state | Should -Be 'enabled'
            $result[1].state | Should -Be 'enabled'
            $result[2].state | Should -Be 'disabled'
            $result[3].state | Should -Be 'enabled'
            $result[4].state | Should -Be 'disabled'
        }

        It 'Should include project context in output' {
            # Act
            $result = Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $result[0].projectName | Should -Be 'TestProject'
            $result[0].projectId | Should -Be '12345678-1234-1234-1234-123456789012'
            $result[0].collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should map feature IDs to friendly names correctly' {
            # Act
            $result = Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $boardsFeature = $result | Where-Object { $_.featureId -eq 'ms.vss-work.agile' }
            $boardsFeature.feature | Should -Be 'Boards'

            $reposFeature = $result | Where-Object { $_.featureId -eq 'ms.vss-code.version-control' }
            $reposFeature.feature | Should -Be 'Repos'
        }

        It 'Should construct API URI correctly with project ID' {
            # Act
            Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/FeatureManagement/FeatureStatesQuery/host/project/12345678-1234-1234-1234-123456789012'
            }
        }

        It 'Should use POST method for API call' {
            # Act
            Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'POST'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockFeatureStates }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should accept project GUID directly without calling Get-AdoProject' {
            # Act
            Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName '12345678-1234-1234-1234-123456789012' -Confirm:$false

            # Assert
            Should -Not -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule
        }

        It 'Should resolve project name to ID via Get-AdoProject' {
            # Act
            Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should return early if project resolution fails' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $null }

            # Act
            $result = Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'NonExistentProject' -Confirm:$false

            # Assert
            $result | Should -BeNullOrEmpty
            Should -Not -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule
        }
    }

    Context 'Pipeline Support Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockFeatureStates }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should accept CollectionUri from pipeline' {
            # Arrange
            $input = [PSCustomObject]@{
                CollectionUri = 'https://dev.azure.com/my-org'
                ProjectName   = 'TestProject'
            }

            # Act
            $result = $input | Get-AdoFeatureState -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should propagate API errors' {
            # Arrange
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('API Error'),
                'ApiError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act & Assert
            { Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false } |
                Should -Throw
        }
    }

    Context 'ShouldProcess Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockFeatureStates }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should call Invoke-AdoRestMethod when confirmed' {
            # Act
            Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }
}
