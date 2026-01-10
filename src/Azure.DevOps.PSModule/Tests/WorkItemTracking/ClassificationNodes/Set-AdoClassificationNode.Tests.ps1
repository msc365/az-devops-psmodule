BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Set-AdoClassificationNode' {
    BeforeAll {
        # Sample environment values for mocking
        $mockCollectionUri = 'https://dev.azure.com/my-org'
        $mockProject = 'my-project'
        $mockPath = 'Team-A/SubArea-1'
        $mockIterationPath = 'Sprint-1'

        $mockUpdatedNode = @{
            id            = 123
            identifier    = 'abc123'
            name          = 'RenamedArea'
            structureType = 'area'
            path          = '\my-project\Area\Team-A\RenamedArea'
            hasChildren   = $false
        }

        $mockUpdatedIterationNode = @{
            id            = 456
            identifier    = 'def456'
            name          = 'Sprint-1'
            structureType = 'iteration'
            path          = '\my-project\Iteration\Sprint-1'
            hasChildren   = $false
            attributes    = @{
                startDate  = '2025-01-01T00:00:00Z'
                finishDate = '2025-01-14T23:59:59Z'
            }
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockUpdatedNode
            }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }

            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        AfterEach {
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should update node name' {
            # Act
            $result = Set-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Name 'RenamedArea' -Confirm:$false

            # Assert
            $result.name | Should -Be 'RenamedArea'
            $result.id | Should -Be 123
        }

        It 'Should update iteration node with StartDate' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockUpdatedIterationNode
            }

            # Act
            $result = Set-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Iterations' -Path $mockIterationPath -StartDate ([datetime]'2025-01-01') -Confirm:$false

            # Assert
            $result.attributes.startDate | Should -Be '2025-01-01T00:00:00Z'
        }

        It 'Should update iteration node with FinishDate' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockUpdatedIterationNode
            }

            # Act
            $result = Set-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Iterations' -Path $mockIterationPath -FinishDate ([datetime]'2025-01-14') -Confirm:$false

            # Assert
            $result.attributes.finishDate | Should -Be '2025-01-14T23:59:59Z'
        }

        It 'Should update iteration node with both StartDate and FinishDate' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockUpdatedIterationNode
            }

            # Act
            $result = Set-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Iterations' -Path $mockIterationPath -StartDate ([datetime]'2025-01-01') -FinishDate ([datetime]'2025-01-14') -Confirm:$false

            # Assert
            $result.attributes.startDate | Should -Be '2025-01-01T00:00:00Z'
            $result.attributes.finishDate | Should -Be '2025-01-14T23:59:59Z'
        }

        It 'Should include projectName and collectionUri in output' {
            # Act
            $result = Set-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Name 'RenamedArea' -Confirm:$false

            # Assert
            $result.projectName | Should -Be $mockProject
            $result.collectionUri | Should -Be $mockCollectionUri
        }
    }

    Context 'API URI Construction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockUpdatedNode
            }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct URI with path' {
            # Act
            Set-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Name 'RenamedArea' -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -eq "$mockCollectionUri/$mockProject/_apis/wit/classificationnodes/Areas/$mockPath"
            }
        }

        It 'Should use PATCH method' {
            # Act
            Set-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Name 'RenamedArea' -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Method -eq 'PATCH'
            }
        }

        It 'Should use correct API version' {
            # Act
            Set-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Name 'RenamedArea' -Version '7.1' -Confirm:$false

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
        }

        It 'Should throw when no properties are specified' {
            # Act & Assert
            { Set-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Confirm:$false } | Should -Throw -ExpectedMessage '*At least one property*'
        }

        It 'Should throw when StartDate used with Areas' {
            # Act & Assert
            { Set-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -StartDate ([datetime]'2025-01-01') -Confirm:$false } | Should -Throw -ExpectedMessage '*StartDate can only be set for Iteration nodes*'
        }

        It 'Should throw when FinishDate used with Areas' {
            # Act & Assert
            { Set-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -FinishDate ([datetime]'2025-01-14') -Confirm:$false } | Should -Throw -ExpectedMessage '*FinishDate can only be set for Iteration nodes*'
        }

        It 'Should handle DuplicateNameException gracefully with warning' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [Exception]::new('Duplicate name'),
                    'DuplicateName',
                    [System.Management.Automation.ErrorCategory]::ResourceExists,
                    $null
                )
                $errorRecord.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message": "DuplicateNameException: A classification node with this name already exists"}')
                throw $errorRecord
            }

            # Act & Assert - Should not throw, only produce warning
            { Set-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Name 'DuplicateName' -Confirm:$false -WarningAction SilentlyContinue } | Should -Not -Throw

            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod
        }

        It 'Should handle NotFoundException gracefully with warning' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [Exception]::new('Not found'),
                    'NotFoundException',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $null
                )
                $errorRecord.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message": "NotFoundException: Classification node not found"}')
                throw $errorRecord
            }

            # Act & Assert - Should not throw, only produce warning
            { Set-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path 'NonExistent' -Name 'NewName' -Confirm:$false -WarningAction SilentlyContinue } | Should -Not -Throw

            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod
        }

        It 'Should throw on other API errors' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                throw 'Unexpected API error'
            }

            # Act & Assert
            { Set-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Name 'NewName' -Confirm:$false } | Should -Throw
        }
    }

    Context 'Parameter Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should accept valid CollectionUri' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockUpdatedNode
            }

            # Act & Assert
            { Set-AdoClassificationNode -CollectionUri 'https://dev.azure.com/test-org' -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Name 'NewName' -Confirm:$false } | Should -Not -Throw
        }

        It 'Should use environment defaults when not specified' {
            # Arrange
            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockUpdatedNode
            }

            # Act
            $result = Set-AdoClassificationNode -StructureGroup 'Areas' -Path $mockPath -Name 'NewName' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }
    }
}
