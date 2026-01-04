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

Describe 'New-AdoCheckConfiguration' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $definitionRefId = '8c6f20a7-a545-4486-9777-f762fafe0d4d'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When creating a new check configuration' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                return @{
                    id        = 1
                    settings  = $Body.settings
                    timeout   = $Body.timeout
                    type      = $Body.type
                    resource  = $Body.resource
                    createdBy = @{
                        id = 'user-id-1'
                    }
                    createdOn = '2024-01-01T00:00:00Z'
                }
            }
        }

        It 'Should create a new check configuration with valid JSON' {
            # Arrange
            $configuration = [PSCustomObject]@{
                settings = @{
                    approvers            = @(
                        @{ id = '11111111-1111-1111-1111-111111111111' }
                    )
                    executionOrder       = 'anyOrder'
                    minRequiredApprovers = 0
                    instructions         = 'Approval required'
                    blockedApprovers     = @()
                    definitionRef        = @{
                        id = $definitionRefId
                    }
                }
                timeout  = 1440
                type     = @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
                resource = @{
                    type = 'environment'
                    id   = 123
                }
            }

            # Act
            $result = New-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $configuration -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            $result.collectionUri | Should -Be $collectionUri
            $result.project | Should -Be $projectName
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match '_apis/pipelines/checks/configurations' -and
                $Method -eq 'POST'
            }
        }

        It 'Should validate GUID format in definitionRef.id' {
            # Arrange
            $configuration = [PSCustomObject]@{
                settings = @{
                    definitionRef = @{
                        id = $definitionRefId
                    }
                }
                timeout  = 1440
                type     = @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
                resource = @{
                    type = 'environment'
                    id   = 123
                }
            }

            # Act
            $result = New-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $configuration -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should use correct API version' {
            # Arrange
            $configuration = [PSCustomObject]@{
                settings = @{
                    definitionRef = @{
                        id = $definitionRefId
                    }
                }
                timeout  = 1440
                type     = @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
                resource = @{
                    type = 'environment'
                    id   = 123
                }
            }

            # Act
            New-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $configuration -Version '7.1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should include settings in output when present' {
            # Arrange
            $configuration = [PSCustomObject]@{
                settings = @{
                    definitionRef = @{
                        id = $definitionRefId
                    }
                    instructions  = 'Test instructions'
                }
                timeout  = 1440
                type     = @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
                resource = @{
                    type = 'environment'
                    id   = 123
                }
            }

            # Act
            $result = New-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $configuration -Confirm:$false

            # Assert
            $result.settings | Should -Not -BeNullOrEmpty
            $result.settings.instructions | Should -Be 'Test instructions'
        }
    }

    Context 'When check configuration already exists' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Method)
                if ($Method -eq 'POST') {
                    $errorMessage = @{
                        message = 'Check configuration already exists'
                        typeKey = 'CheckConfigurationAlreadyExistsException'
                    } | ConvertTo-Json
                    $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                    $exception = [System.Exception]::new('Already exists')
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                        $exception,
                        'AlreadyExists',
                        [System.Management.Automation.ErrorCategory]::ResourceExists,
                        $null
                    )
                    $errorRecord.ErrorDetails = $errorDetails
                    throw $errorRecord
                } else {
                    return @{
                        value = @(
                            @{
                                id        = 1
                                settings  = @{
                                    definitionRef = @{
                                        id = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                                    }
                                    instructions  = 'Existing check'
                                }
                                timeout   = 1440
                                type      = @{
                                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                                    name = 'Approval'
                                }
                                resource  = @{
                                    type = 'environment'
                                    id   = '123'
                                }
                                createdBy = @{
                                    id = 'user-id-1'
                                }
                                createdOn = '2024-01-01T00:00:00Z'
                            }
                        )
                    }
                }
            }
        }

        It 'Should warn and return existing check configuration' {
            # Arrange
            $configuration = [PSCustomObject]@{
                settings = @{
                    definitionRef = @{
                        id = $definitionRefId
                    }
                }
                timeout  = 1440
                type     = @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
                resource = @{
                    type = 'environment'
                    id   = '123'
                }
            }

            # Act
            $result = New-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $configuration -WarningVariable warnings -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'already exists'
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with default value' {
            $command = Get-Command New-AdoCheckConfiguration
            $parameter = $command.Parameters['CollectionUri']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
        }

        It 'Should have ProjectName parameter with ProjectId alias' {
            $command = Get-Command New-AdoCheckConfiguration
            $parameter = $command.Parameters['ProjectName']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Configuration as mandatory parameter' {
            $command = Get-Command New-AdoCheckConfiguration
            $parameter = $command.Parameters['Configuration']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have Version parameter with ApiVersion alias' {
            $command = Get-Command New-AdoCheckConfiguration
            $parameter = $command.Parameters['Version']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should have Version parameter with ValidateSet' {
            $command = Get-Command New-AdoCheckConfiguration
            $parameter = $command.Parameters['Version']
            $validateSet = $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet.ValidValues | Should -Contain '7.1'
            $validateSet.ValidValues | Should -Contain '7.2-preview.1'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command New-AdoCheckConfiguration
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'Error handling' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'REST API error'
            }
        }

        It 'Should throw when invalid GUID format is provided' {
            # Arrange
            $configuration = [PSCustomObject]@{
                settings = @{
                    definitionRef = @{
                        id = 'invalid-guid'
                    }
                }
                timeout  = 1440
                type     = @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
                resource = @{
                    type = 'environment'
                    id   = 123
                }
            }

            # Act & Assert
            { New-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $configuration -Confirm:$false } | Should -Throw -ExpectedMessage '*Invalid GUID format*'
        }

        It 'Should throw when API call fails' {
            # Arrange
            $configuration = [PSCustomObject]@{
                settings = @{
                    definitionRef = @{
                        id = $definitionRefId
                    }
                }
                timeout  = 1440
                type     = @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
                resource = @{
                    type = 'environment'
                    id   = 123
                }
            }

            # Act & Assert
            { New-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $configuration -Confirm:$false } | Should -Throw
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                return @{
                    id        = 1
                    settings  = $Body.settings
                    timeout   = $Body.timeout
                    type      = $Body.type
                    resource  = $Body.resource
                    createdBy = @{
                        id = 'user-id-1'
                    }
                    createdOn = '2024-01-01T00:00:00Z'
                }
            }
        }

        It 'Should return object with all required properties' {
            # Arrange
            $configuration = [PSCustomObject]@{
                settings = @{
                    definitionRef = @{
                        id = $definitionRefId
                    }
                }
                timeout  = 1440
                type     = @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
                resource = @{
                    type = 'environment'
                    id   = 123
                }
            }

            # Act
            $result = New-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $configuration -Confirm:$false

            # Assert
            $result.id | Should -Not -BeNullOrEmpty
            $result.timeout | Should -Be 1440
            $result.type | Should -Not -BeNullOrEmpty
            $result.resource | Should -Not -BeNullOrEmpty
            $result.createdBy | Should -Be 'user-id-1'
            $result.createdOn | Should -Not -BeNullOrEmpty
            $result.project | Should -Be $projectName
            $result.collectionUri | Should -Be $collectionUri
        }

        It 'Should include settings when present in response' {
            # Arrange
            $configuration = [PSCustomObject]@{
                settings = @{
                    definitionRef = @{
                        id = $definitionRefId
                    }
                    instructions  = 'Test'
                }
                timeout  = 1440
                type     = @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
                resource = @{
                    type = 'environment'
                    id   = 123
                }
            }

            # Act
            $result = New-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $configuration -Confirm:$false

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'settings'
        }
    }
}
