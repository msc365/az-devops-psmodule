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

Describe 'Get-AdoTeam' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $teamName = 'my-team'
        $teamId = '11111111-1111-1111-1111-111111111111'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When retrieving all teams' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{
                            id          = $teamId
                            name        = $teamName
                            description = 'Test team'
                            url         = "$collectionUri/_apis/projects/$projectName/teams/$teamId"
                            identityUrl = "$collectionUri/_apis/Identities/$teamId"
                            projectId   = '22222222-2222-2222-2222-222222222222'
                            projectName = $projectName
                        },
                        @{
                            id          = '33333333-3333-3333-3333-333333333333'
                            name        = 'another-team'
                            description = 'Another team'
                            url         = "$collectionUri/_apis/projects/$projectName/teams/33333333-3333-3333-3333-333333333333"
                            identityUrl = "$collectionUri/_apis/Identities/33333333-3333-3333-3333-333333333333"
                            projectId   = '22222222-2222-2222-2222-222222222222'
                            projectName = $projectName
                        }
                    )
                }
            }
        }

        It 'Should retrieve all teams when no name is specified' {
            # Arrange & Act
            $result = Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].name | Should -Be $teamName
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/projects/$projectName/teams`$" -and
                $Method -eq 'GET'
            }
        }

        It 'Should use Skip parameter for pagination' {
            # Act
            Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Skip 5

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match '\$skip=5'
            }
        }

        It 'Should use Top parameter for pagination' {
            # Act
            Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Top 10

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match '\$top=10'
            }
        }

        It 'Should use both Skip and Top parameters' {
            # Act
            Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Skip 5 -Top 10

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match '\$skip=5' -and $QueryParameters -match '\$top=10'
            }
        }

        It 'Should add collectionUri property to each team' {
            # Act
            $result = Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result[0].collectionUri | Should -Be $collectionUri
            $result[1].collectionUri | Should -Be $collectionUri
        }
    }

    Context 'When retrieving specific team by name or ID' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'
                $script:teamName = 'my-team'
                $script:teamId = '11111111-1111-1111-1111-111111111111'

                return @{
                    id          = $script:teamId
                    name        = $script:teamName
                    description = 'Test team'
                    url         = "$script:collectionUri/_apis/projects/$script:projectName/teams/$script:teamId"
                    identityUrl = "$script:collectionUri/_apis/Identities/$script:teamId"
                    projectId   = '22222222-2222-2222-2222-222222222222'
                    projectName = $script:projectName
                }
            }
        }

        It 'Should retrieve specific team by name' {
            # Act
            $result = Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $teamName
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/projects/$projectName/teams/$teamName" -and
                $Method -eq 'GET'
            }
        }

        It 'Should retrieve specific team by ID' {
            # Act
            $result = Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamId

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/projects/$projectName/teams/$teamId"
            }
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'

                if ($Uri -match 'team-1') {
                    return @{
                        id          = '11111111-1111-1111-1111-111111111111'
                        name        = 'team-1'
                        description = 'Team 1'
                        url         = "$script:collectionUri/_apis/projects/$script:projectName/teams/11111111-1111-1111-1111-111111111111"
                        identityUrl = "$script:collectionUri/_apis/Identities/11111111-1111-1111-1111-111111111111"
                        projectId   = '22222222-2222-2222-2222-222222222222'
                        projectName = $script:projectName
                    }
                } elseif ($Uri -match 'team-2') {
                    return @{
                        id          = '33333333-3333-3333-3333-333333333333'
                        name        = 'team-2'
                        description = 'Team 2'
                        url         = "$script:collectionUri/_apis/projects/$script:projectName/teams/33333333-3333-3333-3333-333333333333"
                        identityUrl = "$script:collectionUri/_apis/Identities/33333333-3333-3333-3333-333333333333"
                        projectId   = '22222222-2222-2222-2222-222222222222'
                        projectName = $script:projectName
                    }
                } else {
                    return @{
                        id          = '44444444-4444-4444-4444-444444444444'
                        name        = 'default-team'
                        description = 'Default team'
                        url         = "$script:collectionUri/_apis/projects/$script:projectName/teams/44444444-4444-4444-4444-444444444444"
                        identityUrl = "$script:collectionUri/_apis/Identities/44444444-4444-4444-4444-444444444444"
                        projectId   = '22222222-2222-2222-2222-222222222222'
                        projectName = $script:projectName
                    }
                }
            }
        }

        It 'Should accept team name from pipeline' {
            # Act
            $result = 'team-1' | Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'team-1'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should process multiple team names from pipeline' {
            # Act
            $result = @('team-1', 'team-2') | Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with default value' {
            $command = Get-Command Get-AdoTeam
            $parameter = $command.Parameters['CollectionUri']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
        }

        It 'Should have ProjectName parameter with ProjectId alias' {
            $command = Get-Command Get-AdoTeam
            $parameter = $command.Parameters['ProjectName']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Name parameter with multiple aliases' {
            $command = Get-Command Get-AdoTeam
            $parameter = $command.Parameters['Name']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'TeamName'
            $parameter.Aliases | Should -Contain 'Id'
            $parameter.Aliases | Should -Contain 'TeamId'
        }

        It 'Should have Skip parameter in ListTeams parameter set' {
            $command = Get-Command Get-AdoTeam
            $parameter = $command.Parameters['Skip']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'Int32'
        }

        It 'Should have Top parameter in ListTeams parameter set' {
            $command = Get-Command Get-AdoTeam
            $parameter = $command.Parameters['Top']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'Int32'
        }

        It 'Should have Version parameter with ApiVersion alias' {
            $command = Get-Command Get-AdoTeam
            $parameter = $command.Parameters['Version']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Get-AdoTeam
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
            # Act & Assert
            $result = Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name 'non-existent-team' -WarningVariable warnings -WarningAction SilentlyContinue

            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'does not exist'
        }

        It 'Should not throw on NotFoundException' {
            # Act & Assert
            { Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name 'non-existent-team' -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should throw on other exceptions' {
            # Arrange
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Unexpected error'
            }

            # Act & Assert
            { Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName } | Should -Throw
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id          = $teamId
                    name        = $teamName
                    description = 'Test team'
                    url         = "$collectionUri/_apis/projects/$projectName/teams/$teamId"
                    identityUrl = "$collectionUri/_apis/Identities/$teamId"
                    projectId   = '22222222-2222-2222-2222-222222222222'
                    projectName = $projectName
                }
            }
        }

        It 'Should return PSCustomObject with correct properties' {
            # Act
            $result = Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.id | Should -Be $teamId
            $result.name | Should -Be $teamName
            $result.collectionUri | Should -Be $collectionUri
        }

        It 'Should include all expected properties' {
            # Act
            $result = Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'id'
            $result.PSObject.Properties.Name | Should -Contain 'name'
            $result.PSObject.Properties.Name | Should -Contain 'description'
            $result.PSObject.Properties.Name | Should -Contain 'url'
            $result.PSObject.Properties.Name | Should -Contain 'identityUrl'
            $result.PSObject.Properties.Name | Should -Contain 'projectId'
            $result.PSObject.Properties.Name | Should -Contain 'projectName'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }
    }

    Context 'Integration scenarios' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id          = $teamId
                    name        = $teamName
                    description = 'Test team'
                    url         = "$collectionUri/_apis/projects/$projectName/teams/$teamId"
                    identityUrl = "$collectionUri/_apis/Identities/$teamId"
                    projectId   = '22222222-2222-2222-2222-222222222222'
                    projectName = $projectName
                }
            }
        }

        It 'Should work with WhatIf' {
            # Act
            Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should call Confirm-Default with correct parameters' {
            # Act
            Get-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName

            # Assert
            Should -Invoke Confirm-Default -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Defaults.CollectionUri -eq $collectionUri
            }
        }
    }
}
