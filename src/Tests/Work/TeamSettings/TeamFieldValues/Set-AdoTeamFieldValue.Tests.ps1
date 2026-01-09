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

Describe 'Set-AdoTeamFieldValue' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $teamName = 'my-team-1'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When updating team field values for default team' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                return @{
                    field        = @{
                        referenceName = 'System.AreaPath'
                        url           = 'https://dev.azure.com/my-org/_apis/wit/fields/System.AreaPath'
                    }
                    defaultValue = $Body.defaultValue
                    values       = $Body.values
                }
            }
        }

        It 'Should update team field values successfully with correct output structure' {
            # Arrange
            $params = @{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                DefaultValue  = 'my-project-1'
                Values        = @(
                    @{
                        value           = 'my-project-1'
                        includeChildren = $true
                    }
                )
                Confirm       = $false
            }

            # Act
            $result = Set-AdoTeamFieldValue @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [PSCustomObject]
            $result.defaultValue | Should -Be 'my-project-1'
            $result.values | Should -HaveCount 1
            $result.projectName | Should -Be $projectName
            $result.collectionUri | Should -Be $collectionUri
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/work/teamsettings/teamfieldvalues" -and
                $Uri -notmatch "/$teamName/" -and
                $Method -eq 'PATCH'
            }
        }

        It 'Should use correct API version' {
            # Arrange
            $params = @{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                DefaultValue  = 'my-project-1'
                Values        = @(@{ value = 'my-project-1'; includeChildren = $true })
                Version       = '7.1'
                Confirm       = $false
            }

            # Act
            Set-AdoTeamFieldValue @params

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }
    }

    Context 'When updating team field values for specific team' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                return @{
                    field        = @{
                        referenceName = 'System.AreaPath'
                        url           = 'https://dev.azure.com/my-org/_apis/wit/fields/System.AreaPath'
                    }
                    defaultValue = $Body.defaultValue
                    values       = $Body.values
                }
            }
        }

        It 'Should update team field values for specific team' {
            # Arrange
            $params = @{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                TeamName      = $teamName
                DefaultValue  = 'my-project-1\my-team-1'
                Values        = @(
                    @{
                        value           = 'my-project-1\my-team-1'
                        includeChildren = $false
                    }
                )
                Confirm       = $false
            }

            # Act
            $result = Set-AdoTeamFieldValue @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.defaultValue | Should -Be 'my-project-1\my-team-1'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/work/teamsettings/teamfieldvalues" -and
                $Uri -match "/$teamName/" -and
                $Method -eq 'PATCH'
            }
        }

        It 'Should update with multiple area path values' {
            # Arrange
            $params = @{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                TeamName      = $teamName
                DefaultValue  = 'my-project-1\my-team-1'
                Values        = @(
                    @{
                        value           = 'my-project-1\my-team-1'
                        includeChildren = $false
                    }
                    @{
                        value           = 'my-project-1\my-team-2'
                        includeChildren = $false
                    }
                    @{
                        value           = 'my-project-1\Shared'
                        includeChildren = $true
                    }
                )
                Confirm       = $false
            }

            # Act
            $result = Set-AdoTeamFieldValue @params

            # Assert
            $result.values | Should -HaveCount 3
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Body.values.Count -eq 3
            }
        }
    }

    Context 'When updating team field values using pipeline input' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                return @{
                    field        = @{
                        referenceName = 'System.AreaPath'
                    }
                    defaultValue = $Body.defaultValue
                    values       = $Body.values
                }
            }
        }

        It 'Should accept values from pipeline object' {
            # Arrange
            $pipelineObject = [PSCustomObject]@{
                DefaultValue = 'my-project-1\my-team-1'
                Values       = @(
                    @{
                        value           = 'my-project-1\my-team-1'
                        includeChildren = $false
                    }
                )
            }

            # Act
            $result = $pipelineObject | Set-AdoTeamFieldValue -CollectionUri $collectionUri -ProjectName $projectName -TeamName $teamName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'Input validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    field        = @{ referenceName = 'System.AreaPath' }
                    defaultValue = 'my-project-1'
                    values       = @()
                }
            }
        }

        It 'Should throw when value property is empty' {
            # Arrange
            $params = @{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                DefaultValue  = 'my-project-1'
                Values        = @(
                    @{
                        value           = ''
                        includeChildren = $true
                    }
                )
                Confirm       = $false
            }

            # Act & Assert
            { Set-AdoTeamFieldValue @params } | Should -Throw "*value*required*"
        }

        It 'Should throw when includeChildren is not boolean' {
            # Arrange
            $params = @{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                DefaultValue  = 'my-project-1'
                Values        = @(
                    @{
                        value           = 'my-project-1'
                        includeChildren = 'not-a-bool'
                    }
                )
                Confirm       = $false
            }

            # Act & Assert
            { Set-AdoTeamFieldValue @params } | Should -Throw "*includeChildren*bool*"
        }

        It 'Should throw when includeChildren is null' {
            # Arrange
            $params = @{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                DefaultValue  = 'my-project-1'
                Values        = @(
                    @{
                        value           = 'my-project-1'
                        includeChildren = $null
                    }
                )
                Confirm       = $false
            }

            # Act & Assert
            { Set-AdoTeamFieldValue @params } | Should -Throw "*includeChildren*"
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
            # Arrange
            $params = @{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                TeamName      = 'NonExistentTeam'
                DefaultValue  = 'my-project-1'
                Values        = @(@{ value = 'my-project-1'; includeChildren = $true })
                Confirm       = $false
            }

            # Act
            $result = Set-AdoTeamFieldValue @params -WarningVariable warnings -WarningAction SilentlyContinue

            # Assert
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'does not exist'
        }

        It 'Should not throw on NotFoundException' {
            # Arrange
            $params = @{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                TeamName      = 'NonExistentTeam'
                DefaultValue  = 'my-project-1'
                Values        = @(@{ value = 'my-project-1'; includeChildren = $true })
                Confirm       = $false
            }

            # Act & Assert
            { Set-AdoTeamFieldValue @params -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should throw on other exceptions' {
            # Arrange
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Unexpected error'
            }

            $params = @{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                DefaultValue  = 'my-project-1'
                Values        = @(@{ value = 'my-project-1'; includeChildren = $true })
                Confirm       = $false
            }

            # Act & Assert
            { Set-AdoTeamFieldValue @params } | Should -Throw
        }
    }

    Context 'WhatIf support' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    field        = @{ referenceName = 'System.AreaPath' }
                    defaultValue = 'my-project-1'
                    values       = @()
                }
            }
        }

        It 'Should not call Invoke-AdoRestMethod when WhatIf is specified' {
            # Arrange
            $params = @{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                DefaultValue  = 'my-project-1'
                Values        = @(@{ value = 'my-project-1'; includeChildren = $true })
                WhatIf        = $true
            }

            # Act
            Set-AdoTeamFieldValue @params

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }
}
