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

Describe 'Get-AdoFeatureState' {

    Context 'When retrieving feature states successfully' {
        BeforeAll {
            # Mock Get-AdoProject for project name resolution
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                param($CollectionUri, $Name)

                return @{
                    id   = 'test-project-id-123'
                    name = $Name
                }
            }

            # Mock Invoke-AdoRestMethod for successful feature state queries
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri, $Method, $Version, $Body)

                return @{
                    featureStates = @(
                        @{
                            featureId = 'ms.vss-work.agile'
                            state     = 1
                            reason    = 'none'
                        },
                        @{
                            featureId = 'ms.vss-code.version-control'
                            state     = 1
                            reason    = 'none'
                        },
                        @{
                            featureId = 'ms.vss-build.pipelines'
                            state     = 0
                            reason    = 'none'
                        },
                        @{
                            featureId = 'ms.vss-test-web.test'
                            state     = 1
                            reason    = 'none'
                        },
                        @{
                            featureId = 'ms.azure-artifacts.feature'
                            state     = 0
                            reason    = 'none'
                        }
                    )
                }
            }
        }

        It 'Should retrieve feature states for a project by name' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'

            # Act
            $result = Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 5

            # Verify expected features are returned
            $result.feature | Should -Contain 'Boards'
            $result.feature | Should -Contain 'Repos'
            $result.feature | Should -Contain 'Pipelines'
            $result.feature | Should -Contain 'TestPlans'
            $result.feature | Should -Contain 'Artifacts'

            # Verify state mappings
            ($result | Where-Object { $_.feature -eq 'Boards' }).state | Should -Be 'enabled'
            ($result | Where-Object { $_.feature -eq 'Repos' }).state | Should -Be 'enabled'
            ($result | Where-Object { $_.feature -eq 'Pipelines' }).state | Should -Be 'disabled'
            ($result | Where-Object { $_.feature -eq 'TestPlans' }).state | Should -Be 'enabled'
            ($result | Where-Object { $_.feature -eq 'Artifacts' }).state | Should -Be 'disabled'

            # Verify Get-AdoProject was called for name resolution
            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Name -eq $projectName
            }

            # Verify Invoke-AdoRestMethod was called correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/FeatureManagement/FeatureStatesQuery/host/project/test-project-id-123" -and
                $Method -eq 'POST' -and
                $Version -eq '4.1-preview.1'
            }
        }

        It 'Should retrieve feature states when using project ID (GUID)' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectId = '12345678-1234-1234-1234-123456789abc'

            # Act
            $result = Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectId

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 5

            # Verify Get-AdoProject was NOT called (GUID doesn't need resolution)
            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 0

            # Verify Invoke-AdoRestMethod was called with the GUID
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/FeatureManagement/FeatureStatesQuery/host/project/$projectId"
            }
        }

        It 'Should include additional properties in output' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'

            # Act
            $result = Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $firstFeature = $result | Select-Object -First 1

            $firstFeature.feature | Should -Not -BeNullOrEmpty
            $firstFeature.featureId | Should -Not -BeNullOrEmpty
            $firstFeature.state | Should -BeIn @('enabled', 'disabled')
            $firstFeature.projectName | Should -Be $projectName
            $firstFeature.projectId | Should -Be 'test-project-id-123'
            $firstFeature.collectionUri | Should -Be $collectionUri
        }

        It 'Should send correct feature IDs in request body' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'

            # Act
            Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Body -and
                ($Body | ConvertFrom-Json).featureIds -contains 'ms.vss-work.agile' -and
                ($Body | ConvertFrom-Json).featureIds -contains 'ms.vss-code.version-control' -and
                ($Body | ConvertFrom-Json).featureIds -contains 'ms.vss-build.pipelines' -and
                ($Body | ConvertFrom-Json).featureIds -contains 'ms.vss-test-web.test' -and
                ($Body | ConvertFrom-Json).featureIds -contains 'ms.azure-artifacts.feature'
            }
        }
    }

    Context 'When using environment variable defaults' {
        BeforeAll {
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return @{
                    id   = 'env-project-id'
                    name = 'EnvProject'
                }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    featureStates = @(
                        @{
                            featureId = 'ms.vss-work.agile'
                            state     = 1
                        }
                    )
                }
            }
        }

        It 'Should use environment variable for CollectionUri when not specified' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/envorg'
            $env:DefaultAdoProject = 'EnvProject'

            try {
                # Act
                $result = Get-AdoFeatureState

                # Assert
                $result | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                    $Uri -like 'https://dev.azure.com/envorg/_apis/FeatureManagement/*'
                }
            } finally {
                # Cleanup
                $env:DefaultAdoCollectionUri = $null
                $env:DefaultAdoProject = $null
            }
        }

        It 'Should use environment variable for ProjectName when not specified' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/testorg'
            $env:DefaultAdoProject = 'EnvProject'

            try {
                # Act
                $result = Get-AdoFeatureState

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.projectName | Should -Be 'EnvProject'

                Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                    $Name -eq 'EnvProject'
                }
            } finally {
                # Cleanup
                $env:DefaultAdoCollectionUri = $null
                $env:DefaultAdoProject = $null
            }
        }
    }

    Context 'When using custom API version' {
        BeforeAll {
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return @{ id = 'test-project-id' }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    featureStates = @(
                        @{
                            featureId = 'ms.vss-work.agile'
                            state     = 1
                        }
                    )
                }
            }
        }

        It 'Should use specified API version' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'
            $version = '4.1-preview.1'

            # Act
            Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Version $version

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq $version
            }
        }

        It 'Should use default API version when not specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'

            # Act
            Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '4.1-preview.1'
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should have ProjectName parameter with alias ProjectId' {
            # Arrange
            $command = Get-Command Get-AdoFeatureState

            # Act
            $projectNameParam = $command.Parameters['ProjectName']

            # Assert
            $projectNameParam.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Version parameter with alias ApiVersion' {
            # Arrange
            $command = Get-Command Get-AdoFeatureState

            # Act
            $versionParam = $command.Parameters['Version']

            # Assert
            $versionParam.Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should have ValidateSet constraint on Version parameter' {
            # Arrange
            $command = Get-Command Get-AdoFeatureState
            $versionParam = $command.Parameters['Version']

            # Act
            $validateSet = $versionParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain '4.1-preview.1'
        }

        It 'Should accept CollectionUri from pipeline by property name' {
            # Arrange
            $command = Get-Command Get-AdoFeatureState
            $collectionUriParam = $command.Parameters['CollectionUri']

            # Act
            $pipelineAttribute = $collectionUriParam.Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ValueFromPipelineByPropertyName
            }

            # Assert
            $pipelineAttribute | Should -Not -BeNullOrEmpty
        }

        It 'Should accept ProjectName from pipeline by property name' {
            # Arrange
            $command = Get-Command Get-AdoFeatureState
            $projectNameParam = $command.Parameters['ProjectName']

            # Act
            $pipelineAttribute = $projectNameParam.Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ValueFromPipelineByPropertyName
            }

            # Assert
            $pipelineAttribute | Should -Not -BeNullOrEmpty
        }

        It 'Should support ShouldProcess' {
            # Arrange
            $command = Get-Command Get-AdoFeatureState

            # Act
            $supportsShouldProcess = $command.Parameters.ContainsKey('WhatIf') -and $command.Parameters.ContainsKey('Confirm')

            # Assert
            $supportsShouldProcess | Should -Be $true
        }

        It 'Should have PSCustomObject as output type' {
            # Arrange
            $command = Get-Command Get-AdoFeatureState

            # Act
            $outputType = ($command.OutputType | Select-Object -First 1).Type.Name

            # Assert
            $outputType | Should -Be 'PSObject'
        }
    }

    Context 'Error handling' {
        BeforeAll {
            # Mock Get-AdoProject to return nothing (project not found)
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return $null
            }
        }

        It 'Should return early when project is not found' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'NonExistentProject'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Should not be called'
            }

            # Act
            $result = Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -BeNullOrEmpty

            # Verify Invoke-AdoRestMethod was not called
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should throw when REST API call fails' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectId = '12345678-1234-1234-1234-123456789abc'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Access denied: User does not have permissions'
                    typeKey = 'UnauthorizedException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Unauthorized')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'Unauthorized',
                    [System.Management.Automation.ErrorCategory]::PermissionDenied,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert
            { Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectId -ErrorAction Stop } |
                Should -Throw
        }

        It 'Should throw when project ID parsing fails and Get-AdoProject throws' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'FailProject'

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                throw 'Project not found'
            }

            # Act & Assert
            { Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -ErrorAction Stop } |
                Should -Throw 'Project not found'
        }
    }

    Context 'WhatIf and Confirm support' {
        BeforeAll {
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return @{
                    id   = 'test-project-id'
                    name = 'TestProject'
                }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    featureStates = @(
                        @{
                            featureId = 'ms.vss-work.agile'
                            state     = 1
                        }
                    )
                }
            }
        }

        It 'Should support WhatIf parameter' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'

            # Act
            $result = Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -WhatIf

            # Assert
            $result | Should -BeNullOrEmpty

            # Verify Invoke-AdoRestMethod was not called
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return @{
                    id   = 'output-test-project-id'
                    name = 'OutputTestProject'
                }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    featureStates = @(
                        @{
                            featureId = 'ms.vss-work.agile'
                            state     = 1
                            reason    = 'none'
                        },
                        @{
                            featureId = 'ms.vss-code.version-control'
                            state     = 0
                            reason    = 'none'
                        }
                    )
                }
            }
        }

        It 'Should return objects with expected properties' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'OutputTestProject'

            # Act
            $result = Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | ForEach-Object {
                $_.PSObject.Properties.Name | Should -Contain 'feature'
                $_.PSObject.Properties.Name | Should -Contain 'featureId'
                $_.PSObject.Properties.Name | Should -Contain 'state'
                $_.PSObject.Properties.Name | Should -Contain 'projectName'
                $_.PSObject.Properties.Name | Should -Contain 'projectId'
                $_.PSObject.Properties.Name | Should -Contain 'collectionUri'
            }
        }

        It 'Should map feature IDs to friendly names correctly' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'OutputTestProject'

            # Act
            $result = Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty

            $boardsFeature = $result | Where-Object { $_.featureId -eq 'ms.vss-work.agile' }
            $boardsFeature.feature | Should -Be 'Boards'

            $reposFeature = $result | Where-Object { $_.featureId -eq 'ms.vss-code.version-control' }
            $reposFeature.feature | Should -Be 'Repos'
        }

        It 'Should map state values to enabled/disabled correctly' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'OutputTestProject'

            # Act
            $result = Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty

            $enabledFeature = $result | Where-Object { $_.featureId -eq 'ms.vss-work.agile' }
            $enabledFeature.state | Should -Be 'enabled'

            $disabledFeature = $result | Where-Object { $_.featureId -eq 'ms.vss-code.version-control' }
            $disabledFeature.state | Should -Be 'disabled'
        }

        It 'Should return all feature states from API response' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'OutputTestProject'

            # Act
            $result = Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }
    }

    Context 'Integration scenarios' {
        BeforeAll {
            # Mock Confirm-Default to bypass validation in pipeline scenarios
            Mock Confirm-Default -ModuleName $moduleName -MockWith {}

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                param($Name)
                return @{
                    id   = "int-project-id-$Name"
                    name = $Name
                }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    featureStates = @(
                        @{
                            featureId = 'ms.vss-work.agile'
                            state     = 1
                        },
                        @{
                            featureId = 'ms.vss-code.version-control'
                            state     = 1
                        },
                        @{
                            featureId = 'ms.vss-build.pipelines'
                            state     = 1
                        },
                        @{
                            featureId = 'ms.vss-test-web.test'
                            state     = 0
                        },
                        @{
                            featureId = 'ms.azure-artifacts.feature'
                            state     = 0
                        }
                    )
                }
            }
        }

        It 'Should handle pipeline input from Get-AdoProject' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            # Create objects that include all required properties for pipeline input
            $projectObjects = @(
                [PSCustomObject]@{
                    id            = 'project-1'
                    name          = 'Project1'
                    ProjectName   = 'Project1'
                    CollectionUri = $collectionUri
                },
                [PSCustomObject]@{
                    id            = 'project-2'
                    name          = 'Project2'
                    ProjectName   = 'Project2'
                    CollectionUri = $collectionUri
                }
            )

            # Act
            $result = $projectObjects | Get-AdoFeatureState

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 5
        }

        It 'Should work with realistic project names containing special characters' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'My-Project.Test_123'

            # Act
            $result = Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result[0].projectName | Should -Be $projectName
        }

        It 'Should handle multiple consecutive calls for different projects' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projects = @('Project1', 'Project2', 'Project3')

            # Act
            $results = foreach ($project in $projects) {
                Get-AdoFeatureState -CollectionUri $collectionUri -ProjectName $project
            }

            # Assert
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterOrEqual 15  # 5 features per project × 3 projects

            # Verify each project was called
            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 3
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
        }
    }
}
