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

Describe 'New-AdoTeam' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $teamName = 'new-team'
        $teamId = '11111111-1111-1111-1111-111111111111'
        $description = 'Test team description'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When creating a new team' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'

                return @{
                    id          = '11111111-1111-1111-1111-111111111111'
                    name        = $Body.name
                    description = $Body.description
                    url         = "$script:collectionUri/_apis/projects/$script:projectName/teams/11111111-1111-1111-1111-111111111111"
                    identityUrl = "$script:collectionUri/_apis/Identities/11111111-1111-1111-1111-111111111111"
                    projectId   = '22222222-2222-2222-2222-222222222222'
                    projectName = $script:projectName
                }
            }
        }

        It 'Should create a new team with required parameters' {
            # Act
            $result = New-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $teamName
            $result.id | Should -Not -BeNullOrEmpty
            $result.collectionUri | Should -Be $collectionUri
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/projects/$projectName/teams" -and
                $Method -eq 'POST'
            }
        }

        It 'Should create a team with name and description' {
            # Act
            $result = New-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName -Description $description -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.description | Should -Be $description
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Body.description -eq $description
            }
        }

        It 'Should use correct API version' {
            # Act
            $result = New-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName -Version '7.1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }
    }

    Context 'When team already exists' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = "The team with name 'new-team' already exists."
                    typeKey = 'TeamAlreadyExistsException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Team already exists')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'TeamAlreadyExists',
                    [System.Management.Automation.ErrorCategory]::ResourceExists,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            Mock Get-AdoTeam -ModuleName $moduleName -MockWith {
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'
                $script:teamName = 'new-team'

                return @{
                    id          = '11111111-1111-1111-1111-111111111111'
                    name        = $script:teamName
                    description = 'Existing team'
                    url         = "$script:collectionUri/_apis/projects/$script:projectName/teams/11111111-1111-1111-1111-111111111111"
                    identityUrl = "$script:collectionUri/_apis/Identities/11111111-1111-1111-1111-111111111111"
                    projectId   = '22222222-2222-2222-2222-222222222222'
                    projectName = $script:projectName
                }
            }
        }

        It 'Should warn and return existing team when TeamAlreadyExistsException occurs' {
            # Act
            $result = New-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName -WarningVariable warnings -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'already exists'
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $teamName
            Should -Invoke Get-AdoTeam -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'

                return @{
                    id          = [guid]::NewGuid().ToString()
                    name        = $Body.name
                    description = $Body.description
                    url         = "$script:collectionUri/_apis/projects/$script:projectName/teams/$([guid]::NewGuid())"
                    identityUrl = "$script:collectionUri/_apis/Identities/$([guid]::NewGuid())"
                    projectId   = '22222222-2222-2222-2222-222222222222'
                    projectName = $script:projectName
                }
            }
        }

        It 'Should accept team name from pipeline' {
            # Act
            $result = 'team-1' | New-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'team-1'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should process multiple team names from pipeline' {
            # Act
            $result = @('team-1', 'team-2', 'team-3') | New-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with default value' {
            $command = Get-Command New-AdoTeam
            $parameter = $command.Parameters['CollectionUri']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
        }

        It 'Should have ProjectName parameter with ProjectId alias' {
            $command = Get-Command New-AdoTeam
            $parameter = $command.Parameters['ProjectName']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Name as mandatory parameter' {
            $command = Get-Command New-AdoTeam
            $parameter = $command.Parameters['Name']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes.Mandatory | Should -Contain $true
            $parameter.Aliases | Should -Contain 'TeamName'
        }

        It 'Should have Description parameter' {
            $command = Get-Command New-AdoTeam
            $parameter = $command.Parameters['Description']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
        }

        It 'Should have Version parameter with ApiVersion alias' {
            $command = Get-Command New-AdoTeam
            $parameter = $command.Parameters['Version']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command New-AdoTeam
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should have ConfirmImpact set to High' {
            $command = Get-Command New-AdoTeam
            $confirmImpact = $command.ScriptBlock.Attributes |
                Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] } |
                Select-Object -ExpandProperty ConfirmImpact
            $confirmImpact | Should -Be 'High'
        }
    }

    Context 'Error handling' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Unexpected error creating team'
            }
        }

        It 'Should throw on unexpected errors' {
            # Act & Assert
            { New-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName -Confirm:$false } | Should -Throw
        }

        It 'Should handle invalid project name' {
            # Arrange
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'VS403729: The project does not exist.'
                    typeKey = 'ProjectDoesNotExistException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Project not found')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'NotFoundException',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert
            { New-AdoTeam -CollectionUri $collectionUri -ProjectName 'non-existent' -Name $teamName -Confirm:$false } | Should -Throw
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'

                return @{
                    id          = '11111111-1111-1111-1111-111111111111'
                    name        = $Body.name
                    description = $Body.description
                    url         = "$script:collectionUri/_apis/projects/$script:projectName/teams/11111111-1111-1111-1111-111111111111"
                    identityUrl = "$script:collectionUri/_apis/Identities/11111111-1111-1111-1111-111111111111"
                    projectId   = '22222222-2222-2222-2222-222222222222'
                    projectName = $script:projectName
                }
            }
        }

        It 'Should return PSCustomObject with correct properties' {
            # Act
            $result = New-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName -Confirm:$false

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.id | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $teamName
            $result.collectionUri | Should -Be $collectionUri
        }

        It 'Should include all expected properties' {
            # Act
            $result = New-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName -Description $description -Confirm:$false

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
                param($Body)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'

                return @{
                    id          = '11111111-1111-1111-1111-111111111111'
                    name        = $Body.name
                    description = $Body.description
                    url         = "$script:collectionUri/_apis/projects/$script:projectName/teams/11111111-1111-1111-1111-111111111111"
                    identityUrl = "$script:collectionUri/_apis/Identities/11111111-1111-1111-1111-111111111111"
                    projectId   = '22222222-2222-2222-2222-222222222222'
                    projectName = $script:projectName
                }
            }
        }

        It 'Should work with WhatIf' {
            # Act
            New-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should call Confirm-Default with correct parameters' {
            # Act
            New-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name $teamName -Confirm:$false

            # Assert
            Should -Invoke Confirm-Default -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Defaults.CollectionUri -eq $collectionUri
            }
        }
    }
}
