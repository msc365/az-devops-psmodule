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

Describe 'Get-AdoTeamSettings' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $teamName = 'my-team-1'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When retrieving team settings successfully' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    backlogIteration      = @{
                        id   = '11111111-1111-1111-1111-111111111111'
                        name = 'Sprint 1'
                        path = 'Sprint 1'
                        url  = 'https://dev.azure.com/my-org/_apis/work/teamsettings/iterations/11111111-1111-1111-1111-111111111111'
                    }
                    backlogVisibilities   = @{
                        'Microsoft.EpicCategory'        = $true
                        'Microsoft.FeatureCategory'     = $true
                        'Microsoft.RequirementCategory' = $true
                    }
                    bugsBehavior          = 'asRequirements'
                    defaultIteration      = @{
                        id   = '22222222-2222-2222-2222-222222222222'
                        name = 'Current Sprint'
                        path = 'Current Sprint'
                        url  = 'https://dev.azure.com/my-org/_apis/work/teamsettings/iterations/22222222-2222-2222-2222-222222222222'
                    }
                    defaultIterationMacro = '@currentIteration'
                    workingDays           = @('monday', 'tuesday', 'wednesday', 'thursday', 'friday')
                    url                   = 'https://dev.azure.com/my-org/my-project-1/my-team-1/_apis/work/teamsettings'
                }
            }
        }

        It 'Should retrieve team settings successfully' {
            # Act
            $result = Get-AdoTeamSettings -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.bugsBehavior | Should -Be 'asRequirements'
            $result.workingDays | Should -HaveCount 5
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/work/teamsettings" -and
                $Uri -match $teamName -and
                $Method -eq 'GET'
            }
        }

        It 'Should use correct API version' {
            # Act
            Get-AdoTeamSettings -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName -Version '7.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should accept team name from pipeline' {
            # Act
            $result = $teamName | Get-AdoTeamSettings -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should accept multiple team names from pipeline' {
            # Act
            $result = @('my-team-1', 'my-team-2') | Get-AdoTeamSettings -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with default value' {
            $command = Get-Command Get-AdoTeamSettings
            $parameter = $command.Parameters['CollectionUri']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
        }

        It 'Should have ProjectName parameter with ProjectId alias' {
            $command = Get-Command Get-AdoTeamSettings
            $parameter = $command.Parameters['ProjectName']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Name as mandatory parameter' {
            $command = Get-Command Get-AdoTeamSettings
            $parameter = $command.Parameters['Name']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have Name parameter with Team, TeamId, and TeamName aliases' {
            $command = Get-Command Get-AdoTeamSettings
            $parameter = $command.Parameters['Name']
            $parameter.Aliases | Should -Contain 'Team'
            $parameter.Aliases | Should -Contain 'TeamId'
            $parameter.Aliases | Should -Contain 'TeamName'
        }

        It 'Should have Version parameter with ApiVersion alias' {
            $command = Get-Command Get-AdoTeamSettings
            $parameter = $command.Parameters['Version']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Get-AdoTeamSettings
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'Error handling' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'VS403729: The team does not exist.'
                    typeKey = 'NotFoundException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Team not found')
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

        It 'Should warn when team does not exist' {
            # Act
            $result = Get-AdoTeamSettings -CollectionUri $collectionUri -ProjectName $projectName -Name 'NonExistentTeam' -WarningVariable warnings -WarningAction SilentlyContinue

            # Assert
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'does not exist'
        }

        It 'Should not throw on NotFoundException' {
            # Act & Assert
            { Get-AdoTeamSettings -CollectionUri $collectionUri -ProjectName $projectName -Name 'NonExistentTeam' -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should throw on other exceptions' {
            # Arrange
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Unexpected error'
            }

            # Act & Assert
            { Get-AdoTeamSettings -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName } | Should -Throw
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    backlogIteration      = @{
                        id   = '11111111-1111-1111-1111-111111111111'
                        name = 'Sprint 1'
                    }
                    backlogVisibilities   = @{
                        'Microsoft.EpicCategory' = $true
                    }
                    bugsBehavior          = 'asRequirements'
                    defaultIteration      = @{
                        id   = '22222222-2222-2222-2222-222222222222'
                        name = 'Current Sprint'
                    }
                    defaultIterationMacro = '@currentIteration'
                    workingDays           = @('monday', 'tuesday', 'wednesday')
                    url                   = 'https://dev.azure.com/my-org/_apis/work/teamsettings'
                }
            }
        }

        It 'Should return PSCustomObject with correct properties' {
            # Act
            $result = Get-AdoTeamSettings -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.projectName | Should -Be $projectName
            $result.collectionUri | Should -Be $collectionUri
        }

        It 'Should include all expected properties' {
            # Act
            $result = Get-AdoTeamSettings -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'backlogIteration'
            $result.PSObject.Properties.Name | Should -Contain 'backlogVisibilities'
            $result.PSObject.Properties.Name | Should -Contain 'bugsBehavior'
            $result.PSObject.Properties.Name | Should -Contain 'defaultIteration'
            $result.PSObject.Properties.Name | Should -Contain 'defaultIterationMacro'
            $result.PSObject.Properties.Name | Should -Contain 'workingDays'
            $result.PSObject.Properties.Name | Should -Contain 'url'
            $result.PSObject.Properties.Name | Should -Contain 'projectName'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should preserve all settings values from API response' {
            # Act
            $result = Get-AdoTeamSettings -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName

            # Assert
            $result.bugsBehavior | Should -Be 'asRequirements'
            $result.defaultIterationMacro | Should -Be '@currentIteration'
            $result.workingDays | Should -Contain 'monday'
            $result.workingDays | Should -Contain 'tuesday'
            $result.workingDays | Should -Contain 'wednesday'
        }
    }

    Context 'Integration scenarios' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    backlogIteration      = @{
                        id   = '11111111-1111-1111-1111-111111111111'
                        name = 'Sprint 1'
                    }
                    backlogVisibilities   = @{
                        'Microsoft.EpicCategory' = $true
                    }
                    bugsBehavior          = 'asRequirements'
                    defaultIteration      = @{
                        id   = '22222222-2222-2222-2222-222222222222'
                        name = 'Current Sprint'
                    }
                    defaultIterationMacro = '@currentIteration'
                    workingDays           = @('monday', 'tuesday', 'wednesday', 'thursday', 'friday')
                    url                   = 'https://dev.azure.com/my-org/_apis/work/teamsettings'
                }
            }
        }

        It 'Should work with WhatIf' {
            # Act
            Get-AdoTeamSettings -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should call Confirm-Default with correct parameters' {
            # Act
            Get-AdoTeamSettings -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName

            # Assert
            Should -Invoke Confirm-Default -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Defaults.CollectionUri -eq $collectionUri -and
                $Defaults.ProjectName -eq $projectName
            }
        }

        It 'Should work with different API versions' {
            # Act
            Get-AdoTeamSettings -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName -Version '7.2-preview.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should construct correct URI' {
            # Act
            Get-AdoTeamSettings -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/$projectName/$teamName/_apis/work/teamsettings"
            }
        }
    }
}
