[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '', Scope = 'Function', Target = '*', Justification = 'Variables are used in nested It blocks')]
param()

BeforeAll {
    # Import the module for testing
    $moduleName = 'Azure.DevOps.PSModule'
    $modulePath = Join-Path -Path (Get-Item $PSScriptRoot).Parent.Parent.Parent.Parent.FullName -ChildPath $moduleName

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

Describe 'Get-AdoTeamIteration' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $teamName = 'my-team'
        $iterationId = '11111111-1111-1111-1111-111111111111'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When retrieving all iterations' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{
                            id         = '11111111-1111-1111-1111-111111111111'
                            name       = 'Sprint 1'
                            attributes = @{
                                startDate  = '2026-01-01T00:00:00Z'
                                finishDate = '2026-01-15T00:00:00Z'
                                timeFrame  = 'past'
                            }
                        },
                        @{
                            id         = '22222222-2222-2222-2222-222222222222'
                            name       = 'Sprint 2'
                            attributes = @{
                                startDate  = '2026-01-16T00:00:00Z'
                                finishDate = '2026-01-31T00:00:00Z'
                                timeFrame  = 'current'
                            }
                        },
                        @{
                            id         = '33333333-3333-3333-3333-333333333333'
                            name       = 'Sprint 3'
                            attributes = @{
                                startDate  = '2026-02-01T00:00:00Z'
                                finishDate = '2026-02-15T00:00:00Z'
                                timeFrame  = 'future'
                            }
                        }
                    )
                }
            }
        }

        It 'Should retrieve all iterations when no parameters specified' {
            # Act
            $result = Get-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].name | Should -Be 'Sprint 1'
            $result[1].name | Should -Be 'Sprint 2'
            $result[2].name | Should -Be 'Sprint 3'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/work/teamsettings/iterations" -and
                $Uri -match "$projectName/$teamName" -and
                $Method -eq 'GET'
            }
        }

        It 'Should include all properties in output' {
            # Act
            $result = Get-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName

            # Assert
            $result[0].id | Should -Be '11111111-1111-1111-1111-111111111111'
            $result[0].name | Should -Be 'Sprint 1'
            $result[0].attributes | Should -Not -BeNullOrEmpty
            $result[0].team | Should -Be $teamName
            $result[0].project | Should -Be $projectName
            $result[0].collectionUri | Should -Be $collectionUri
        }

        It 'Should include iteration attributes' {
            # Act
            $result = Get-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName

            # Assert
            $result[0].attributes.startDate | Should -Be '2026-01-01T00:00:00Z'
            $result[0].attributes.finishDate | Should -Be '2026-01-15T00:00:00Z'
            $result[0].attributes.timeFrame | Should -Be 'past'
            $result[1].attributes.timeFrame | Should -Be 'current'
            $result[2].attributes.timeFrame | Should -Be 'future'
        }
    }

    Context 'When filtering iterations by timeframe' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri, $QueryParameters)

                if ($QueryParameters -match 'timeframe=current') {
                    return @{
                        value = @(
                            @{
                                id         = '22222222-2222-2222-2222-222222222222'
                                name       = 'Sprint 2'
                                attributes = @{
                                    startDate  = '2026-01-16T00:00:00Z'
                                    finishDate = '2026-01-31T00:00:00Z'
                                    timeFrame  = 'current'
                                }
                            }
                        )
                    }
                } elseif ($QueryParameters -match 'timeframe=past') {
                    return @{
                        value = @(
                            @{
                                id         = '11111111-1111-1111-1111-111111111111'
                                name       = 'Sprint 1'
                                attributes = @{
                                    startDate  = '2026-01-01T00:00:00Z'
                                    finishDate = '2026-01-15T00:00:00Z'
                                    timeFrame  = 'past'
                                }
                            }
                        )
                    }
                } elseif ($QueryParameters -match 'timeframe=future') {
                    return @{
                        value = @(
                            @{
                                id         = '33333333-3333-3333-3333-333333333333'
                                name       = 'Sprint 3'
                                attributes = @{
                                    startDate  = '2026-02-01T00:00:00Z'
                                    finishDate = '2026-02-15T00:00:00Z'
                                    timeFrame  = 'future'
                                }
                            }
                        )
                    }
                } else {
                    return @{
                        value = @()
                    }
                }
            }
        }

        It 'Should filter by current timeframe' {
            # Act
            $result = Get-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -TimeFrame 'current'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result.name | Should -Be 'Sprint 2'
            $result.attributes.timeFrame | Should -Be 'current'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match '\$timeframe=current'
            }
        }

        It 'Should filter by past timeframe' {
            # Act
            $result = Get-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -TimeFrame 'past'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'Sprint 1'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match '\$timeframe=past'
            }
        }

        It 'Should filter by future timeframe' {
            # Act
            $result = Get-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -TimeFrame 'future'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'Sprint 3'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match '\$timeframe=future'
            }
        }
    }

    Context 'When retrieving specific iteration by ID' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id         = '11111111-1111-1111-1111-111111111111'
                    name       = 'Sprint 1'
                    attributes = @{
                        startDate  = '2026-01-01T00:00:00Z'
                        finishDate = '2026-01-15T00:00:00Z'
                        timeFrame  = 'past'
                    }
                }
            }
        }

        It 'Should retrieve specific iteration by ID' {
            # Act
            $result = Get-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Id $iterationId

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be $iterationId
            $result.name | Should -Be 'Sprint 1'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/work/teamsettings/iterations/$iterationId" -and
                $Method -eq 'GET'
            }
        }
    }

    Context 'When iteration does not exist' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    '$id'            = '1'
                    'innerException' = $null
                    'message'        = 'VS403249: NotFoundException'
                    'typeName'       = 'Microsoft.TeamFoundation.Core.WebApi.NotFoundException, Microsoft.TeamFoundation.Core.WebApi'
                    'typeKey'        = 'NotFoundException'
                    'errorCode'      = 0
                    'eventId'        = 3000
                } | ConvertTo-Json -Compress

                $exception = [System.Net.WebException]::new('Not found')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'WebException',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $null
                )
                $errorRecord.ErrorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                throw $errorRecord
            }
        }

        It 'Should handle NotFoundException and write warning' {
            # Act
            $result = Get-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Id 'invalid-id' -WarningVariable warnings -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
            $warnings | Should -Not -BeNullOrEmpty
            $warnings | Should -Match 'does not exist, skipping'
        }

        It 'Should not throw on NotFoundException' {
            # Act & Assert
            { Get-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Id 'invalid-id' -WarningAction SilentlyContinue } |
                Should -Not -Throw
        }
    }

    Context 'When REST API call fails with other error' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorDetails = @{
                    message = @{
                        value = 'Unauthorized access'
                    } | ConvertTo-Json
                } | ConvertTo-Json

                $exception = [System.Net.WebException]::new('Unauthorized')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'UnauthorizedException',
                    [System.Management.Automation.ErrorCategory]::PermissionDenied,
                    $null
                )
                $errorRecord.ErrorDetails = [System.Management.Automation.ErrorDetails]::new($errorDetails)
                throw $errorRecord
            }
        }

        It 'Should throw on non-NotFoundException errors' {
            # Act & Assert
            { Get-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Id $iterationId } |
                Should -Throw
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should not call REST API when WhatIf is specified' {
            # Act
            Get-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }

    Context 'Using different API versions' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{
                            id         = '11111111-1111-1111-1111-111111111111'
                            name       = 'Sprint 1'
                            attributes = @{
                                startDate  = '2026-01-01T00:00:00Z'
                                finishDate = '2026-01-15T00:00:00Z'
                                timeFrame  = 'current'
                            }
                        }
                    )
                }
            }
        }

        It 'Should use default API version 7.1' {
            # Act
            Get-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should use specified API version' {
            # Act
            Get-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Version '7.2-preview.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with default value' {
            $command = Get-Command Get-AdoTeamIteration
            $parameter = $command.Parameters['CollectionUri']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
        }

        It 'Should have ProjectName parameter with ProjectId alias' {
            $command = Get-Command Get-AdoTeamIteration
            $parameter = $command.Parameters['ProjectName']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have TeamName as mandatory parameter' {
            $command = Get-Command Get-AdoTeamIteration
            $parameter = $command.Parameters['TeamName']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes.Mandatory | Should -Contain $true
            $parameter.Aliases | Should -Contain 'TeamId'
        }

        It 'Should have Id parameter with IterationId alias' {
            $command = Get-Command Get-AdoTeamIteration
            $parameter = $command.Parameters['Id']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'IterationId'
        }

        It 'Should have TimeFrame parameter with ValidateSet' {
            $command = Get-Command Get-AdoTeamIteration
            $parameter = $command.Parameters['TimeFrame']
            $parameter | Should -Not -BeNullOrEmpty
            $validateSet = $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet.ValidValues | Should -Contain 'past'
            $validateSet.ValidValues | Should -Contain 'current'
            $validateSet.ValidValues | Should -Contain 'future'
        }

        It 'Should have Version parameter with ApiVersion alias' {
            $command = Get-Command Get-AdoTeamIteration
            $parameter = $command.Parameters['Version']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ApiVersion'
            $parameter.Aliases | Should -Contain 'api'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Get-AdoTeamIteration
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should have ListIterations and ById parameter sets' {
            $command = Get-Command Get-AdoTeamIteration
            $parameterSets = $command.ParameterSets
            $parameterSets.Name | Should -Contain 'ListIterations'
            $parameterSets.Name | Should -Contain 'ById'
        }

        It 'Should have TimeFrame in ListIterations parameter set only' {
            $command = Get-Command Get-AdoTeamIteration
            $parameter = $command.Parameters['TimeFrame']
            $parameterSets = $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            $parameterSetNames = $parameterSets | Select-Object -ExpandProperty ParameterSetName
            $parameterSetNames | Should -Contain 'ListIterations'
            $parameterSetNames | Should -Not -Contain 'ById'
        }

        It 'Should have Id in ById parameter set only' {
            $command = Get-Command Get-AdoTeamIteration
            $parameter = $command.Parameters['Id']
            $parameterSets = $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            $parameterSetNames = $parameterSets | Select-Object -ExpandProperty ParameterSetName
            $parameterSetNames | Should -Contain 'ById'
        }
    }

    Context 'Using pipeline input with ValueFromPipelineByPropertyName' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{
                            id         = '11111111-1111-1111-1111-111111111111'
                            name       = 'Sprint 1'
                            attributes = @{
                                startDate  = '2026-01-01T00:00:00Z'
                                finishDate = '2026-01-15T00:00:00Z'
                                timeFrame  = 'current'
                            }
                        }
                    )
                }
            }
        }

        It 'Should accept object with properties from pipeline' {
            # Arrange
            $inputObject = [PSCustomObject]@{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                TeamName      = $teamName
            }

            # Act
            $result = $inputObject | Get-AdoTeamIteration

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should accept object with Id property from pipeline' {
            # Arrange
            BeforeAll {
                Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                    return @{
                        id         = '11111111-1111-1111-1111-111111111111'
                        name       = 'Sprint 1'
                        attributes = @{
                            startDate  = '2026-01-01T00:00:00Z'
                            finishDate = '2026-01-15T00:00:00Z'
                            timeFrame  = 'current'
                        }
                    }
                }
            }

            $inputObject = [PSCustomObject]@{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                TeamName      = $teamName
                Id            = $iterationId
            }

            # Act
            $result = $inputObject | Get-AdoTeamIteration

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be $iterationId
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{
                            id         = '11111111-1111-1111-1111-111111111111'
                            name       = 'Sprint 1'
                            attributes = @{
                                startDate  = '2026-01-01T00:00:00Z'
                                finishDate = '2026-01-15T00:00:00Z'
                                timeFrame  = 'current'
                            }
                        }
                    )
                }
            }
        }

        It 'Should return array of PSCustomObjects' {
            # Act
            $result = Get-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName

            # Assert
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Should include all required properties' {
            # Act
            $result = Get-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName

            # Assert
            $result[0].PSObject.Properties.Name | Should -Contain 'id'
            $result[0].PSObject.Properties.Name | Should -Contain 'name'
            $result[0].PSObject.Properties.Name | Should -Contain 'attributes'
            $result[0].PSObject.Properties.Name | Should -Contain 'team'
            $result[0].PSObject.Properties.Name | Should -Contain 'project'
            $result[0].PSObject.Properties.Name | Should -Contain 'collectionUri'
        }
    }
}
