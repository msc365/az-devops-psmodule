BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Remove-AdoClassificationNode' {
    BeforeAll {
        # Sample environment values for mocking
        $mockCollectionUri = 'https://dev.azure.com/my-org'
        $mockProject = 'my-project'
        $mockPath = 'Team-A/SubArea-1'
        $mockIterationPath = 'Sprint-1'
        $mockReclassifyId = 658
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $null
            }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }

            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        AfterEach {
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should remove area node at specified path' {
            # Act
            { Remove-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Confirm:$false } | Should -Not -Throw

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -Times 1
        }

        It 'Should remove iteration node at specified path' {
            # Act
            { Remove-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Iterations' -Path $mockIterationPath -Confirm:$false } | Should -Not -Throw

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -Times 1
        }

        It 'Should remove node with ReclassifyId parameter' {
            # Act
            { Remove-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -ReclassifyId $mockReclassifyId -Confirm:$false } | Should -Not -Throw

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -Times 1
        }

        It 'Should not return output' {
            # Act
            $result = Remove-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Confirm:$false

            # Assert
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'API URI Construction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $null
            }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct URI with path' {
            # Act
            Remove-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -eq "$mockCollectionUri/$mockProject/_apis/wit/classificationnodes/Areas/$mockPath"
            }
        }

        It 'Should include ReclassifyId in query parameters when specified' {
            # Act
            Remove-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -ReclassifyId $mockReclassifyId -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $QueryParameters -like '*$reclassifyId=658*'
            }
        }

        It 'Should use DELETE method' {
            # Act
            Remove-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Method -eq 'DELETE'
            }
        }

        It 'Should use correct API version' {
            # Act
            Remove-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Version '7.1' -Confirm:$false

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
            { Remove-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path 'NonExistent' -Confirm:$false -WarningAction SilentlyContinue } | Should -Not -Throw

            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod
        }

        It 'Should throw on other API errors' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                throw 'Unexpected API error'
            }

            # Act & Assert
            { Remove-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Confirm:$false } | Should -Throw
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
                return $null
            }

            # Act & Assert
            { Remove-AdoClassificationNode -CollectionUri 'https://dev.azure.com/test-org' -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Confirm:$false } | Should -Not -Throw
        }

        It 'Should use environment defaults when not specified' {
            # Arrange
            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $null
            }

            # Act & Assert
            { Remove-AdoClassificationNode -StructureGroup 'Areas' -Path $mockPath -Confirm:$false } | Should -Not -Throw

            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should accept pipeline input for Path parameter' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $null
            }

            # Act & Assert
            { 'Path1', 'Path2' | ForEach-Object { Remove-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $_ -Confirm:$false } } | Should -Not -Throw
        }
    }

    Context 'ShouldProcess Support Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $null
            }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should support WhatIf parameter' {
            # Act
            Remove-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -WhatIf

            # Assert
            Should -Not -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod
        }

        It 'Should call API when Confirm is false' {
            # Act
            Remove-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -Times 1
        }
    }

    Context 'ReclassifyId Parameter Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $null
            }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should handle work item reclassification' {
            # Act
            Remove-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -ReclassifyId $mockReclassifyId -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $QueryParameters -match 'reclassifyId=658'
            }
        }

        It 'Should not include ReclassifyId when not specified' {
            # Act
            Remove-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $null -eq $QueryParameters -or $QueryParameters -notmatch 'reclassifyId'
            }
        }
    }
}
