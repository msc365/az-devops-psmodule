BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoCheckConfiguration' {
    BeforeAll {
        # Sample check configuration data for mocking
        $mockCheckConfigurations = @{
            value = @(
                @{
                    id       = 1
                    timeout  = 1440
                    type     = @{
                        id   = 'type-id-1'
                        name = 'Approval'
                    }
                    settings = @{
                        approvers            = @(@{ id = 'user1' })
                        definitionRef        = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
                        minRequiredApprovers = 1
                    }
                    resource = @{
                        type = 'environment'
                        id   = '1'
                        name = 'TestEnvironment'
                    }
                }
                @{
                    id       = 2
                    timeout  = 2880
                    type     = @{
                        id   = 'type-id-2'
                        name = 'BranchControl'
                    }
                    settings = @{
                        allowedBranches  = @('refs/heads/main')
                        definitionRef    = @{ id = '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b' }
                    }
                    resource = @{
                        type = 'environment'
                        id   = '1'
                        name = 'TestEnvironment'
                    }
                }
            )
        }

        $mockEnvironment = @{
            id = 1
            name = 'TestEnvironment'
        }

        $mockDefinitionRefApproval = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d'; name = 'approval' }
        $mockDefinitionRefBranchControl = @{ id = '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'; name = 'branchControl' }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCheckConfigurations }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoEnvironment { return $mockEnvironment }
        }

        It 'Should retrieve all check configurations for a resource' {
            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'TestEnvironment'

            # Assert
            $result | Should -HaveCount 2
            $result[0].id | Should -Be 1
            $result[1].id | Should -Be 2
        }

        It 'Should retrieve a specific check configuration by Id' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCheckConfigurations.value[0] }

            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
        }

        It 'Should accept resource names via pipeline' {
            # Act
            $result = 'TestEnvironment' | Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment'

            # Assert
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should filter by DefinitionType parameter' {
            # Act
            Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'TestEnvironment' -DefinitionType 'approval'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should support Expands parameter' {
            # Act
            Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'TestEnvironment' -Expands 'settings'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*$expand=settings*'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCheckConfigurations }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoEnvironment { return $mockEnvironment }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Get-AdoCheckConfiguration -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'TestEnv' } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            $result = Get-AdoCheckConfiguration -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'TestEnvironment'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*dev.azure.com/default-org*'
            }

            # Cleanup
            Remove-Item env:DefaultAdoCollectionUri -ErrorAction SilentlyContinue
        }
    }

    Context 'API Interaction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCheckConfigurations }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoEnvironment { return $mockEnvironment }
        }

        It 'Should construct correct REST API URI for listing configurations' {
            # Act
            Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'TestEnvironment'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/pipelines/checks/configurations' -and
                $Version -eq '7.2-preview.1' -and
                $Method -eq 'GET'
            }
        }

        It 'Should construct correct REST API URI for specific configuration by Id' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCheckConfigurations.value[0] }

            # Act
            Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Id 1

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/pipelines/checks/configurations/1' -and
                $Method -eq 'GET'
            }
        }

        It 'Should call Get-AdoEnvironment to resolve resource ID' {
            # Act
            Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'TestEnvironment'

            # Assert
            Should -Invoke Get-AdoEnvironment -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoEnvironment { return $mockEnvironment }
        }

        It 'Should handle empty configuration list from API' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return @{ value = @() } }

            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'TestEnvironment'

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should propagate errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'TestEnvironment' } | Should -Throw '*API Error: Unauthorized*'
        }
    }

    Context 'ParameterSet Tests - ResourceId' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCheckConfigurations }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Resolve-AdoDefinitionRef {
                param($Name)
                switch ($Name) {
                    'approval' { return $mockDefinitionRefApproval }
                    'branchControl' { return $mockDefinitionRefBranchControl }
                    default { return @{ id = 'unknown-id'; name = $Name } }
                }
            }
        }

        It 'Should retrieve all check configurations using ResourceId without DefinitionType' {
            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceId '12345'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should retrieve filtered check configurations using ResourceId with DefinitionType' {
            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceId '12345' -DefinitionType 'approval'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 1
            $result.id | Should -Be 1
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should NOT call Get-AdoEnvironment when ResourceId is provided' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoEnvironment { return $mockEnvironment }

            # Act
            Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceId '12345'

            # Assert
            Should -Invoke Get-AdoEnvironment -ModuleName Azure.DevOps.PSModule -Times 0
        }

        It 'Should accept ResourceId via pipeline without DefinitionType' {
            # Act
            $result = [PSCustomObject]@{ ResourceId = '12345' } | Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 2
        }

        It 'Should accept ResourceId via pipeline with DefinitionType' {
            # Act
            $result = [PSCustomObject]@{ ResourceId = '12345'; DefinitionType = 'approval' } | Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 1
        }

        It 'Should work with ResourceId and multiple DefinitionTypes' {
            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceId '12345' -DefinitionType 'approval','branchControl'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should work with ResourceId and Expands parameter without DefinitionType' {
            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceId '12345' -Expands 'settings'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*$expand=settings*'
            }
        }

        It 'Should work with ResourceId, DefinitionType and Expands parameter' {
            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceId '12345' -DefinitionType 'approval' -Expands 'settings'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 1
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*$expand=settings*'
            }
        }

        It 'Should construct correct URI with ResourceId in query parameters' {
            # Act
            Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceId '12345'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*resourceId=12345*'
            }
        }

        It 'Should throw error when both ResourceName and ResourceId are provided' {
            # Act & Assert
            { Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'TestEnvironment' -ResourceId '12345' } | Should -Throw
        }
    }
}
