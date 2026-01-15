BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoClassificationNode' {
    BeforeAll {
        # Sample environment values for mocking
        $mockCollectionUri = 'https://dev.azure.com/my-org'
        $mockProject = 'my-project'
        $mockAreaPath = 'Team-A/SubArea-1'
        $mockIterationPath = 'Sprint-1'

        $mockAreaNode = @{
            id            = 123
            identifier    = 'abc123'
            name          = 'SubArea-1'
            structureType = 'area'
            path          = '\my-project\Area\Team-A\SubArea-1'
            hasChildren   = $false
            attributes    = @{}
        }

        $mockIterationNode = @{
            id            = 456
            identifier    = 'def456'
            name          = 'Sprint-1'
            structureType = 'iteration'
            path          = '\my-project\Iteration\Sprint-1'
            hasChildren   = $true
            attributes    = @{
                startDate  = '2025-01-01T00:00:00Z'
                finishDate = '2025-01-14T23:59:59Z'
            }
            children      = @(
                @{
                    id   = 789
                    name = 'Sprint-1-Week-1'
                }
            )
        }

        $mockRootNodes = @{
            value = @(
                @{
                    id            = 1
                    identifier    = 'root-area'
                    name          = 'Area'
                    structureType = 'area'
                    path          = '\my-project\Area'
                    hasChildren   = $true
                }
                @{
                    id            = 2
                    identifier    = 'root-iteration'
                    name          = 'Iteration'
                    structureType = 'iteration'
                    path          = '\my-project\Iteration'
                    hasChildren   = $true
                }
            )
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockAreaNode
            }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }

            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        AfterEach {
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should retrieve root classification node for Areas' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return @{
                    id            = 1
                    identifier    = 'root-area'
                    name          = 'Area'
                    structureType = 'area'
                    path          = '\my-project\Area'
                    hasChildren   = $true
                }
            }

            # Act
            $result = Get-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas'

            # Assert
            $result.name | Should -Be 'Area'
            $result.structureType | Should -Be 'area'
            $result.hasChildren | Should -Be $true
        }

        It 'Should retrieve specific classification node by path' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockAreaNode
            }

            # Act
            $result = Get-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockAreaPath

            # Assert
            $result.id | Should -Be 123
            $result.name | Should -Be 'SubArea-1'
            $result.path | Should -Be '\my-project\Area\Team-A\SubArea-1'
        }

        It 'Should retrieve iteration node with attributes' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockIterationNode
            }

            # Act
            $result = Get-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Iterations' -Path $mockIterationPath

            # Assert
            $result.name | Should -Be 'Sprint-1'
            $result.attributes.startDate | Should -Be '2025-01-01T00:00:00Z'
            $result.attributes.finishDate | Should -Be '2025-01-14T23:59:59Z'
        }

        It 'Should retrieve nodes with children when present' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockIterationNode
            }

            # Act
            $result = Get-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Iterations' -Path $mockIterationPath

            # Assert
            $result.hasChildren | Should -Be $true
            $result.children.Count | Should -Be 1
            $result.children[0].name | Should -Be 'Sprint-1-Week-1'
        }

        It 'Should retrieve multiple nodes by IDs' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return @{
                    value = @($mockAreaNode, $mockIterationNode)
                }
            }

            # Act
            $result = Get-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -Ids @('123', '456')

            # Assert
            $result.Count | Should -Be 2
        }

        It 'Should include projectName and collectionUri in output' {
            # Act
            $result = Get-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockAreaPath

            # Assert
            $result.projectName | Should -Be $mockProject
            $result.collectionUri | Should -Be $mockCollectionUri
        }
    }

    Context 'API URI Construction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockAreaNode
            }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct URI for root node retrieval' {
            # Act
            Get-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas'

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -eq "$mockCollectionUri/$mockProject/_apis/wit/classificationnodes/Areas"
            }
        }

        It 'Should construct correct URI with path' {
            # Act
            Get-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockAreaPath

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -eq "$mockCollectionUri/$mockProject/_apis/wit/classificationnodes/Areas/$mockAreaPath"
            }
        }

        It 'Should include Depth in query parameters when specified' {
            # Act
            Get-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Depth 2

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $QueryParameters -like '*$depth=2*'
            }
        }

        It 'Should include IDs in query parameters when specified' {
            # Act
            Get-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -Ids @('1', '2', '3')

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $QueryParameters -like '*ids=1,2,3*'
            }
        }

        It 'Should include ErrorPolicy in query parameters when specified with IDs' {
            # Act
            Get-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -Ids @('1', '2') -ErrorPolicy 'omit'

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $QueryParameters -like '*errorPolicy=omit*'
            }
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
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
            { Get-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path 'NonExistent' -WarningAction SilentlyContinue } | Should -Not -Throw

            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod
        }

        It 'Should throw on other API errors' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                throw 'Unexpected API error'
            }

            # Act & Assert
            { Get-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' } | Should -Throw
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
                return $mockAreaNode
            }

            # Act & Assert
            { Get-AdoClassificationNode -CollectionUri 'https://dev.azure.com/test-org' -ProjectName $mockProject -StructureGroup 'Areas' } | Should -Not -Throw
        }

        It 'Should use environment defaults when not specified' {
            # Arrange
            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockAreaNode
            }

            # Act
            $result = Get-AdoClassificationNode -StructureGroup 'Areas'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }
    }
}
