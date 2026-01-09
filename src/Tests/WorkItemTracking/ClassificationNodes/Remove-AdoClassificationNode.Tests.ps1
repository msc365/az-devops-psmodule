[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '', Scope = 'Function', Target = '*', Justification = 'Variables are used in nested It blocks')]
param()

BeforeAll {
    # Import the module for testing
    $moduleName = 'Azure.DevOps.PSModule'
    $modulePath = Join-Path -Path (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName -ChildPath $moduleName

    # Only remove and re-import if module is not loaded or loaded from different path
    $loadedModule = Get-Module -Name $moduleName -ErrorAction SilentlyContinue
    if ($loadedModule -and $loadedModule.Path -ne (Join-Path $modulePath "$moduleName.psm1")) {
        Remove-Module -Name $moduleName -Force
        $loadedModule = $null
    }

    # Import the module if not already loaded
    if (-not $loadedModule) {
        Import-Module $modulePath -Force -ErrorAction Stop
    }
}

Describe 'Remove-AdoClassificationNode' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $nodePath = 'my-area-1'
        $reclassifyId = 456

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When removing a classification node' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should remove <StructureGroup> node by path' -ForEach @(
            @{ StructureGroup = 'Areas' }
            @{ StructureGroup = 'Iterations' }
        ) {
            # Act
            Remove-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup $StructureGroup -Path $nodePath -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/wit/classificationnodes/$StructureGroup/$nodePath" -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should remove area node at specified path' {
            # Act
            Remove-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodePath -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/wit/classificationnodes/Areas/$nodePath"
            }
        }

        It 'Should remove nested classification node' {
            # Act
            $nestedPath = 'my-team-1/my-subarea-1'
            Remove-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nestedPath -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match 'my-team-1' -and $Uri -match 'my-subarea-1'
            }
        }
    }

    Context 'When removing node with reclassification' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should remove node with ReclassifyId parameter' {
            # Act
            Remove-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodePath -ReclassifyId $reclassifyId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match "\`$reclassifyId=$reclassifyId" -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should reclassify work items to node <ReclassifyId>' -ForEach @(
            @{ ReclassifyId = 100 }
            @{ ReclassifyId = 200 }
            @{ ReclassifyId = 658 }
        ) {
            # Act
            Remove-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodePath -ReclassifyId $ReclassifyId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match "\`$reclassifyId=$ReclassifyId"
            }
        }
    }

    Context 'When removing multiple classification nodes' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should remove multiple nodes from pipeline' {
            # Act
            $inputObjects = @(
                [PSCustomObject]@{ CollectionUri = $collectionUri; ProjectName = $projectName; StructureGroup = 'Areas'; Path = 'area-1' }
                [PSCustomObject]@{ CollectionUri = $collectionUri; ProjectName = $projectName; StructureGroup = 'Areas'; Path = 'area-2' }
                [PSCustomObject]@{ CollectionUri = $collectionUri; ProjectName = $projectName; StructureGroup = 'Areas'; Path = 'area-3' }
            )
            $inputObjects | Remove-AdoClassificationNode -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should accept parameters from pipeline by property name' {
            # Act
            $inputObject = [PSCustomObject]@{
                CollectionUri  = $collectionUri
                ProjectName    = $projectName
                StructureGroup = 'Areas'
                Path           = $nodePath
            }
            $inputObject | Remove-AdoClassificationNode -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should accept multiple items from pipeline' {
            # Act
            $inputObjects = @(
                [PSCustomObject]@{ CollectionUri = $collectionUri; ProjectName = $projectName; StructureGroup = 'Areas'; Path = 'area-1' }
                [PSCustomObject]@{ CollectionUri = $collectionUri; ProjectName = $projectName; StructureGroup = 'Areas'; Path = 'area-2' }
            )
            $inputObjects | Remove-AdoClassificationNode -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }

    Context 'When using API version parameter' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should use API version 7.2-preview.2' {
            # Act
            Remove-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodePath -Version '7.2-preview.2' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.2'
            }
        }
    }

    Context 'When handling errors' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = "The classification node 'nonexistent' does not exist. NotFoundException"
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Node not found')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'NotFoundException',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }
        }

        It 'Should warn and skip when NotFoundException occurs' {
            # Act
            Remove-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path 'nonexistent' -WarningVariable warnings -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'not found'
        }
    }

    Context 'When handling generic errors' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'An error occurred while removing the classification node.'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('API error')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'ApiError',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }
        }

        It 'Should throw error for non-NotFound exceptions' {
            # Act & Assert
            { Remove-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodePath -Confirm:$false -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*error*'
        }
    }

    Context 'Parameter validation' {
        It 'Should have StructureGroup parameter with valid values' {
            $command = Get-Command Remove-AdoClassificationNode
            $parameter = $command.Parameters['StructureGroup']
            $validateSet = $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet.ValidValues | Should -Contain 'Areas'
            $validateSet.ValidValues | Should -Contain 'Iterations'
        }
    }

    Context 'When validating ShouldProcess behavior' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should support WhatIf' {
            # Act
            Remove-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodePath -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should invoke REST method when confirmed' {
            # Act
            Remove-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodePath -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'When removing nodes with special characters in path' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should handle paths with spaces' {
            # Act
            Remove-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path 'my area 1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match 'my area 1' -or $Uri -match 'my%20area%201'
            }
        }

        It 'Should handle deeply nested paths' {
            # Act
            $deepPath = 'level-1/level-2/level-3/level-4'
            Remove-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $deepPath -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }
}
