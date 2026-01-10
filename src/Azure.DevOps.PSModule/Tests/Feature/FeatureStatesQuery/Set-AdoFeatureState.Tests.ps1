BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Set-AdoFeatureState' {
    BeforeAll {
        # Sample data for mocking
        $mockProject = @{
            id   = '12345678-1234-1234-1234-123456789012'
            name = 'TestProject'
        }

        $mockFeatureStateResult = @{
            featureId = 'ms.vss-work.agile'
            state     = 1
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockFeatureStateResult }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should set feature state to enabled' {
            # Act
            $result = Set-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Feature 'boards' -FeatureState 'enabled' -Confirm:$false

            # Assert
            $result.state | Should -Be 'enabled'
            $result.feature | Should -Be 'boards'
        }

        It 'Should set feature state to disabled by default' {
            # Act
            $result = Set-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Feature 'repos' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Body -like '*"state":0*'
            }
        }

        It 'Should include project context in output' {
            # Act
            $result = Set-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Feature 'boards' -Confirm:$false

            # Assert
            $result.projectName | Should -Be 'TestProject'
            $result.projectId | Should -Be '12345678-1234-1234-1234-123456789012'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should use PATCH method for API call' {
            # Act
            Set-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Feature 'boards' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'PATCH'
            }
        }

        It 'Should map Boards feature to correct feature ID' {
            # Act
            Set-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Feature 'boards' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*ms.vss-work.agile'
            }
        }

        It 'Should map Repos feature to correct feature ID' {
            # Act
            Set-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Feature 'repos' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*ms.vss-code.version-control'
            }
        }

        It 'Should map Pipelines feature to correct feature ID' {
            # Act
            Set-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Feature 'pipelines' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*ms.vss-build.pipelines'
            }
        }

        It 'Should construct API URI correctly with project ID and feature ID' {
            # Act
            Set-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Feature 'boards' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/FeatureManagement/FeatureStates/host/project/12345678-1234-1234-1234-123456789012/ms.vss-work.agile'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockFeatureStateResult }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should accept project GUID directly without calling Get-AdoProject' {
            # Act
            Set-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName '12345678-1234-1234-1234-123456789012' -Feature 'boards' -Confirm:$false

            # Assert
            Should -Not -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule
        }

        It 'Should resolve project name to ID via Get-AdoProject' {
            # Act
            Set-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Feature 'boards' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should return early if project resolution fails' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $null }

            # Act
            $result = Set-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'NonExistentProject' -Feature 'boards' -Confirm:$false

            # Assert
            $result | Should -BeNullOrEmpty
            Should -Not -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule
        }

        It 'Should handle case-insensitive feature names' {
            # Act - Test with uppercase
            Set-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Feature 'BOARDS' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*ms.vss-work.agile'
            }
        }
    }

    Context 'Pipeline Support Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockFeatureStateResult }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should accept parameters from pipeline' {
            # Arrange
            $input = [PSCustomObject]@{
                CollectionUri = 'https://dev.azure.com/my-org'
                ProjectName   = 'TestProject'
                Feature       = 'boards'
                FeatureState  = 'enabled'
            }

            # Act
            $result = $input | Set-AdoFeatureState -Confirm:$false

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
            { Set-AdoFeatureState -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Feature 'boards' -Confirm:$false } |
                Should -Throw
        }
    }
}
