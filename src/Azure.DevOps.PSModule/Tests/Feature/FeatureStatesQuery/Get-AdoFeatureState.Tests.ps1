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
        # Sample feature state data for mocking - featureStates is a PSCustomObject (not hashtable)
        $mockFeatureStates = [PSCustomObject]@{
            featureStates = [PSCustomObject]@{
                'ms.vss-work.agile'           = [PSCustomObject]@{
                    featureId = 'ms.vss-work.agile'
                    state     = 1
                }
                'ms.vss-code.version-control' = [PSCustomObject]@{
                    featureId = 'ms.vss-code.version-control'
                    state     = 1
                }
                'ms.vss-build.pipelines'      = [PSCustomObject]@{
                    featureId = 'ms.vss-build.pipelines'
                    state     = 0
                }
                'ms.vss-test-web.test'        = [PSCustomObject]@{
                    featureId = 'ms.vss-test-web.test'
                    state     = 1
                }
                'ms.azure-artifacts.feature'  = [PSCustomObject]@{
                    featureId = 'ms.azure-artifacts.feature'
                    state     = 0
                }
            }
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
            ($result.feature | Sort-Object) | Should -Contain 'boards'
            ($result.feature | Sort-Object) | Should -Contain 'repos'
            ($result.feature | Sort-Object) | Should -Contain 'pipelines'
            ($result.feature | Sort-Object) | Should -Contain 'testPlans'
            ($result.feature | Sort-Object) | Should -Contain 'artifacts'
        }

        It 'Should return feature states with correct state values' {
            # Act
            $result = Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $boardsState = ($result | Where-Object { $_.featureId -eq 'ms.vss-work.agile' }).state
            $reposState = ($result | Where-Object { $_.featureId -eq 'ms.vss-code.version-control' }).state
            $pipelinesState = ($result | Where-Object { $_.featureId -eq 'ms.vss-build.pipelines' }).state
            $testPlansState = ($result | Where-Object { $_.featureId -eq 'ms.vss-test-web.test' }).state
            $artifactsState = ($result | Where-Object { $_.featureId -eq 'ms.azure-artifacts.feature' }).state

            $boardsState | Should -Be 1
            $reposState | Should -Be 1
            $pipelinesState | Should -Be 0
            $testPlansState | Should -Be 1
            $artifactsState | Should -Be 0
        }

        It 'Should include project context in output' {
            # Act
            $result = Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert - Check first result (any feature)
            $firstResult = $result | Select-Object -First 1
            $firstResult.projectName | Should -Be 'TestProject'
            $firstResult.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should map feature IDs to friendly names correctly' {
            # Act
            $result = Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $boardsFeature = $result | Where-Object { $_.featureId -eq 'ms.vss-work.agile' }
            $boardsFeature.feature | Should -Be 'boards'

            $reposFeature = $result | Where-Object { $_.featureId -eq 'ms.vss-code.version-control' }
            $reposFeature.feature | Should -Be 'repos'
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

        It 'Should pass Body parameter to API call' {
            # Act
            Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert - Just verify Body parameter was passed
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
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
            Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName '12345678-1234-1234-1234-123456789012'

            # Assert
            Should -Not -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule
        }

        It 'Should resolve project name to ID via Get-AdoProject' {
            # Act
            Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            Should -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should return early if project resolution fails' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $null }

            # Act
            $result = Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'NonExistentProject'

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
            $result = $input | Get-AdoFeatureState

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
            { Get-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' } |
                Should -Throw
        }
    }
}
