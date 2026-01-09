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

Describe 'Get-AdoClassificationNode' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $nodeId = 123
        $nodeName = 'my-area-1'
        $nodeIdentifier = '11111111-1111-1111-1111-111111111111'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When retrieving all root classification nodes' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{
                            id            = 123
                            identifier    = '11111111-1111-1111-1111-111111111111'
                            name          = 'Area'
                            structureType = 'area'
                            path          = '\my-project-1\Area'
                            hasChildren   = $true
                        },
                        @{
                            id            = 456
                            identifier    = '22222222-2222-2222-2222-222222222222'
                            name          = 'Iteration'
                            structureType = 'iteration'
                            path          = '\my-project-1\Iteration'
                            hasChildren   = $true
                        }
                    )
                }
            }
        }

        It 'Should retrieve all root classification nodes when no parameters specified' {
            # Arrange & Act
            $result = Get-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].structureType | Should -Be 'area'
            $result[1].structureType | Should -Be 'iteration'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/wit/classificationnodes`$" -and
                $Method -eq 'GET'
            }
        }

        It 'Should add collectionUri and projectName properties to each node' {
            # Act
            $result = Get-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result[0].collectionUri | Should -Be $collectionUri
            $result[0].projectName | Should -Be $projectName
            $result[1].collectionUri | Should -Be $collectionUri
            $result[1].projectName | Should -Be $projectName
        }
    }

    Context 'When retrieving root node by structure group' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri)
                if ($Uri -match '/Areas') {
                    return @{
                        id            = 123
                        identifier    = '11111111-1111-1111-1111-111111111111'
                        name          = 'Area'
                        structureType = 'area'
                        path          = '\my-project-1\Area'
                        hasChildren   = $true
                    }
                } elseif ($Uri -match '/Iterations') {
                    return @{
                        id            = 456
                        identifier    = '22222222-2222-2222-2222-222222222222'
                        name          = 'Iteration'
                        structureType = 'iteration'
                        path          = '\my-project-1\Iteration'
                        hasChildren   = $true
                    }
                }
            }
        }

        It 'Should retrieve root <StructureGroup> node' -ForEach @(
            @{ StructureGroup = 'Areas'; ExpectedType = 'area' }
            @{ StructureGroup = 'Iterations'; ExpectedType = 'iteration' }
        ) {
            # Act
            $result = Get-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup $StructureGroup

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.structureType | Should -Be $ExpectedType
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/wit/classificationnodes/$StructureGroup`$" -and
                $Method -eq 'GET'
            }
        }
    }

    Context 'When retrieving classification node by path' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'
                $script:nodeName = 'my-area-1'

                return @{
                    id            = 123
                    identifier    = '11111111-1111-1111-1111-111111111111'
                    name          = $script:nodeName
                    structureType = 'area'
                    path          = "\$script:projectName\Area\$script:nodeName"
                    hasChildren   = $false
                }
            }
        }

        It 'Should retrieve classification node by path' {
            # Act
            $result = Get-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nodeName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $nodeName
            $result.structureType | Should -Be 'area'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/wit/classificationnodes/Areas/$nodeName" -and
                $Method -eq 'GET'
            }
        }

        It 'Should retrieve classification node with nested path' {
            # Act
            $nestedPath = 'my-team-1/my-subarea-1'
            $result = Get-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path $nestedPath

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/wit/classificationnodes/Areas/$($nestedPath -replace '/', '%2F'|Out-String)" -or
                $Uri -match "_apis/wit/classificationnodes/Areas/my-team-1/my-subarea-1"
            }
        }
    }

    Context 'When retrieving classification nodes by IDs' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    count = 2
                    value = @(
                        @{
                            id            = 123
                            identifier    = '11111111-1111-1111-1111-111111111111'
                            name          = 'my-area-1'
                            structureType = 'area'
                            path          = '\my-project-1\Area\my-area-1'
                            hasChildren   = $false
                        },
                        @{
                            id            = 456
                            identifier    = '22222222-2222-2222-2222-222222222222'
                            name          = 'my-area-2'
                            structureType = 'area'
                            path          = '\my-project-1\Area\my-area-2'
                            hasChildren   = $false
                        }
                    )
                }
            }
        }

        It 'Should retrieve multiple classification nodes by IDs' {
            # Act
            $result = Get-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -Ids 123, 456

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match 'ids=123,456' -and
                $Method -eq 'GET'
            }
        }

        It 'Should use ErrorPolicy parameter when specified' {
            # Act
            Get-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -Ids 123, 456 -ErrorPolicy 'omit'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match 'errorPolicy=omit'
            }
        }

        It 'Should use ErrorPolicy <Policy>' -ForEach @(
            @{ Policy = 'fail' }
            @{ Policy = 'omit' }
        ) {
            # Act
            Get-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -Ids 123 -ErrorPolicy $Policy

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match "errorPolicy=$Policy"
            }
        }
    }

    Context 'When using depth parameter' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id            = 123
                    identifier    = '11111111-1111-1111-1111-111111111111'
                    name          = 'Area'
                    structureType = 'area'
                    path          = '\my-project-1\Area'
                    hasChildren   = $true
                    children      = @(
                        @{
                            id            = 124
                            identifier    = '33333333-3333-3333-3333-333333333333'
                            name          = 'my-area-1'
                            structureType = 'area'
                            path          = '\my-project-1\Area\my-area-1'
                            hasChildren   = $true
                            children      = @(
                                @{
                                    id            = 125
                                    identifier    = '44444444-4444-4444-4444-444444444444'
                                    name          = 'my-subarea-1'
                                    structureType = 'area'
                                    path          = '\my-project-1\Area\my-area-1\my-subarea-1'
                                    hasChildren   = $false
                                }
                            )
                        }
                    )
                }
            }
        }

        It 'Should retrieve classification nodes with depth parameter' {
            # Act
            $result = Get-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Depth 2

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.children | Should -Not -BeNullOrEmpty
            $result.children[0].children | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match '\$depth=2'
            }
        }

        It 'Should retrieve classification nodes with depth <Depth>' -ForEach @(
            @{ Depth = 1 }
            @{ Depth = 2 }
            @{ Depth = 5 }
        ) {
            # Act
            Get-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Depth $Depth

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match "\`$depth=$Depth"
            }
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id            = 123
                    identifier    = '11111111-1111-1111-1111-111111111111'
                    name          = 'my-area-1'
                    structureType = 'area'
                    path          = '\my-project-1\Area\my-area-1'
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
            }
            $result = $inputObject | Get-AdoClassificationNode

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'When using API version parameter' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id            = 123
                    identifier    = '11111111-1111-1111-1111-111111111111'
                    name          = 'Area'
                    structureType = 'area'
                    path          = '\my-project-1\Area'
                    hasChildren   = $true
                }
            }
        }

        It 'Should use API version 7.2-preview.2' {
            # Act
            Get-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Version '7.2-preview.2'

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
                    message = "The classification node 'nonexistent' does not exist."
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Classification node not found')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'ClassificationNodeNotFound',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }
        }

        It 'Should throw error when classification node not found' {
            # Act & Assert
            { Get-AdoClassificationNode -CollectionUri $collectionUri -ProjectName $projectName -StructureGroup 'Areas' -Path 'nonexistent' -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*not found*'
        }
    }

    Context 'Parameter validation' {
        It 'Should have StructureGroup parameter with valid values' {
            $command = Get-Command Get-AdoClassificationNode
            $parameter = $command.Parameters['StructureGroup']
            $parameter | Should -Not -BeNullOrEmpty
            $validateSet = $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet.ValidValues | Should -Contain 'Areas'
            $validateSet.ValidValues | Should -Contain 'Iterations'
        }

        It 'Should have ErrorPolicy parameter with valid values' {
            $command = Get-Command Get-AdoClassificationNode
            $parameter = $command.Parameters['ErrorPolicy']
            $parameter | Should -Not -BeNullOrEmpty
            $validateSet = $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet.ValidValues | Should -Contain 'fail'
            $validateSet.ValidValues | Should -Contain 'omit'
        }
    }
}
