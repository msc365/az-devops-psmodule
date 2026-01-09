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

Describe 'Set-AdoClassificationNode' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $nodePath = 'my-area-1'
        $nodeId = 123

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When updating area node properties' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body, $Uri)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'

                return @{
                    id            = 123
                    identifier    = '11111111-1111-1111-1111-111111111111'
                    name          = if ($Body.name) { $Body.name } else { 'existing-area' }
                    structureType = 'area'
                    path          = "\$script:projectName\Area\$($Body.name ?? 'existing-area')"
                    hasChildren   = $false
                }
            }
        }

        It 'Should update area node name' {
            # Act
            $result = Set-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodePath -Name 'updated-area' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'updated-area'
            $result.collectionUri | Should -Be $collectionUri
            $result.projectName | Should -Be $projectName
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/wit/classificationnodes/Areas/$nodePath" -and
                $Method -eq 'PATCH' -and
                $Body.name -eq 'updated-area'
            }
        }
    }

    Context 'When updating iteration node properties' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body, $Uri)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'

                $response = @{
                    id            = 456
                    identifier    = '22222222-2222-2222-2222-222222222222'
                    name          = if ($Body.name) { $Body.name } else { 'existing-iteration' }
                    structureType = 'iteration'
                    path          = "\$script:projectName\Iteration\$($Body.name ?? 'existing-iteration')"
                    hasChildren   = $false
                }

                if ($Body.attributes) {
                    $response['attributes'] = @{}
                    if ($Body.attributes.startDate) {
                        $response.attributes['startDate'] = $Body.attributes.startDate
                    }
                    if ($Body.attributes.finishDate) {
                        $response.attributes['finishDate'] = $Body.attributes.finishDate
                    }
                }

                return $response
            }
        }

        It 'Should update iteration node <Property>' -ForEach @(
            @{ Property = 'Name'; ParameterValue = 'updated-iteration'; BodyProperty = 'name' }
            @{ Property = 'StartDate'; ParameterValue = [datetime]'2024-01-01'; BodyProperty = 'attributes.startDate' }
            @{ Property = 'FinishDate'; ParameterValue = [datetime]'2024-12-31'; BodyProperty = 'attributes.finishDate' }
        ) {
            # Arrange & Act
            $params = @{
                CollectionUri  = $collectionUri
                ProjectName    = $projectName
                StructureGroup = 'Iterations'
                Path           = 'Sprint 1'
                $Property      = $ParameterValue
                Confirm        = $false
            }
            $result = Set-AdoClassificationNode @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/wit/classificationnodes/Iterations/Sprint 1" -and
                $Method -eq 'PATCH'
            }
        }

        It 'Should update multiple iteration properties together' {
            # Act
            $startDate = [datetime]'2024-01-01'
            $finishDate = [datetime]'2024-12-31'
            $result = Set-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Iterations' -Path 'Sprint 1' -Name 'Sprint 1 Updated' -StartDate $startDate -FinishDate $finishDate -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Body.name -eq 'Sprint 1 Updated' -and
                $Body.attributes.startDate -and
                $Body.attributes.finishDate
            }
        }

        It 'Should include attributes in output when dates are set' {
            # Act
            $startDate = [datetime]'2024-01-01'
            $finishDate = [datetime]'2024-12-31'
            $result = Set-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Iterations' -Path 'Sprint 1' -StartDate $startDate -FinishDate $finishDate -Confirm:$false

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'attributes'
            $result.attributes | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When validating iteration-specific properties on areas' {
        It 'Should throw error when setting StartDate on area node' {
            # Act & Assert
            { Set-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodePath -StartDate ([datetime]'2024-01-01') -Confirm:$false -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*can only be set for Iteration nodes*'
        }

        It 'Should throw error when setting FinishDate on area node' {
            # Act & Assert
            { Set-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodePath -FinishDate ([datetime]'2024-12-31') -Confirm:$false -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*can only be set for Iteration nodes*'
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body, $Uri)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'

                # Extract path from URI
                $pathFromUri = $Uri -replace '.*classificationnodes/[^/]+/(.+)\?.*', '$1'
                $pathFromUri = $pathFromUri -replace '.*classificationnodes/[^/]+/(.+)$', '$1'

                return @{
                    id            = 123
                    identifier    = '11111111-1111-1111-1111-111111111111'
                    name          = if ($Body.name) { $Body.name } else { $pathFromUri }
                    structureType = 'area'
                    path          = "\$script:projectName\Area\$($Body.name ?? $pathFromUri)"
                    hasChildren   = $false
                }
            }
        }

        It 'Should accept parameters from pipeline by property name' {
            # Act
            $inputObject = [PSCustomObject]@{
                CollectionUri  = $collectionUri
                ProjectName    = $projectName
                StructureGroup = 'Areas'
                Path           = 'my-area-1'
                Name           = 'updated-area'
            }
            $result = $inputObject | Set-AdoClassificationNode -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should update multiple nodes from pipeline' {
            # Act
            $inputObjects = @(
                [PSCustomObject]@{ CollectionUri = $collectionUri; ProjectName = $projectName; StructureGroup = 'Areas'; Path = 'area-1'; Name = 'updated' }
                [PSCustomObject]@{ CollectionUri = $collectionUri; ProjectName = $projectName; StructureGroup = 'Areas'; Path = 'area-2'; Name = 'updated' }
            )
            $result = $inputObjects | Set-AdoClassificationNode -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }

    Context 'When using API version parameter' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                return @{
                    id            = 123
                    identifier    = '11111111-1111-1111-1111-111111111111'
                    name          = $Body.name
                    structureType = 'area'
                    path          = '\my-project-1\Area\updated-area'
                    hasChildren   = $false
                }
            }
        }

        It 'Should use API version 7.2-preview.2' {
            # Act
            Set-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodePath -Name 'updated-area' -Version '7.2-preview.2' -Confirm:$false

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
                    message = "The classification node with name 'duplicate-name' already exists. DuplicateNameException"
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Duplicate name')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'DuplicateNameException',
                    [System.Management.Automation.ErrorCategory]::ResourceExists,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }
        }

        It 'Should warn and skip when DuplicateNameException occurs' {
            # Act
            Set-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodePath -Name 'duplicate-name' -WarningVariable warnings -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'already exists'
        }
    }

    Context 'When node not found' {
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
            Set-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path 'nonexistent' -Name 'updated' -WarningVariable warnings -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'not found'
        }
    }

    Context 'When no properties specified' {
        It 'Should throw error when no update properties specified' {
            # Act & Assert
            { Set-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodePath -Confirm:$false -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*At least one property*'
        }
    }

    Context 'Parameter validation' {
        It 'Should have StructureGroup parameter with valid values' {
            $command = Get-Command Set-AdoClassificationNode
            $parameter = $command.Parameters['StructureGroup']
            $validateSet = $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet.ValidValues | Should -Contain 'Areas'
            $validateSet.ValidValues | Should -Contain 'Iterations'
        }
    }

    Context 'When validating ShouldProcess behavior' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                return @{
                    id            = 123
                    identifier    = '11111111-1111-1111-1111-111111111111'
                    name          = $Body.name
                    structureType = 'area'
                    path          = '\my-project-1\Area\updated-area'
                    hasChildren   = $false
                }
            }
        }

        It 'Should support WhatIf' {
            # Act
            Set-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodePath -Name 'updated-area' -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should invoke REST method when confirmed' {
            # Act
            Set-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodePath -Name 'updated-area' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }


}
