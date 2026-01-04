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

Describe 'Set-AdoTeam' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $teamId = '11111111-1111-1111-1111-111111111111'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When updating individual properties' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'
                $script:teamId = '11111111-1111-1111-1111-111111111111'

                return @{
                    id          = $script:teamId
                    name        = if ($Body.name) { $Body.name } else { 'existing-team' }
                    description = if ($Body.description) { $Body.description } else { 'Existing description' }
                    url         = "$script:collectionUri/_apis/projects/$script:projectName/teams/$script:teamId"
                    identityUrl = "$script:collectionUri/_apis/Identities/$script:teamId"
                    projectId   = '22222222-2222-2222-2222-222222222222'
                    projectName = $script:projectName
                }
            }
        }

        It 'Should update team <Property>' -ForEach @(
            @{ Property = 'Name'; ParameterValue = 'updated-team'; BodyProperty = 'name' }
            @{ Property = 'Description'; ParameterValue = 'Updated description'; BodyProperty = 'description' }
        ) {
            # Arrange & Act
            $params = @{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                Id            = $teamId
                $Property     = $ParameterValue
                Confirm       = $false
            }
            $result = Set-AdoTeam @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.collectionUri | Should -Be $collectionUri
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/projects/$projectName/teams/$teamId" -and
                $Method -eq 'PATCH'
            }
        }

        It 'Should update multiple properties together' {
            # Act
            $result = Set-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Id $teamId -Name 'updated-team' -Description 'Updated description' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Body.name -eq 'updated-team' -and
                $Body.description -eq 'Updated description'
            }
        }

        It 'Should use correct API version' {
            # Act
            Set-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Id $teamId -Name 'updated' -Version '7.1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }
    }

    Context 'When updating multiple teams' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri, $Body)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'

                # Extract team ID from URI
                $teamIdFromUri = $Uri -replace '.*/teams/([^/]+).*', '$1'

                return @{
                    id          = $teamIdFromUri
                    name        = if ($Body.name) { $Body.name } else { "team-$teamIdFromUri" }
                    description = if ($Body.description) { $Body.description } else { 'Updated' }
                    url         = "$script:collectionUri/_apis/projects/$script:projectName/teams/$teamIdFromUri"
                    identityUrl = "$script:collectionUri/_apis/Identities/$teamIdFromUri"
                    projectId   = '22222222-2222-2222-2222-222222222222'
                    projectName = $script:projectName
                }
            }
        }

        It 'Should update multiple teams from pipeline' {
            # Act
            $result = @('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333') | Set-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name 'updated-team' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body, $Uri)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'
                $teamIdFromUri = $Uri -replace '.*/teams/([^/]+).*', '$1'

                return @{
                    id          = $teamIdFromUri
                    name        = if ($Body.name) { $Body.name } else { 'team-name' }
                    description = if ($Body.description) { $Body.description } else { 'Team description' }
                    url         = "$script:collectionUri/_apis/projects/$script:projectName/teams/$teamIdFromUri"
                    identityUrl = "$script:collectionUri/_apis/Identities/$teamIdFromUri"
                    projectId   = '22222222-2222-2222-2222-222222222222'
                    projectName = $script:projectName
                }
            }
        }

        It 'Should accept team ID from pipeline' {
            # Act
            $result = $teamId | Set-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Name 'updated-team' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should accept team properties from pipeline object' {
            # Arrange
            $pipelineObject = [PSCustomObject]@{
                Id          = $teamId
                Name        = 'updated-team'
                Description = 'Updated from pipeline'
            }

            # Act
            $result = $pipelineObject | Set-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Body.name -eq 'updated-team' -and
                $Body.description -eq 'Updated from pipeline'
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with default value' {
            $command = Get-Command Set-AdoTeam
            $parameter = $command.Parameters['CollectionUri']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
        }

        It 'Should have ProjectName parameter with ProjectId alias' {
            $command = Get-Command Set-AdoTeam
            $parameter = $command.Parameters['ProjectName']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Id as mandatory parameter' {
            $command = Get-Command Set-AdoTeam
            $parameter = $command.Parameters['Id']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes.Mandatory | Should -Contain $true
            $parameter.Aliases | Should -Contain 'TeamId'
        }

        It 'Should have Name parameter with TeamName alias' {
            $command = Get-Command Set-AdoTeam
            $parameter = $command.Parameters['Name']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
            $parameter.Aliases | Should -Contain 'TeamName'
        }

        It 'Should have Description parameter' {
            $command = Get-Command Set-AdoTeam
            $parameter = $command.Parameters['Description']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
        }

        It 'Should have Version parameter with ApiVersion alias' {
            $command = Get-Command Set-AdoTeam
            $parameter = $command.Parameters['Version']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Set-AdoTeam
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should have ConfirmImpact set to High' {
            $command = Get-Command Set-AdoTeam
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
            $result = Set-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Id 'non-existent' -Name 'updated' -WarningVariable warnings -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'does not exist'
        }

        It 'Should not throw on NotFoundException' {
            # Act & Assert
            { Set-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Id 'non-existent' -Name 'updated' -WarningAction SilentlyContinue -Confirm:$false } | Should -Not -Throw
        }

        It 'Should throw on other exceptions' {
            # Arrange
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Unexpected error'
            }

            # Act & Assert
            { Set-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Id $teamId -Name 'updated' -Confirm:$false } | Should -Throw
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                $script:collectionUri = 'https://dev.azure.com/my-org'
                $script:projectName = 'my-project-1'
                $script:teamId = '11111111-1111-1111-1111-111111111111'

                return @{
                    id          = $script:teamId
                    name        = if ($Body.name) { $Body.name } else { 'existing-team' }
                    description = if ($Body.description) { $Body.description } else { 'Existing description' }
                    url         = "$script:collectionUri/_apis/projects/$script:projectName/teams/$script:teamId"
                    identityUrl = "$script:collectionUri/_apis/Identities/$script:teamId"
                    projectId   = '22222222-2222-2222-2222-222222222222'
                    projectName = $script:projectName
                }
            }
        }

        It 'Should return PSCustomObject with correct properties' {
            # Act
            $result = Set-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Id $teamId -Name 'updated-team' -Confirm:$false

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.id | Should -Be $teamId
            $result.collectionUri | Should -Be $collectionUri
        }

        It 'Should include all expected properties' {
            # Act
            $result = Set-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Id $teamId -Name 'updated-team' -Description 'Updated' -Confirm:$false

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
                $script:teamId = '11111111-1111-1111-1111-111111111111'

                return @{
                    id          = $script:teamId
                    name        = if ($Body.name) { $Body.name } else { 'existing-team' }
                    description = if ($Body.description) { $Body.description } else { 'Existing description' }
                    url         = "$script:collectionUri/_apis/projects/$script:projectName/teams/$script:teamId"
                    identityUrl = "$script:collectionUri/_apis/Identities/$script:teamId"
                    projectId   = '22222222-2222-2222-2222-222222222222'
                    projectName = $script:projectName
                }
            }
        }

        It 'Should work with WhatIf' {
            # Act
            Set-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Id $teamId -Name 'updated' -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should call Confirm-Default with correct parameters' {
            # Act
            Set-AdoTeam -CollectionUri $collectionUri -ProjectName $projectName -Id $teamId -Name 'updated' -Confirm:$false

            # Assert
            Should -Invoke Confirm-Default -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Defaults.CollectionUri -eq $collectionUri -and
                $Defaults.ProjectName -eq $projectName
            }
        }
    }
}
