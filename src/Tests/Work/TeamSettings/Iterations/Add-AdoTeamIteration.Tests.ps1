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

Describe 'Add-AdoTeamIteration' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $teamName = 'my-team'
        $iterationId = '11111111-1111-1111-1111-111111111111'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When adding an iteration to a team' {
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

        It 'Should add iteration by ID' {
            # Act
            $result = Add-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Id $iterationId -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be $iterationId
            $result.name | Should -Be 'Sprint 1'
            $result.team | Should -Be $teamName
            $result.project | Should -Be $projectName
            $result.collectionUri | Should -Be $collectionUri
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/work/teamsettings/iterations" -and
                $Uri -match "$projectName/$teamName" -and
                $Method -eq 'POST'
            }
        }

        It 'Should include iteration attributes in output' {
            # Act
            $result = Add-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Id $iterationId -Confirm:$false

            # Assert
            $result.attributes | Should -Not -BeNullOrEmpty
            $result.attributes.startDate | Should -Be '2026-01-01T00:00:00Z'
            $result.attributes.finishDate | Should -Be '2026-01-15T00:00:00Z'
            $result.attributes.timeFrame | Should -Be 'current'
        }

        It 'Should use correct API version' {
            # Act
            Add-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Id $iterationId -Version '7.1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should call REST API with POST method' {
            # Act
            Add-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Id $iterationId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Method -eq 'POST'
            }
        }
    }

    Context 'When adding multiple iterations from pipeline' {
        BeforeAll {
            $script:callCount = 0
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $script:callCount++
                $id = if ($script:callCount -eq 1) { '11111111-1111-1111-1111-111111111111' } else { '22222222-2222-2222-2222-222222222222' }
                return @{
                    id         = $id
                    name       = "Sprint $script:callCount"
                    attributes = @{
                        startDate  = '2026-01-01T00:00:00Z'
                        finishDate = '2026-01-15T00:00:00Z'
                        timeFrame  = 'current'
                    }
                }
            }
        }

        It 'Should process multiple iteration IDs from pipeline' {
            # Act
            $result = @('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222') |
                Add-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }

    Context 'When iteration does not exist' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    '$id'            = '1'
                    'innerException' = $null
                    'message'        = 'VS403248: InvalidTeamSettingsIterationException'
                    'typeName'       = 'Microsoft.TeamFoundation.Core.WebApi.InvalidTeamSettingsIterationException, Microsoft.TeamFoundation.Core.WebApi'
                    'typeKey'        = 'InvalidTeamSettingsIterationException'
                    'errorCode'      = 0
                    'eventId'        = 3000
                } | ConvertTo-Json -Compress

                $exception = [System.Net.WebException]::new('Invalid iteration')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'WebException',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $null
                )
                $errorRecord.ErrorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                throw $errorRecord
            }
        }

        It 'Should handle InvalidTeamSettingsIterationException and write warning' {
            # Act
            $result = Add-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Id 'invalid-id' -Confirm:$false -WarningVariable warnings -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
            $warnings | Should -Not -BeNullOrEmpty
            $warnings | Should -Match 'does not exist, skipping'
        }

        It 'Should not throw on InvalidTeamSettingsIterationException' {
            # Act & Assert
            { Add-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Id 'invalid-id' -Confirm:$false -WarningAction SilentlyContinue } |
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

        It 'Should throw on non-InvalidTeamSettingsIterationException errors' {
            # Act & Assert
            { Add-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Id $iterationId -Confirm:$false } |
                Should -Throw
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should not call REST API when WhatIf is specified' {
            # Act
            Add-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Id $iterationId -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with default value' {
            $command = Get-Command Add-AdoTeamIteration
            $parameter = $command.Parameters['CollectionUri']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
        }

        It 'Should have ProjectName parameter with ProjectId alias' {
            $command = Get-Command Add-AdoTeamIteration
            $parameter = $command.Parameters['ProjectName']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have TeamName as mandatory parameter' {
            $command = Get-Command Add-AdoTeamIteration
            $parameter = $command.Parameters['TeamName']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes.Mandatory | Should -Contain $true
            $parameter.Aliases | Should -Contain 'Team'
            $parameter.Aliases | Should -Contain 'TeamId'
        }

        It 'Should have Id as mandatory parameter' {
            $command = Get-Command Add-AdoTeamIteration
            $parameter = $command.Parameters['Id']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes.Mandatory | Should -Contain $true
            $parameter.Aliases | Should -Contain 'IterationId'
        }

        It 'Should have Version parameter with ApiVersion alias' {
            $command = Get-Command Add-AdoTeamIteration
            $parameter = $command.Parameters['Version']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ApiVersion'
            $parameter.Aliases | Should -Contain 'api'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Add-AdoTeamIteration
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'Using pipeline input with ValueFromPipelineByPropertyName' {
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

        It 'Should accept object with properties from pipeline' {
            # Arrange
            $inputObject = [PSCustomObject]@{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                TeamName      = $teamName
                Id            = $iterationId
            }

            # Act
            $result = $inputObject | Add-AdoTeamIteration -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'Output validation' {
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

        It 'Should return PSCustomObject' {
            # Act
            $result = Add-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Id $iterationId -Confirm:$false

            # Assert
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Should include all required properties' {
            # Act
            $result = Add-AdoTeamIteration -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Id $iterationId -Confirm:$false

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'id'
            $result.PSObject.Properties.Name | Should -Contain 'name'
            $result.PSObject.Properties.Name | Should -Contain 'attributes'
            $result.PSObject.Properties.Name | Should -Contain 'team'
            $result.PSObject.Properties.Name | Should -Contain 'project'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }
    }
}
