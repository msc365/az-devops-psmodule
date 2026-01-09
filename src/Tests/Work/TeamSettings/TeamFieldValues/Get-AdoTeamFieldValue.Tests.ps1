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

Describe 'Get-AdoTeamFieldValue' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $teamName = 'my-team-1'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When retrieving team field values for default team' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    field        = @{
                        referenceName = 'System.AreaPath'
                        url           = 'https://dev.azure.com/my-org/_apis/wit/fields/System.AreaPath'
                    }
                    defaultValue = 'my-project-1'
                    values       = @(
                        @{
                            value           = 'my-project-1'
                            includeChildren = $true
                        }
                    )
                }
            }
        }

        It 'Should retrieve team field values successfully with correct output structure' {
            # Act
            $result = Get-AdoTeamFieldValue -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [PSCustomObject]
            $result.defaultValue | Should -Be 'my-project-1'
            $result.field.referenceName | Should -Be 'System.AreaPath'
            $result.values | Should -HaveCount 1
            $result.projectName | Should -Be $projectName
            $result.collectionUri | Should -Be $collectionUri
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/work/teamsettings/teamfieldvalues" -and
                $Uri -notmatch "/$teamName/" -and
                $Method -eq 'GET'
            }
        }

        It 'Should use correct API version' {
            # Act
            Get-AdoTeamFieldValue -CollectionUri $collectionUri -ProjectName $projectName -Version '7.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }
    }

    Context 'When retrieving team field values for specific team' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    field        = @{
                        referenceName = 'System.AreaPath'
                        url           = 'https://dev.azure.com/my-org/_apis/wit/fields/System.AreaPath'
                    }
                    defaultValue = 'my-project-1\my-team-1'
                    values       = @(
                        @{
                            value           = 'my-project-1\my-team-1'
                            includeChildren = $false
                        }
                        @{
                            value           = 'my-project-1\my-team-2'
                            includeChildren = $false
                        }
                    )
                }
            }
        }

        It 'Should retrieve team field values for specific team' {
            # Act
            $result = Get-AdoTeamFieldValue -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.defaultValue | Should -Be 'my-project-1\my-team-1'
            $result.values | Should -HaveCount 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/work/teamsettings/teamfieldvalues" -and
                $Uri -match "/$teamName/" -and
                $Method -eq 'GET'
            }
        }

        It 'Should accept team names from pipeline' {
            # Act
            $result = @(
                [PSCustomObject]@{ TeamName = 'my-team-1' }
                [PSCustomObject]@{ TeamName = 'my-team-2' }
            ) | Get-AdoTeamFieldValue -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }

    Context 'When retrieving team field values with multiple area paths' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    field        = @{
                        referenceName = 'System.AreaPath'
                        url           = 'https://dev.azure.com/my-org/_apis/wit/fields/System.AreaPath'
                    }
                    defaultValue = 'my-project-1\Team Area'
                    values       = @(
                        @{
                            value           = 'my-project-1\Team Area'
                            includeChildren = $false
                        }
                        @{
                            value           = 'my-project-1\Shared Area'
                            includeChildren = $true
                        }
                        @{
                            value           = 'my-project-1\Component A'
                            includeChildren = $false
                        }
                    )
                }
            }
        }

        It 'Should handle multiple area paths with includeChildren settings' {
            # Act
            $result = Get-AdoTeamFieldValue -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName

            # Assert
            $result.values | Should -HaveCount 3
            $result.values[0].value | Should -Be 'my-project-1\Team Area'
            $result.values[0].includeChildren | Should -Be $false
            $result.values[1].includeChildren | Should -Be $true
            $result.values[2].includeChildren | Should -Be $false
        }
    }

    Context 'Error handling' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'VS403729: Team field values do not exist.'
                    typeKey = 'NotFoundException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Team field values not found')
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

        It 'Should warn when team field values do not exist' {
            # Act
            $result = Get-AdoTeamFieldValue -CollectionUri $collectionUri -ProjectName $projectName -TeamName 'NonExistentTeam' -WarningVariable warnings -WarningAction SilentlyContinue

            # Assert
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'does not exist'
        }

        It 'Should not throw on NotFoundException' {
            # Act & Assert
            { Get-AdoTeamFieldValue -CollectionUri $collectionUri -ProjectName $projectName -TeamName 'NonExistentTeam' -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should throw on other exceptions' {
            # Arrange
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Unexpected error'
            }

            # Act & Assert
            { Get-AdoTeamFieldValue -CollectionUri $collectionUri -ProjectName $projectName } | Should -Throw
        }
    }

    Context 'WhatIf support' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    field        = @{
                        referenceName = 'System.AreaPath'
                    }
                    defaultValue = 'my-project-1'
                    values       = @()
                }
            }
        }

        It 'Should not call Invoke-AdoRestMethod when WhatIf is specified' {
            # Act
            Get-AdoTeamFieldValue -CollectionUri $collectionUri -ProjectName $projectName -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }
}
