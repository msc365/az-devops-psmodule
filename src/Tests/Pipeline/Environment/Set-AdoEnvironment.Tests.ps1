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

Describe 'Set-AdoEnvironment' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $environmentId = 123
        $environmentName = 'my-environment-updated'
        $environmentDescription = 'Updated environment description'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When updating environment successfully' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id             = 123
                    name           = 'my-environment-updated'
                    createdBy      = @{ id = '11111111-1111-1111-1111-111111111111' }
                    createdOn      = '2024-01-01T00:00:00Z'
                    lastModifiedBy = @{ id = '22222222-2222-2222-2222-222222222222' }
                    lastModifiedOn = '2024-01-05T00:00:00Z'
                }
            }
        }

        It 'Should update environment with all parameters' {
            # Act
            $result = Set-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id $environmentId -Name $environmentName -Description $environmentDescription -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 123
            $result.name | Should -Be 'my-environment-updated'
            $result.lastModifiedBy | Should -Be '22222222-2222-2222-2222-222222222222'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/pipelines/environments/123`$" -and
                $Method -eq 'PATCH'
            }
        }

        It 'Should update environment without description' {
            # Act
            $result = Set-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id $environmentId -Name $environmentName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'my-environment-updated'
        }

        It 'Should support pipeline input with all properties' {
            # Arrange
            $inputObject = [PSCustomObject]@{
                Id          = 123
                Name        = 'my-environment-updated'
                Description = 'Updated via pipeline'
            }

            # Act
            $result = $inputObject | Set-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 123
        }

        It 'Should add collectionUri and projectName properties to output' {
            # Act
            $result = Set-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id $environmentId -Name $environmentName -Confirm:$false

            # Assert
            $result.collectionUri | Should -Be $collectionUri
            $result.projectName | Should -Be $projectName
        }

        It 'Should include lastModifiedBy and lastModifiedOn in output' {
            # Act
            $result = Set-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id $environmentId -Name $environmentName -Confirm:$false

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'lastModifiedBy'
            $result.PSObject.Properties.Name | Should -Contain 'lastModifiedOn'
            $result.lastModifiedOn | Should -Be '2024-01-05T00:00:00Z'
        }
    }

    Context 'When updating multiple environments' {
        BeforeAll {
            $mockCallCount = 0
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $script:mockCallCount++
                return @{
                    id             = 100 + $script:mockCallCount
                    name           = "env-updated-$script:mockCallCount"
                    createdBy      = @{ id = '11111111-1111-1111-1111-111111111111' }
                    createdOn      = '2024-01-01T00:00:00Z'
                    lastModifiedBy = @{ id = '22222222-2222-2222-2222-222222222222' }
                    lastModifiedOn = '2024-01-05T00:00:00Z'
                }
            }
        }

        It 'Should update multiple environments via pipeline' {
            # Arrange
            $environments = @(
                [PSCustomObject]@{ Id = 1; Name = 'env-1-updated'; Description = 'Desc 1' }
                [PSCustomObject]@{ Id = 2; Name = 'env-2-updated'; Description = 'Desc 2' }
                [PSCustomObject]@{ Id = 3; Name = 'env-3-updated'; Description = 'Desc 3' }
            )

            # Act
            $result = $environments | Set-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
        }
    }

    Context 'When environment is not found' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Environment with ID 999 does not exist.'
                    typeKey = 'EnvironmentNotFoundException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Environment not found')
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

        It 'Should write warning when environment is not found' {
            # Act
            $result = Set-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id 999 -Name 'non-existent' -Confirm:$false -WarningAction SilentlyContinue -WarningVariable warning

            # Assert
            $result | Should -BeNullOrEmpty
            $warning | Should -Not -BeNullOrEmpty
            $warning | Should -Match 'Environment with ID 999 does not exist'
        }

        It 'Should not throw exception when environment is not found' {
            # Act & Assert
            { Set-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id 999 -Name 'non-existent' -Confirm:$false -WarningAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'When API call fails with unexpected error' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'API connection failed'
            }
        }

        It 'Should throw exception for unexpected errors' {
            # Act & Assert
            { Set-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id $environmentId -Name $environmentName -Confirm:$false } | Should -Throw -ExpectedMessage '*API connection failed*'
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with ValidateScript attribute' {
            # Arrange
            $command = Get-Command Set-AdoEnvironment
            $param = $command.Parameters['CollectionUri']
            $validateScript = $param.Attributes | Where-Object { $_ -is [ValidateScript] }

            # Assert
            $validateScript | Should -Not -BeNullOrEmpty
        }

        It 'Should have ProjectName parameter with alias ProjectId' {
            # Arrange
            $command = Get-Command Set-AdoEnvironment
            $param = $command.Parameters['ProjectName']

            # Assert
            $param.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Id as a mandatory parameter' {
            # Arrange
            $command = Get-Command Set-AdoEnvironment
            $param = $command.Parameters['Id']
            $mandatoryAttr = $param.Attributes | Where-Object {
                $_ -is [Parameter] -and $_.Mandatory
            }

            # Assert
            $mandatoryAttr | Should -Not -BeNullOrEmpty
        }

        It 'Should have Id parameter with alias EnvironmentId' {
            # Arrange
            $command = Get-Command Set-AdoEnvironment
            $param = $command.Parameters['Id']

            # Assert
            $param.Aliases | Should -Contain 'EnvironmentId'
        }

        It 'Should have Name as a mandatory parameter' {
            # Arrange
            $command = Get-Command Set-AdoEnvironment
            $param = $command.Parameters['Name']
            $mandatoryAttr = $param.Attributes | Where-Object {
                $_ -is [Parameter] -and $_.Mandatory
            }

            # Assert
            $mandatoryAttr | Should -Not -BeNullOrEmpty
        }

        It 'Should have Name parameter with alias EnvironmentName' {
            # Arrange
            $command = Get-Command Set-AdoEnvironment
            $param = $command.Parameters['Name']

            # Assert
            $param.Aliases | Should -Contain 'EnvironmentName'
        }

        It 'Should have Description parameter that accepts pipeline input' {
            # Arrange
            $command = Get-Command Set-AdoEnvironment
            $param = $command.Parameters['Description']
            $pipelineAttr = $param.Attributes | Where-Object {
                $_ -is [Parameter] -and $_.ValueFromPipelineByPropertyName
            }

            # Assert
            $pipelineAttr | Should -Not -BeNullOrEmpty
        }

        It 'Should have Version parameter with ValidateSet attribute' {
            # Arrange
            $command = Get-Command Set-AdoEnvironment
            $param = $command.Parameters['Version']
            $validateSet = $param.Attributes | Where-Object { $_ -is [ValidateSet] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain '7.2-preview.1'
        }

        It 'Should have Version parameter with alias ApiVersion' {
            # Arrange
            $command = Get-Command Set-AdoEnvironment
            $param = $command.Parameters['Version']

            # Assert
            $param.Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should support ShouldProcess (WhatIf and Confirm parameters)' {
            # Arrange
            $command = Get-Command Set-AdoEnvironment

            # Assert
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'ShouldProcess support' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id             = 123
                    name           = 'my-environment-updated'
                    createdBy      = @{ id = '11111111-1111-1111-1111-111111111111' }
                    createdOn      = '2024-01-01T00:00:00Z'
                    lastModifiedBy = @{ id = '22222222-2222-2222-2222-222222222222' }
                    lastModifiedOn = '2024-01-05T00:00:00Z'
                }
            }
        }

        It 'Should not call API when WhatIf is specified' {
            # Act
            Set-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id $environmentId -Name $environmentName -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should call API when Confirm is false' {
            # Act
            Set-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id $environmentId -Name $environmentName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id             = 123
                    name           = 'my-environment-updated'
                    createdBy      = @{ id = '11111111-1111-1111-1111-111111111111' }
                    createdOn      = '2024-01-01T00:00:00Z'
                    lastModifiedBy = @{ id = '22222222-2222-2222-2222-222222222222' }
                    lastModifiedOn = '2024-01-05T00:00:00Z'
                }
            }
        }

        It 'Should return PSCustomObject with expected properties' {
            # Act
            $result = Set-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id $environmentId -Name $environmentName -Confirm:$false

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.PSObject.Properties.Name | Should -Contain 'id'
            $result.PSObject.Properties.Name | Should -Contain 'name'
            $result.PSObject.Properties.Name | Should -Contain 'createdBy'
            $result.PSObject.Properties.Name | Should -Contain 'createdOn'
            $result.PSObject.Properties.Name | Should -Contain 'lastModifiedBy'
            $result.PSObject.Properties.Name | Should -Contain 'lastModifiedOn'
            $result.PSObject.Properties.Name | Should -Contain 'projectName'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }
    }
}
