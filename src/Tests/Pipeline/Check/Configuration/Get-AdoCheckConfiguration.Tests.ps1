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

Describe 'Get-AdoCheckConfiguration' {

    Context 'When retrieving check configurations by resource type and name' {
        BeforeAll {
            # Mock Get-AdoEnvironment for environment ID resolution
            Mock Get-AdoEnvironment -ModuleName $moduleName -MockWith {
                return @{
                    Id   = 123
                    Name = 'my-environment-tst'
                }
            }

            # Mock Invoke-AdoRestMethod for successful check configuration retrieval
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    count = 2
                    value = @(
                        @{
                            id        = 1
                            timeout   = 1440
                            type      = @{
                                name = 'Approval'
                            }
                            resource  = @{
                                id   = '123'
                                type = 'environment'
                                name = 'my-environment-tst'
                            }
                            createdBy = @{
                                id = 'user-id-1'
                            }
                            createdOn = '2024-01-01T00:00:00Z'
                        },
                        @{
                            id        = 2
                            timeout   = 720
                            type      = @{
                                name = 'BusinessHours'
                            }
                            resource  = @{
                                id   = '123'
                                type = 'environment'
                                name = 'my-environment-tst'
                            }
                            createdBy = @{
                                id = 'user-id-2'
                            }
                            createdOn = '2024-01-02T00:00:00Z'
                        }
                    )
                }
            }
        }

        It 'Should retrieve check configurations for a specific environment' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'
            $resourceType = 'environment'
            $resourceName = 'my-environment-tst'

            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -ResourceType $resourceType -ResourceName $resourceName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].id | Should -Be 1
            $result[0].type.name | Should -Be 'Approval'
            $result[0].project | Should -Be $projectName
            $result[0].collectionUri | Should -Be $collectionUri
            $result[1].id | Should -Be 2
            $result[1].type.name | Should -Be 'BusinessHours'

            # Verify Get-AdoEnvironment was called
            Should -Invoke Get-AdoEnvironment -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $CollectionUri -eq $collectionUri -and
                $ProjectName -eq $projectName -and
                $Name -eq $resourceName
            }

            # Verify Invoke-AdoRestMethod was called
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/$projectName/_apis/pipelines/checks/configurations" -and
                $Method -eq 'GET' -and
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should handle pipeline input for ResourceName' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'
            $resourceType = 'environment'
            $resourceNames = @('my-environment-tst', 'my-environment-dev')

            # Act
            $result = $resourceNames | Get-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -ResourceType $resourceType

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 4 # 2 configs per environment

            # Verify Get-AdoEnvironment was called twice
            Should -Invoke Get-AdoEnvironment -ModuleName $moduleName -Exactly 2
        }

        It 'Should use environment variables when CollectionUri and ProjectName are not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/envorg'
            $env:DefaultAdoProject = 'EnvProject'

            # Act
            $result = Get-AdoCheckConfiguration -ResourceType 'environment' -ResourceName 'my-environment-tst'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/envorg/EnvProject/_apis/pipelines/checks/configurations'
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }
    }

    Context 'When retrieving check configuration by ID' {
        BeforeAll {
            # Mock Invoke-AdoRestMethod for retrieving by ID
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id        = 1
                    timeout   = 1440
                    type      = @{
                        name = 'Approval'
                    }
                    resource  = @{
                        id   = '123'
                        type = 'environment'
                        name = 'my-environment-tst'
                    }
                    createdBy = @{
                        id = 'user-id-1'
                    }
                    createdOn = '2024-01-01T00:00:00Z'
                }
            }
        }

        It 'Should retrieve check configuration by ID' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'
            $configId = 1

            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id $configId

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            $result.type.name | Should -Be 'Approval'
            $result.project | Should -Be $projectName
            $result.collectionUri | Should -Be $collectionUri

            # Verify Invoke-AdoRestMethod was called with correct URI
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/$projectName/_apis/pipelines/checks/configurations/$configId" -and
                $Method -eq 'GET' -and
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should include settings when Expands parameter is set to settings' {
            # Arrange
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id        = 1
                    settings  = @{
                        definitionRef = @{
                            id   = 'def-id-1'
                            name = 'Approval'
                        }
                        approvers     = @(
                            @{
                                id = 'approver-id-1'
                            }
                        )
                    }
                    timeout   = 1440
                    type      = @{
                        name = 'Approval'
                    }
                    resource  = @{
                        id   = '123'
                        type = 'environment'
                    }
                    createdBy = @{
                        id = 'user-id-1'
                    }
                    createdOn = '2024-01-01T00:00:00Z'
                }
            }

            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/testorg' -ProjectName 'TestProject' -Id 1 -Expands 'settings'

            # Assert
            $result.settings | Should -Not -BeNullOrEmpty
            $result.settings.definitionRef.name | Should -Be 'Approval'
            $result.settings.approvers.Count | Should -Be 1
        }
    }

    Context 'When filtering by DefinitionType' {
        BeforeAll {
            # Mock Resolve-AdoCheckConfigDefinitionRef
            Mock Resolve-AdoCheckConfigDefinitionRef -ModuleName $moduleName -MockWith {
                param($Name)
                switch ($Name) {
                    'approval' {
                        return @{ id = 'def-id-approval'; name = 'Approval' }
                    }
                    'preCheckApproval' {
                        return @{ id = 'def-id-precheck'; name = 'PreCheckApproval' }
                    }
                    'businessHours' {
                        return @{ id = 'def-id-businesshours'; name = 'BusinessHours' }
                    }
                }
            }

            # Mock Get-AdoEnvironment
            Mock Get-AdoEnvironment -ModuleName $moduleName -MockWith {
                return @{ Id = 123; Name = 'my-environment-tst' }
            }

            # Mock Invoke-AdoRestMethod
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    count = 3
                    value = @(
                        @{
                            id        = 1
                            settings  = @{
                                definitionRef = @{
                                    id   = 'def-id-approval'
                                    name = 'Approval'
                                }
                            }
                            timeout   = 1440
                            type      = @{ name = 'Approval' }
                            resource  = @{ id = '123'; type = 'environment' }
                            createdBy = @{ id = 'user-id-1' }
                            createdOn = '2024-01-01T00:00:00Z'
                        },
                        @{
                            id        = 2
                            settings  = @{
                                definitionRef = @{
                                    id   = 'def-id-businesshours'
                                    name = 'BusinessHours'
                                }
                            }
                            timeout   = 720
                            type      = @{ name = 'BusinessHours' }
                            resource  = @{ id = '123'; type = 'environment' }
                            createdBy = @{ id = 'user-id-2' }
                            createdOn = '2024-01-02T00:00:00Z'
                        },
                        @{
                            id        = 3
                            settings  = @{
                                definitionRef = @{
                                    id   = 'def-id-precheck'
                                    name = 'PreCheckApproval'
                                }
                            }
                            timeout   = 600
                            type      = @{ name = 'PreCheckApproval' }
                            resource  = @{ id = '123'; type = 'environment' }
                            createdBy = @{ id = 'user-id-3' }
                            createdOn = '2024-01-03T00:00:00Z'
                        }
                    )
                }
            }
        }

        It 'Should filter check configurations by single DefinitionType' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'

            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -ResourceType 'environment' -ResourceName 'my-environment-tst' -DefinitionType 'approval'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].id | Should -Be 1
            $result[0].settings.definitionRef.name | Should -Be 'Approval'

            # Verify Resolve-AdoCheckConfigDefinitionRef was called
            Should -Invoke Resolve-AdoCheckConfigDefinitionRef -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Name -eq 'approval'
            }
        }

        It 'Should filter check configurations by multiple DefinitionTypes' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'

            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -ResourceType 'environment' -ResourceName 'my-environment-tst' -DefinitionType @('approval', 'preCheckApproval')

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].id | Should -Be 1
            $result[0].settings.definitionRef.name | Should -Be 'Approval'
            $result[1].id | Should -Be 3
            $result[1].settings.definitionRef.name | Should -Be 'PreCheckApproval'

            # Verify Resolve-AdoCheckConfigDefinitionRef was called twice
            Should -Invoke Resolve-AdoCheckConfigDefinitionRef -ModuleName $moduleName -Exactly 2
        }

        It 'Should automatically set Expands to settings when DefinitionType is provided' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'

            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -ResourceType 'environment' -ResourceName 'my-environment-tst' -DefinitionType 'approval'

            # Assert
            $result[0].settings | Should -Not -BeNullOrEmpty

            # Verify query parameters include expand
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like '*$expand=settings*'
            }
        }
    }

    Context 'When handling unsupported ResourceType' {
        BeforeAll {
            # No mocks needed - function should return early
        }

        It 'Should display warning and return early for unsupported ResourceType' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'

            # Act & Assert
            $result = Get-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -ResourceType 'endpoint' -ResourceName 'my-endpoint' -WarningVariable warnings -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match "ResourceType 'endpoint' is not supported yet"
        }
    }

    Context 'When environment is not found' {
        BeforeAll {
            # Mock Get-AdoEnvironment to return null
            Mock Get-AdoEnvironment -ModuleName $moduleName -MockWith {
                return $null
            }

            # Mock to verify it's not called
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Should not be called'
            }
        }

        It 'Should return early when environment is not found' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'

            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -ResourceType 'environment' -ResourceName 'non-existent-env'

            # Assert
            $result | Should -BeNullOrEmpty

            # Verify Invoke-AdoRestMethod was not called
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }

    Context 'Error handling' {
        BeforeAll {
            # Mock Get-AdoEnvironment
            Mock Get-AdoEnvironment -ModuleName $moduleName -MockWith {
                return @{ Id = 123; Name = 'my-environment-tst' }
            }
        }

        It 'Should handle NotFoundException gracefully when retrieving by ID' {
            # Arrange
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Check configuration with ID 999 does not exist.'
                    typeKey = 'NotFoundException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Configuration not found')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'NotFoundException',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/testorg' -ProjectName 'TestProject' -Id 999 -WarningVariable warnings -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'Check configuration with ID 999 does not exist'
        }

        It 'Should throw exception for other errors' {
            # Arrange
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Internal server error occurred.'
                    typeKey = 'InternalServerError'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Server error')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'InternalServerError',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert
            {
                Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/testorg' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'my-environment-tst'
            } | Should -Throw
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with ValidateScript attribute' {
            # Arrange
            $command = Get-Command Get-AdoCheckConfiguration

            # Act
            $param = $command.Parameters['CollectionUri']

            # Assert
            $param | Should -Not -BeNullOrEmpty
            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] } | Should -Not -BeNullOrEmpty
        }

        It 'Should have ResourceType as mandatory parameter in ConfigurationList parameter set' {
            # Arrange
            $command = Get-Command Get-AdoCheckConfiguration

            # Act
            $param = $command.Parameters['ResourceType']

            # Assert
            $param | Should -Not -BeNullOrEmpty
            $mandatoryAttribute = $param.Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute] -and
                $_.ParameterSetName -eq 'ConfigurationList' -and
                $_.Mandatory -eq $true
            }
            $mandatoryAttribute | Should -Not -BeNullOrEmpty
        }

        It 'Should have ResourceName as mandatory parameter in ConfigurationList parameter set' {
            # Arrange
            $command = Get-Command Get-AdoCheckConfiguration

            # Act
            $param = $command.Parameters['ResourceName']

            # Assert
            $param | Should -Not -BeNullOrEmpty
            $mandatoryAttribute = $param.Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute] -and
                $_.ParameterSetName -eq 'ConfigurationList' -and
                $_.Mandatory -eq $true
            }
            $mandatoryAttribute | Should -Not -BeNullOrEmpty
        }

        It 'Should have Id as mandatory parameter in ConfigurationById parameter set' {
            # Arrange
            $command = Get-Command Get-AdoCheckConfiguration

            # Act
            $param = $command.Parameters['Id']

            # Assert
            $param | Should -Not -BeNullOrEmpty
            $mandatoryAttribute = $param.Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute] -and
                $_.ParameterSetName -eq 'ConfigurationById' -and
                $_.Mandatory -eq $true
            }
            $mandatoryAttribute | Should -Not -BeNullOrEmpty
        }

        It 'Should have ResourceType parameter with ValidateSet attribute' {
            # Arrange
            $command = Get-Command Get-AdoCheckConfiguration

            # Act
            $param = $command.Parameters['ResourceType']
            $validateSet = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'endpoint'
            $validateSet.ValidValues | Should -Contain 'environment'
            $validateSet.ValidValues | Should -Contain 'variablegroup'
            $validateSet.ValidValues | Should -Contain 'repository'
        }

        It 'Should have DefinitionType parameter with ValidateSet attribute' {
            # Arrange
            $command = Get-Command Get-AdoCheckConfiguration

            # Act
            $param = $command.Parameters['DefinitionType']
            $validateSet = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'approval'
            $validateSet.ValidValues | Should -Contain 'preCheckApproval'
            $validateSet.ValidValues | Should -Contain 'postCheckApproval'
            $validateSet.ValidValues | Should -Contain 'branchControl'
            $validateSet.ValidValues | Should -Contain 'businessHours'
        }

        It 'Should have Expands parameter with ValidateSet attribute and default value of none' {
            # Arrange
            $command = Get-Command Get-AdoCheckConfiguration

            # Act
            $param = $command.Parameters['Expands']
            $validateSet = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'none'
            $validateSet.ValidValues | Should -Contain 'settings'
        }

        It 'Should have Version parameter with ValidateSet attribute' {
            # Arrange
            $command = Get-Command Get-AdoCheckConfiguration

            # Act
            $param = $command.Parameters['Version']
            $validateSet = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain '7.1-preview.1'
            $validateSet.ValidValues | Should -Contain '7.2-preview.1'
        }

        It 'Should support pipeline input for ResourceName' {
            # Arrange
            $command = Get-Command Get-AdoCheckConfiguration

            # Act
            $param = $command.Parameters['ResourceName']
            $pipelineAttribute = $param.Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute] -and
                $_.ValueFromPipeline -eq $true
            }

            # Assert
            $pipelineAttribute | Should -Not -BeNullOrEmpty
        }

        It 'Should support ShouldProcess' {
            # Arrange
            $command = Get-Command Get-AdoCheckConfiguration

            # Act
            $supportsShouldProcess = $command.Parameters.ContainsKey('WhatIf') -and $command.Parameters.ContainsKey('Confirm')

            # Assert
            $supportsShouldProcess | Should -Be $true
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Get-AdoEnvironment -ModuleName $moduleName -MockWith {
                return @{ Id = 123; Name = 'my-environment-tst' }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    count = 1
                    value = @(
                        @{
                            id        = 1
                            settings  = @{
                                definitionRef = @{ id = 'def-id'; name = 'Approval' }
                            }
                            timeout   = 1440
                            type      = @{ name = 'Approval' }
                            resource  = @{ id = '123'; type = 'environment'; name = 'my-environment-tst' }
                            createdBy = @{ id = 'user-id-1' }
                            createdOn = '2024-01-01T00:00:00Z'
                        }
                    )
                }
            }
        }

        It 'Should return objects with expected properties' {
            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/testorg' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'my-environment-tst' -Expands 'settings'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result[0].PSObject.Properties.Name | Should -Contain 'id'
            $result[0].PSObject.Properties.Name | Should -Contain 'settings'
            $result[0].PSObject.Properties.Name | Should -Contain 'timeout'
            $result[0].PSObject.Properties.Name | Should -Contain 'type'
            $result[0].PSObject.Properties.Name | Should -Contain 'resource'
            $result[0].PSObject.Properties.Name | Should -Contain 'createdBy'
            $result[0].PSObject.Properties.Name | Should -Contain 'createdOn'
            $result[0].PSObject.Properties.Name | Should -Contain 'project'
            $result[0].PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should return PSCustomObject type' {
            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/testorg' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'my-environment-tst'

            # Assert
            $result[0] | Should -BeOfType [PSCustomObject]
        }

        It 'Should not include settings property when Expands is none' {
            # Arrange
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    count = 1
                    value = @(
                        @{
                            id        = 1
                            timeout   = 1440
                            type      = @{ name = 'Approval' }
                            resource  = @{ id = '123'; type = 'environment' }
                            createdBy = @{ id = 'user-id-1' }
                            createdOn = '2024-01-01T00:00:00Z'
                        }
                    )
                }
            }

            # Act
            $result = Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/testorg' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'my-environment-tst' -Expands 'none'

            # Assert
            $result[0].PSObject.Properties.Name | Should -Not -Contain 'settings'
        }
    }

    Context 'WhatIf support' {
        BeforeAll {
            Mock Get-AdoEnvironment -ModuleName $moduleName -MockWith {
                return @{ Id = 123; Name = 'my-environment-tst' }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Should not be called in WhatIf mode'
            }
        }

        It 'Should not call Invoke-AdoRestMethod when WhatIf is specified' {
            # Act
            Get-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/testorg' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'my-environment-tst' -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }
}
