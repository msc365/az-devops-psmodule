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

Describe 'New-AdoEnvironment' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $environmentName = 'my-environment-tst'
        $environmentDescription = 'Test environment'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When creating a new environment successfully' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id        = 123
                    name      = 'my-environment-tst'
                    createdBy = @{ id = '11111111-1111-1111-1111-111111111111' }
                    createdOn = '2024-01-01T00:00:00Z'
                }
            }
        }

        It 'Should create new environment with all parameters' {
            # Act
            $result = New-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Name $environmentName -Description $environmentDescription -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 123
            $result.name | Should -Be 'my-environment-tst'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/pipelines/environments`$" -and
                $Method -eq 'POST'
            }
        }

        It 'Should create environment without description' {
            # Act
            $result = New-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Name $environmentName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'my-environment-tst'
        }

        It 'Should support pipeline input of Name' {
            # Act
            $result = $environmentName | New-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'my-environment-tst'
        }

        It 'Should support pipeline input of multiple environment names' {
            # Arrange
            $envNames = @('env-1', 'env-2', 'env-3')
            $mockCallCount = 0
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $script:mockCallCount++
                return @{
                    id        = 100 + $script:mockCallCount
                    name      = "env-$script:mockCallCount"
                    createdBy = @{ id = '11111111-1111-1111-1111-111111111111' }
                    createdOn = '2024-01-01T00:00:00Z'
                }
            }

            # Act
            $result = $envNames | New-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
        }

        It 'Should add collectionUri and projectName properties to output' {
            # Act
            $result = New-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Name $environmentName -Confirm:$false

            # Assert
            $result.collectionUri | Should -Be $collectionUri
            $result.projectName | Should -Be $projectName
        }
    }

    Context 'When environment already exists' {
        BeforeAll {
            # Mock for POST request that fails with EnvironmentExistsException
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Method)
                if ($Method -eq 'POST') {
                    $errorMessage = @{
                        message = "Environment 'my-environment-tst' already exists."
                        typeKey = 'EnvironmentExistsException'
                    } | ConvertTo-Json
                    $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                    $exception = [System.Exception]::new('Environment already exists')
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                        $exception,
                        'ConflictException',
                        [System.Management.Automation.ErrorCategory]::ResourceExists,
                        $null
                    )
                    $errorRecord.ErrorDetails = $errorDetails
                    throw $errorRecord
                } elseif ($Method -eq 'GET') {
                    return @{
                        value = @(
                            @{
                                id        = 123
                                name      = 'my-environment-tst'
                                createdBy = @{ id = '11111111-1111-1111-1111-111111111111' }
                                createdOn = '2024-01-01T00:00:00Z'
                            }
                        )
                    }
                }
            }
        }

        It 'Should write warning and retrieve existing environment' {
            # Act
            $result = New-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Name $environmentName -Confirm:$false -WarningAction SilentlyContinue -WarningVariable warning

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 123
            $result.name | Should -Be 'my-environment-tst'
            $warning | Should -Not -BeNullOrEmpty
            $warning | Should -Match 'already exists'

            # Verify both POST and GET were called
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }

        It 'Should call GET with name parameter when environment exists' {
            # Act
            New-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Name $environmentName -Confirm:$false -WarningAction SilentlyContinue

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -ParameterFilter {
                $Method -eq 'GET' -and $QueryParameters -match 'name=my-environment-tst'
            }
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
            { New-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Name $environmentName -Confirm:$false } | Should -Throw -ExpectedMessage '*API connection failed*'
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with ValidateScript attribute' {
            # Arrange
            $command = Get-Command New-AdoEnvironment
            $param = $command.Parameters['CollectionUri']
            $validateScript = $param.Attributes | Where-Object { $_ -is [ValidateScript] }

            # Assert
            $validateScript | Should -Not -BeNullOrEmpty
        }

        It 'Should have ProjectName parameter with alias ProjectId' {
            # Arrange
            $command = Get-Command New-AdoEnvironment
            $param = $command.Parameters['ProjectName']

            # Assert
            $param.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Name parameter that accepts pipeline input' {
            # Arrange
            $command = Get-Command New-AdoEnvironment
            $param = $command.Parameters['Name']
            $pipelineAttr = $param.Attributes | Where-Object {
                $_ -is [Parameter] -and $_.ValueFromPipeline
            }

            # Assert
            $pipelineAttr | Should -Not -BeNullOrEmpty
        }

        It 'Should have Version parameter with ValidateSet attribute' {
            # Arrange
            $command = Get-Command New-AdoEnvironment
            $param = $command.Parameters['Version']
            $validateSet = $param.Attributes | Where-Object { $_ -is [ValidateSet] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain '7.2-preview.1'
        }

        It 'Should have Version parameter with alias ApiVersion' {
            # Arrange
            $command = Get-Command New-AdoEnvironment
            $param = $command.Parameters['Version']

            # Assert
            $param.Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should support ShouldProcess (WhatIf and Confirm parameters)' {
            # Arrange
            $command = Get-Command New-AdoEnvironment

            # Assert
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'ShouldProcess support' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id        = 123
                    name      = 'my-environment-tst'
                    createdBy = @{ id = '11111111-1111-1111-1111-111111111111' }
                    createdOn = '2024-01-01T00:00:00Z'
                }
            }
        }

        It 'Should not call API when WhatIf is specified' {
            # Act
            New-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Name $environmentName -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should call API when Confirm is false' {
            # Act
            New-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Name $environmentName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id        = 123
                    name      = 'my-environment-tst'
                    createdBy = @{ id = '11111111-1111-1111-1111-111111111111' }
                    createdOn = '2024-01-01T00:00:00Z'
                }
            }
        }

        It 'Should return PSCustomObject with expected properties' {
            # Act
            $result = New-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Name $environmentName -Confirm:$false

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.PSObject.Properties.Name | Should -Contain 'id'
            $result.PSObject.Properties.Name | Should -Contain 'name'
            $result.PSObject.Properties.Name | Should -Contain 'createdBy'
            $result.PSObject.Properties.Name | Should -Contain 'createdOn'
            $result.PSObject.Properties.Name | Should -Contain 'projectName'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }
    }
}
