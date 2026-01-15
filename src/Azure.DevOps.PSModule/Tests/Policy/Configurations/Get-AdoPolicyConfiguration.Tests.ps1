BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoPolicyConfiguration' {
    BeforeAll {
        # Sample environment values for mocking
        $mockCollectionUri = 'https://dev.azure.com/my-org'
        $mockProject = 'my-project'
        $mockConfigId = 42
        $mockPolicyTypeId = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'

        $mockPolicyConfig = @{
            id          = 42
            type        = @{
                id          = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
                displayName = 'Minimum Approver Count'
            }
            revision    = 1
            isEnabled   = $true
            isBlocking  = $true
            isDeleted   = $false
            settings    = @{
                minimumApproverCount = 2
                scope                = @(
                    @{
                        repositoryId = $null
                        refName      = $null
                        matchKind    = 'DefaultBranch'
                    }
                )
            }
            createdBy   = @{
                displayName = 'Test User'
                id          = '12345'
            }
            createdDate = '2025-01-01T00:00:00Z'
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockPolicyConfig
            }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }

            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        AfterEach {
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should retrieve specific policy configuration by ID' {
            # Act
            $result = Get-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId

            # Assert
            $result.id | Should -Be $mockConfigId
            $result.isEnabled | Should -Be $true
            $result.isBlocking | Should -Be $true
        }

        It 'Should retrieve all policy configurations when no filters specified' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return @{
                    value = @($mockPolicyConfig, $mockPolicyConfig)
                    count = 2
                }
            }

            # Act
            $result = Get-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject

            # Assert
            $result.Count | Should -Be 2
        }

        It 'Should filter configurations by PolicyType' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return @{
                    value = @($mockPolicyConfig)
                    count = 1
                }
            }

            # Act
            $result = Get-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -PolicyType $mockPolicyTypeId

            # Assert
            $result.Count | Should -Be 1
            $result.type.id | Should -Be $mockPolicyTypeId
        }

        It 'Should support pipeline input for configuration IDs' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockPolicyConfig
            }

            # Act
            $result = 42, 43 | Get-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject

            # Assert
            $result.Count | Should -Be 2
        }

        It 'Should include projectName and collectionUri in output' {
            # Act
            $result = Get-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId

            # Assert
            $result.projectName | Should -Be $mockProject
            $result.collectionUri | Should -Be $mockCollectionUri
        }

        It 'Should support pagination with Top parameter' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return @{
                    value = @($mockPolicyConfig)
                    count = 1
                }
            }

            # Act
            $result = Get-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Top 10

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $QueryParameters -like '*$top=10*'
            }
        }

        It 'Should support continuation token for pagination' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return @{
                    value = @($mockPolicyConfig)
                    count = 1
                }
            }
            $token = 'abc123'

            # Act
            $result = Get-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -ContinuationToken $token

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $QueryParameters -like "*continuationToken=$token*"
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }

            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        AfterEach {
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should reject invalid CollectionUri format' {
            # Act & Assert
            { Get-AdoPolicyConfiguration -CollectionUri 'invalid-uri' -ProjectName $mockProject } | Should -Throw
        }

        It 'Should use default CollectionUri from environment when not specified' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockPolicyConfig
            }

            # Act
            $result = Get-AdoPolicyConfiguration -ProjectName $mockProject -Id $mockConfigId

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -like "*$mockCollectionUri*"
            }
        }

        It 'Should use default ProjectName from environment when not specified' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockPolicyConfig
            }

            # Act
            $result = Get-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -Id $mockConfigId

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -like "*/$mockProject/*"
            }
        }
    }

    Context 'API Interaction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockPolicyConfig
            }

            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        AfterEach {
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should construct correct URI for retrieving by ID' {
            # Act
            Get-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -eq "$mockCollectionUri/$mockProject/_apis/policy/configurations/$mockConfigId"
            }
        }

        It 'Should construct correct URI for listing configurations' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return @{ value = @($mockPolicyConfig) }
            }

            # Act
            Get-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -eq "$mockCollectionUri/$mockProject/_apis/policy/configurations"
            }
        }

        It 'Should use GET HTTP method' {
            # Act
            Get-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Method -eq 'GET'
            }
        }

        It 'Should use correct API version' {
            # Act
            Get-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId -Version '7.1'

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Version -eq '7.1'
            }
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }

            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        AfterEach {
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should propagate API exceptions' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                throw 'Simulated API error'
            }

            # Act & Assert
            { Get-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId -ErrorAction Stop } | Should -Throw
        }
    }
}
