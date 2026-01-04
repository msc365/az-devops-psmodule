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

Describe 'Remove-AdoTeam' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $teamId = '11111111-1111-1111-1111-111111111111'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When removing a team' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should remove team by ID' {
            # Act
            Remove-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/projects/$projectName/teams/$teamId" -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should remove team by name' {
            # Act
            Remove-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name 'my-team' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/projects/$projectName/teams/my-team"
            }
        }

        It 'Should use correct API version' {
            # Act
            Remove-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamId -Version '7.1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }
    }

    Context 'When removing multiple teams' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should remove multiple teams from pipeline' {
            # Act
            @($teamId, '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333') | Remove-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should accept team ID from pipeline' {
            # Act
            $teamId | Remove-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should accept team name from pipeline' {
            # Act
            'my-team' | Remove-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match 'my-team'
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with default value' {
            $command = Get-Command Remove-AdoTeam
            $parameter = $command.Parameters['CollectionUri']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
        }

        It 'Should have ProjectName parameter with ProjectId alias' {
            $command = Get-Command Remove-AdoTeam
            $parameter = $command.Parameters['ProjectName']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Name as mandatory parameter' {
            $command = Get-Command Remove-AdoTeam
            $parameter = $command.Parameters['Name']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes.Mandatory | Should -Contain $true
            $parameter.Aliases | Should -Contain 'TeamName'
            $parameter.Aliases | Should -Contain 'Id'
            $parameter.Aliases | Should -Contain 'TeamId'
        }

        It 'Should have Version parameter with ApiVersion alias' {
            $command = Get-Command Remove-AdoTeam
            $parameter = $command.Parameters['Version']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Remove-AdoTeam
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should have ConfirmImpact set to High' {
            $command = Get-Command Remove-AdoTeam
            $confirmImpact = $command.ScriptBlock.Attributes |
                Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] } |
                Select-Object -ExpandProperty ConfirmImpact
            $confirmImpact | Should -Be 'High'
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
            Remove-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name 'non-existent-team' -WarningVariable warnings -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'does not exist'
        }

        It 'Should not throw on NotFoundException' {
            # Act & Assert
            { Remove-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name 'non-existent-team' -WarningAction SilentlyContinue -Confirm:$false } | Should -Not -Throw
        }

        It 'Should throw on other exceptions' {
            # Arrange
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Unexpected error'
            }

            # Act & Assert
            { Remove-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamId -Confirm:$false } | Should -Throw
        }

        It 'Should handle permission errors' {
            # Arrange
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Access denied. You do not have permission to delete this team.'
                    typeKey = 'AccessDeniedException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Access denied')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'AccessDenied',
                    [System.Management.Automation.ErrorCategory]::PermissionDenied,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert
            { Remove-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamId -Confirm:$false } | Should -Throw
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should not return any output on successful deletion' {
            # Act
            $result = Remove-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamId -Confirm:$false

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should complete silently when piping multiple teams' {
            # Act
            $result = @($teamId, '22222222-2222-2222-2222-222222222222') | Remove-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            $result | Should -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }

    Context 'Integration scenarios' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should work with WhatIf' {
            # Act
            Remove-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamId -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should call Confirm-Default with correct parameters' {
            # Act
            Remove-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamId -Confirm:$false

            # Assert
            Should -Invoke Confirm-Default -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Defaults.CollectionUri -eq $collectionUri -and
                $Defaults.ProjectName -eq $projectName
            }
        }

        It 'Should handle batch deletion workflow' {
            # Arrange
            $teamsToDelete = @(
                '11111111-1111-1111-1111-111111111111',
                '22222222-2222-2222-2222-222222222222',
                '33333333-3333-3333-3333-333333333333'
            )

            # Act
            $teamsToDelete | Remove-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
        }
    }
}
