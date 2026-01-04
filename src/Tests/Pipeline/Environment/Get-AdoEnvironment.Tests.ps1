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

Describe 'Get-AdoEnvironment' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $environmentName = 'my-environment-tst'
        $environmentId = 123

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When retrieving all environments' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{
                            id             = 123
                            name           = 'my-environment-tst'
                            createdBy      = @{ id = '11111111-1111-1111-1111-111111111111' }
                            createdOn      = '2024-01-01T00:00:00Z'
                            lastModifiedBy = @{ id = '11111111-1111-1111-1111-111111111111' }
                            lastModifiedOn = '2024-01-01T00:00:00Z'
                        },
                        @{
                            id             = 124
                            name           = 'my-environment-dev'
                            createdBy      = @{ id = '22222222-2222-2222-2222-222222222222' }
                            createdOn      = '2024-01-02T00:00:00Z'
                            lastModifiedBy = @{ id = '22222222-2222-2222-2222-222222222222' }
                            lastModifiedOn = '2024-01-02T00:00:00Z'
                        }
                    )
                }
            }
        }

        It 'Should retrieve all environments when no parameters are specified' {
            # Act
            $result = Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].name | Should -Be 'my-environment-tst'
            $result[1].name | Should -Be 'my-environment-dev'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/pipelines/environments`$" -and
                $Method -eq 'GET'
            }
        }

        It 'Should add collectionUri and projectName properties to each environment' {
            # Act
            $result = Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result[0].collectionUri | Should -Be $collectionUri
            $result[0].projectName | Should -Be $projectName
            $result[1].collectionUri | Should -Be $collectionUri
            $result[1].projectName | Should -Be $projectName
        }

        It 'Should use Top parameter for pagination' {
            # Act
            Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Top 5

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match '\$top=5'
            }
        }

        It 'Should use ContinuationToken parameter for pagination' {
            # Act
            Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -ContinuationToken 'token123'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match 'continuationToken=token123'
            }
        }
    }

    Context 'When retrieving environments by name' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{
                            id             = 123
                            name           = 'my-environment-tst'
                            createdBy      = @{ id = '11111111-1111-1111-1111-111111111111' }
                            createdOn      = '2024-01-01T00:00:00Z'
                            lastModifiedBy = @{ id = '11111111-1111-1111-1111-111111111111' }
                            lastModifiedOn = '2024-01-01T00:00:00Z'
                        }
                    )
                }
            }
        }

        It 'Should retrieve environment by exact name' {
            # Act
            $result = Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Name 'my-environment-tst'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'my-environment-tst'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match 'name=my-environment-tst' -and
                $Method -eq 'GET'
            }
        }

        It 'Should retrieve environment by wildcard name' {
            # Act
            $result = Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Name '*environment*'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match 'name=\*environment\*'
            }
        }
    }

    Context 'When retrieving environment by ID' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id             = 123
                    name           = 'my-environment-tst'
                    createdBy      = @{ id = '11111111-1111-1111-1111-111111111111' }
                    createdOn      = '2024-01-01T00:00:00Z'
                    lastModifiedBy = @{ id = '11111111-1111-1111-1111-111111111111' }
                    lastModifiedOn = '2024-01-01T00:00:00Z'
                }
            }
        }

        It 'Should retrieve specific environment by ID' {
            # Act
            $result = Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id 123

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 123
            $result.name | Should -Be 'my-environment-tst'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/pipelines/environments/123`$" -and
                $Method -eq 'GET'
            }
        }

        It 'Should support pipeline input of ID' {
            # Act
            $result = 123 | Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 123
        }

        It 'Should use Expands parameter when specified' {
            # Act
            Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id 123 -Expands 'resourceReferences' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match 'expands=resourceReferences'
            }
        }

        It 'Should include expands parameter even when set to none' {
            # Act
            Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id 123 -Expands 'none' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match 'expands=none'
            }
        }
    }

    Context 'When retrieving environment with resourceReferences expand' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id             = 123
                    name           = 'my-environment-tst'
                    resources      = @(
                        @{
                            id   = 1
                            type = 'virtualMachine'
                            name = 'vm-001'
                        }
                    )
                    createdBy      = @{ id = '11111111-1111-1111-1111-111111111111' }
                    createdOn      = '2024-01-01T00:00:00Z'
                    lastModifiedBy = @{ id = '11111111-1111-1111-1111-111111111111' }
                    lastModifiedOn = '2024-01-01T00:00:00Z'
                }
            }
        }

        It 'Should include resources property when Expands is resourceReferences' {
            # Act
            $result = Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id 123 -Expands 'resourceReferences'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain 'resources'
            $result.resources | Should -Not -BeNullOrEmpty
        }

        It 'Should not include resources property when Expands is none' {
            # Arrange
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id             = 123
                    name           = 'my-environment-tst'
                    createdBy      = @{ id = '11111111-1111-1111-1111-111111111111' }
                    createdOn      = '2024-01-01T00:00:00Z'
                    lastModifiedBy = @{ id = '11111111-1111-1111-1111-111111111111' }
                    lastModifiedOn = '2024-01-01T00:00:00Z'
                }
            }

            # Act
            $result = Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id 123 -Expands 'none'

            # Assert
            $result.PSObject.Properties.Name | Should -Not -Contain 'resources'
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

        It 'Should write warning when environment is not found by ID' {
            # Act
            $result = Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id 999 -WarningAction SilentlyContinue -WarningVariable warning

            # Assert
            $result | Should -BeNullOrEmpty
            $warning | Should -Not -BeNullOrEmpty
            $warning | Should -Match 'Environment with ID 999 does not exist'
        }

        It 'Should not throw exception when environment is not found' {
            # Act & Assert
            { Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id 999 -WarningAction SilentlyContinue } | Should -Not -Throw
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
            { Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName } | Should -Throw -ExpectedMessage '*API connection failed*'
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with ValidateScript attribute' {
            # Arrange
            $command = Get-Command Get-AdoEnvironment
            $param = $command.Parameters['CollectionUri']
            $validateScript = $param.Attributes | Where-Object { $_ -is [ValidateScript] }

            # Assert
            $validateScript | Should -Not -BeNullOrEmpty
        }

        It 'Should have ProjectName parameter with alias ProjectId' {
            # Arrange
            $command = Get-Command Get-AdoEnvironment
            $param = $command.Parameters['ProjectName']

            # Assert
            $param.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Name parameter in ListEnvironments parameter set' {
            # Arrange
            $command = Get-Command Get-AdoEnvironment
            $param = $command.Parameters['Name']
            $paramAttr = $param.Attributes | Where-Object {
                $_ -is [Parameter] -and $_.ParameterSetName -eq 'ListEnvironments'
            }

            # Assert
            $paramAttr | Should -Not -BeNullOrEmpty
        }

        It 'Should have Id parameter in ByEnvironmentId parameter set' {
            # Arrange
            $command = Get-Command Get-AdoEnvironment
            $param = $command.Parameters['Id']
            $paramAttr = $param.Attributes | Where-Object {
                $_ -is [Parameter] -and $_.ParameterSetName -eq 'ByEnvironmentId'
            }

            # Assert
            $paramAttr | Should -Not -BeNullOrEmpty
        }

        It 'Should have Expands parameter with ValidateSet attribute' {
            # Arrange
            $command = Get-Command Get-AdoEnvironment
            $param = $command.Parameters['Expands']
            $validateSet = $param.Attributes | Where-Object { $_ -is [ValidateSet] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'none'
            $validateSet.ValidValues | Should -Contain 'resourceReferences'
        }

        It 'Should have Version parameter with ValidateSet attribute' {
            # Arrange
            $command = Get-Command Get-AdoEnvironment
            $param = $command.Parameters['Version']
            $validateSet = $param.Attributes | Where-Object { $_ -is [ValidateSet] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain '7.2-preview.1'
        }

        It 'Should support ShouldProcess (WhatIf and Confirm parameters)' {
            # Arrange
            $command = Get-Command Get-AdoEnvironment

            # Assert
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'ShouldProcess support' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{
                            id             = 123
                            name           = 'my-environment-tst'
                            createdBy      = @{ id = '11111111-1111-1111-1111-111111111111' }
                            createdOn      = '2024-01-01T00:00:00Z'
                            lastModifiedBy = @{ id = '11111111-1111-1111-1111-111111111111' }
                            lastModifiedOn = '2024-01-01T00:00:00Z'
                        }
                    )
                }
            }
        }

        It 'Should not call API when WhatIf is specified' {
            # Act
            Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should call API when Confirm is false' {
            # Act
            Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{
                            id             = 123
                            name           = 'my-environment-tst'
                            createdBy      = @{ id = '11111111-1111-1111-1111-111111111111' }
                            createdOn      = '2024-01-01T00:00:00Z'
                            lastModifiedBy = @{ id = '11111111-1111-1111-1111-111111111111' }
                            lastModifiedOn = '2024-01-01T00:00:00Z'
                        }
                    )
                }
            }
        }

        It 'Should return PSCustomObject with expected properties' {
            # Act
            $result = Get-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName

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
