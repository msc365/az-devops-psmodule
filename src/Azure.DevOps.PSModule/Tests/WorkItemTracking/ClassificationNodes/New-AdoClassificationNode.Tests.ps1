BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'New-AdoClassificationNode' {
    BeforeAll {
        # Sample environment values for mocking
        $mockCollectionUri = 'https://dev.azure.com/my-org'
        $mockProject = 'my-project'
        $mockNodeName = 'NewArea'
        $mockPath = 'Team-A'

        $mockCreatedNode = @{
            id            = 999
            identifier    = 'xyz999'
            name          = 'NewArea'
            structureType = 'area'
            path          = '\my-project\Area\NewArea'
            hasChildren   = $false
            attributes    = @{}
        }

        $mockCreatedChildNode = @{
            id            = 888
            identifier    = 'abc888'
            name          = 'SubArea'
            structureType = 'area'
            path          = '\my-project\Area\Team-A\SubArea'
            hasChildren   = $false
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockCreatedNode
            }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }

            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        AfterEach {
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should create new area node at root level' {
            # Act
            $result = New-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Name $mockNodeName -Confirm:$false

            # Assert
            $result.name | Should -Be 'NewArea'
            $result.id | Should -Be 999
            $result.structureType | Should -Be 'area'
        }

        It 'Should create new iteration node at root level' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return @{
                    id            = 777
                    identifier    = 'iter777'
                    name          = 'Sprint-1'
                    structureType = 'iteration'
                    path          = '\my-project\Iteration\Sprint-1'
                    hasChildren   = $false
                }
            }

            # Act
            $result = New-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Iterations' -Name 'Sprint-1' -Confirm:$false

            # Assert
            $result.name | Should -Be 'Sprint-1'
            $result.structureType | Should -Be 'iteration'
        }

        It 'Should create child node under existing parent path' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockCreatedChildNode
            }

            # Act
            $result = New-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Name 'SubArea' -Confirm:$false

            # Assert
            $result.name | Should -Be 'SubArea'
            $result.path | Should -Be '\my-project\Area\Team-A\SubArea'
        }

        It 'Should include projectName and collectionUri in output' {
            # Act
            $result = New-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Name $mockNodeName -Confirm:$false

            # Assert
            $result.projectName | Should -Be $mockProject
            $result.collectionUri | Should -Be $mockCollectionUri
        }

        It 'Should return node with all standard properties' {
            # Act
            $result = New-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Name $mockNodeName -Confirm:$false

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'id'
            $result.PSObject.Properties.Name | Should -Contain 'identifier'
            $result.PSObject.Properties.Name | Should -Contain 'name'
            $result.PSObject.Properties.Name | Should -Contain 'structureType'
            $result.PSObject.Properties.Name | Should -Contain 'path'
            $result.PSObject.Properties.Name | Should -Contain 'hasChildren'
        }
    }

    Context 'API URI Construction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockCreatedNode
            }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct URI for root level creation' {
            # Act
            New-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Name $mockNodeName -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -eq "$mockCollectionUri/$mockProject/_apis/wit/classificationnodes/Areas"
            }
        }

        It 'Should construct correct URI with parent path' {
            # Act
            New-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Path $mockPath -Name 'SubArea' -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -eq "$mockCollectionUri/$mockProject/_apis/wit/classificationnodes/Areas/$mockPath"
            }
        }

        It 'Should use POST method' {
            # Act
            New-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Name $mockNodeName -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Method -eq 'POST'
            }
        }

        It 'Should use correct API version' {
            # Act
            New-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Name $mockNodeName -Version '7.1' -Confirm:$false

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
            { New-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Name $mockNodeName -Confirm:$false -WarningAction SilentlyContinue } | Should -Not -Throw

            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod
        }

        It 'Should throw on other API errors' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                throw 'Unexpected API error'
            }

            # Act & Assert
            { New-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Name $mockNodeName -Confirm:$false } | Should -Throw
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
                return $mockCreatedNode
            }

            # Act & Assert
            { New-AdoClassificationNode -CollectionUri 'https://dev.azure.com/test-org' -ProjectName $mockProject -StructureGroup 'Areas' -Name $mockNodeName -Confirm:$false } | Should -Not -Throw
        }

        It 'Should use environment defaults when not specified' {
            # Arrange
            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockCreatedNode
            }

            # Act
            $result = New-AdoClassificationNode -StructureGroup 'Areas' -Name $mockNodeName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should accept pipeline input for Name parameter' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockCreatedNode
            }

            # Act & Assert
            { 'TestArea' | ForEach-Object { New-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Name $_ -Confirm:$false } } | Should -Not -Throw
        }
    }

    Context 'ShouldProcess Support Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockCreatedNode
            }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should support WhatIf parameter' {
            # Act
            New-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Name $mockNodeName -WhatIf

            # Assert
            Should -Not -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod
        }

        It 'Should call API when Confirm is false' {
            # Act
            New-AdoClassificationNode -CollectionUri $mockCollectionUri -ProjectName $mockProject -StructureGroup 'Areas' -Name $mockNodeName -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -Times 1
        }
    }
}
