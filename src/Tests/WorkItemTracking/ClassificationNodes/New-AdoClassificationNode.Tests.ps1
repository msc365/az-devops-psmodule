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

Describe 'New-AdoClassificationNode' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $nodeName = 'my-area-1'
        $nodeId = 123
        $nodeIdentifier = '11111111-1111-1111-1111-111111111111'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When creating a new classification node at root level' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'

                return @{
                    id            = 123
                    identifier    = '11111111-1111-1111-1111-111111111111'
                    name          = $Body.name
                    structureType = 'area'
                    path          = "\$script:projectName\Area\$($Body.name)"
                    hasChildren   = $false
                }
            }
        }

        It 'Should create a new <StructureGroup> node at root level' -ForEach @(
            @{ StructureGroup = 'Areas'; ExpectedType = 'area' }
            @{ StructureGroup = 'Iterations'; ExpectedType = 'iteration' }
        ) {
            # Arrange
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'

                return @{
                    id            = 123
                    identifier    = '11111111-1111-1111-1111-111111111111'
                    name          = $Body.name
                    structureType = $ExpectedType
                    path          = "\$script:projectName\$StructureGroup\$($Body.name)"
                    hasChildren   = $false
                }
            }

            # Act
            $result = New-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup $StructureGroup -Name $nodeName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $nodeName
            $result.id | Should -Not -BeNullOrEmpty
            $result.structureType | Should -Be $ExpectedType
            $result.collectionUri | Should -Be $collectionUri
            $result.projectName | Should -Be $projectName
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/wit/classificationnodes/$StructureGroup`$" -and
                $Method -eq 'POST'
            }
        }

        It 'Should create an area node with required parameters only' {
            # Act
            $result = New-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Name $nodeName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $nodeName
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Body.name -eq $nodeName
            }
        }
    }

    Context 'When creating a nested classification node' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body, $Uri)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'

                return @{
                    id            = 124
                    identifier    = '22222222-2222-2222-2222-222222222222'
                    name          = $Body.name
                    structureType = 'area'
                    path          = "\$script:projectName\Area\my-team-1\$($Body.name)"
                    hasChildren   = $false
                }
            }
        }

        It 'Should create a nested classification node under specified path' {
            # Act
            $result = New-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path 'my-team-1' -Name 'my-subarea-1' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'my-subarea-1'
            $result.path | Should -Match 'my-team-1'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/wit/classificationnodes/Areas/my-team-1" -and
                $Method -eq 'POST'
            }
        }

        It 'Should create a deeply nested classification node' {
            # Act
            $deepPath = 'my-team-1/my-subarea-1/my-deeper-area'
            $result = New-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $deepPath -Name 'my-deepest-area' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match [regex]::Escape($deepPath)
            }
        }
    }

    Context 'When classification node already exists' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = "The classification node with name '$nodeName' already exists. DuplicateNameException"
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Classification node already exists')
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
            $result = New-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Name $nodeName -WarningVariable warnings -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'already exists'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'

                return @{
                    id            = [guid]::NewGuid().ToString()
                    identifier    = [guid]::NewGuid().ToString()
                    name          = $Body.name
                    structureType = 'area'
                    path          = "\$script:projectName\Area\$($Body.name)"
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
                Name           = 'pipeline-area'
            }
            $result = $inputObject | New-AdoClassificationNode -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'pipeline-area'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should create multiple nodes from pipeline' {
            # Act
            $inputObjects = @(
                [PSCustomObject]@{ CollectionUri = $collectionUri; ProjectName = $projectName; StructureGroup = 'Areas'; Name = 'area-1' }
                [PSCustomObject]@{ CollectionUri = $collectionUri; ProjectName = $projectName; StructureGroup = 'Areas'; Name = 'area-2' }
                [PSCustomObject]@{ CollectionUri = $collectionUri; ProjectName = $projectName; StructureGroup = 'Areas'; Name = 'area-3' }
            )
            $result = $inputObjects | New-AdoClassificationNode -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
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
                    path          = '\my-project-1\Area\my-area-1'
                    hasChildren   = $false
                }
            }
        }

        It 'Should use API version 7.2-preview.2' {
            # Act
            New-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Name $nodeName -Version '7.2-preview.2' -Confirm:$false

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
                    message = 'An error occurred while creating the classification node.'
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

        It 'Should throw error for non-duplicate exceptions' {
            # Act & Assert
            { New-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Name $nodeName -Confirm:$false -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*error*'
        }
    }

    Context 'Parameter validation' {
        It 'Should have StructureGroup parameter with valid values' {
            $command = Get-Command New-AdoClassificationNode
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
                    path          = '\my-project-1\Area\my-area-1'
                    hasChildren   = $false
                }
            }
        }

        It 'Should support WhatIf' {
            # Act
            New-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Name $nodeName -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should invoke REST method when confirmed' {
            # Act
            New-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Name $nodeName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }


}
