BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoPolicyType' {
    BeforeAll {
        # Sample environment values for mocking
        $mockCollectionUri = 'https://dev.azure.com/my-org'
        $mockProject = 'my-project'
        $mockPolicyTypeId = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'

        $mockPolicyType = @{
            id          = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
            displayName = 'Minimum number of reviewers'
            description = 'This policy will ensure that a minimum number of reviewers have approved a pull request before it can be completed.'
        }

        $mockPolicyTypes = @(
            @{
                id          = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
                displayName = 'Minimum number of reviewers'
                description = 'This policy will ensure that a minimum number of reviewers have approved a pull request before it can be completed.'
            },
            @{
                id          = '0609b952-1397-4640-95ec-e00a01b2c241'
                displayName = 'Build'
                description = 'This policy will require a successful build to complete before updating protected refs.'
            },
            @{
                id          = 'fd2167ab-b0be-447a-8ec8-39368250530e'
                displayName = 'Required reviewers'
                description = 'This policy will require that specific users review and approve changes.'
            }
        )
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockPolicyType
            }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }

            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        AfterEach {
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should retrieve specific policy type by ID' {
            # Act
            $result = Get-AdoPolicyType -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockPolicyTypeId

            # Assert
            $result.id | Should -Be $mockPolicyTypeId
            $result.displayName | Should -Be 'Minimum number of reviewers'
            $result.description | Should -Not -BeNullOrEmpty
        }

        It 'Should retrieve all policy types when no ID specified' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return @{
                    value = $mockPolicyTypes
                }
            }

            # Act
            $result = Get-AdoPolicyType -CollectionUri $mockCollectionUri -ProjectName $mockProject

            # Assert
            $result.Count | Should -Be 3
            $result[0].id | Should -Not -BeNullOrEmpty
            $result[1].displayName | Should -Be 'Build'
        }

        It 'Should include projectName and collectionUri in output' {
            # Act
            $result = Get-AdoPolicyType -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockPolicyTypeId

            # Assert
            $result.projectName | Should -Be $mockProject
            $result.collectionUri | Should -Be $mockCollectionUri
        }

        It 'Should support pipeline input for policy type IDs' {
            # Arrange
            $typeId1 = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
            $typeId2 = '0609b952-1397-4640-95ec-e00a01b2c241'

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockPolicyTypes[0]
            } -ParameterFilter { $Uri -like "*$typeId1" }

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockPolicyTypes[1]
            } -ParameterFilter { $Uri -like "*$typeId2" }

            # Act
            $result = $typeId1, $typeId2 | Get-AdoPolicyType -CollectionUri $mockCollectionUri -ProjectName $mockProject

            # Assert
            $result.Count | Should -Be 2
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
            { Get-AdoPolicyType -CollectionUri 'invalid-uri' -ProjectName $mockProject } | Should -Throw
        }

        It 'Should use default CollectionUri from environment when not specified' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockPolicyType
            }

            # Act
            $result = Get-AdoPolicyType -ProjectName $mockProject -Id $mockPolicyTypeId

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -like "*$mockCollectionUri*"
            }
        }

        It 'Should use default ProjectName from environment when not specified' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockPolicyType
            }

            # Act
            $result = Get-AdoPolicyType -CollectionUri $mockCollectionUri -Id $mockPolicyTypeId

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
                return $mockPolicyType
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
            Get-AdoPolicyType -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockPolicyTypeId

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -eq "$mockCollectionUri/$mockProject/_apis/policy/types/$mockPolicyTypeId"
            }
        }

        It 'Should construct correct URI for listing policy types' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return @{ value = $mockPolicyTypes }
            }

            # Act
            Get-AdoPolicyType -CollectionUri $mockCollectionUri -ProjectName $mockProject

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -eq "$mockCollectionUri/$mockProject/_apis/policy/types"
            }
        }

        It 'Should use GET HTTP method' {
            # Act
            Get-AdoPolicyType -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockPolicyTypeId

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Method -eq 'GET'
            }
        }

        It 'Should use correct API version' {
            # Act
            Get-AdoPolicyType -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockPolicyTypeId -Version '7.1'

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

        It 'Should handle non-existent policy type gracefully' {
            # Arrange
            # Use a valid policy type ID that returns NotFoundException from API
            $validId = '40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e'
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Policy type not found'),
                'NotFoundException',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $validId
            )
            $errorRecord.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message": "NotFoundException: Policy type does not exist"}')

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                throw $errorRecord
            }

            # Act
            $result = Get-AdoPolicyType -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $validId -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should propagate non-NotFoundException errors' {
            # Arrange
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Unauthorized'),
                'UnauthorizedError',
                [System.Management.Automation.ErrorCategory]::PermissionDenied,
                $null
            )
            $errorRecord.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message": "Unauthorized access"}')

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                throw $errorRecord
            }

            # Act & Assert
            { Get-AdoPolicyType -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockPolicyTypeId -ErrorAction Stop } | Should -Throw
        }
    }
}
