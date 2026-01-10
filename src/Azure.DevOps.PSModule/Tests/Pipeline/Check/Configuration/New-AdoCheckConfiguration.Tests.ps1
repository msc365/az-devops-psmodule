BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'New-AdoCheckConfiguration' {
    BeforeAll {
        # Sample configuration creation response
        $mockCreatedConfiguration = @{
            id        = 1
            timeout   = 1440
            type      = @{
                id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                name = 'Approval'
            }
            settings  = @{
                approvers            = @(@{ id = 'user1' })
                definitionRef        = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
                minRequiredApprovers = 1
            }
            resource  = @{
                type = 'environment'
                id   = '1'
            }
            createdBy = @{ id = 'creator1' }
            createdOn = '2024-01-01T00:00:00Z'
        }

        $mockExistingConfiguration = @{
            value = @(
                @{
                    id        = 2
                    timeout   = 1440
                    type      = @{
                        id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                        name = 'Approval'
                    }
                    settings  = @{
                        approvers            = @(@{ id = 'user1' })
                        definitionRef        = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
                        minRequiredApprovers = 1
                    }
                    resource  = @{
                        type = 'environment'
                        id   = '1'
                    }
                    createdBy = @{ id = 'creator1' }
                    createdOn = '2024-01-02T00:00:00Z'
                }
            )
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCreatedConfiguration }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should create a new check configuration' {
            # Arrange
            $config = [PSCustomObject]@{
                settings = @{
                    approvers            = @(@{ id = 'user1' })
                    definitionRef        = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
                    minRequiredApprovers = 1
                }
                timeout  = 1440
                type     = @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
                resource = @{
                    type = 'environment'
                    id   = 1
                }
            }

            # Act
            $result = New-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Configuration $config -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            $result.type.name | Should -Be 'Approval'
        }

        It 'Should return configuration with all expected properties' {
            # Arrange
            $config = [PSCustomObject]@{
                settings = @{
                    approvers            = @(@{ id = 'user1' })
                    definitionRef        = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
                    minRequiredApprovers = 1
                }
                timeout  = 1440
                type     = @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
                resource = @{
                    type = 'environment'
                    id   = 1
                }
            }

            # Act
            $result = New-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Configuration $config -Confirm:$false

            # Assert
            $result.id | Should -Be 1
            $result.timeout | Should -Be 1440
            $result.type.name | Should -Be 'Approval'
            $result.settings | Should -Not -BeNullOrEmpty
            $result.resource | Should -Not -BeNullOrEmpty
            $result.createdBy | Should -Be 'creator1'
            $result.createdOn | Should -Be '2024-01-01T00:00:00Z'
            $result.project | Should -Be 'TestProject'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should return existing configuration when it already exists' {
            # Arrange
            $config = [PSCustomObject]@{
                settings = @{
                    approvers            = @(@{ id = 'user1' })
                    definitionRef        = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
                    minRequiredApprovers = 1
                }
                timeout  = 1440
                type     = @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
                resource = @{
                    type = 'environment'
                    id   = 1
                }
            }
            $exception = New-Object System.Management.Automation.RuntimeException('Configuration already exists')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'ConfigurationExists', 'ResourceExists', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('Configuration already exists for this resource.')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                if ($Method -eq 'POST') {
                    throw $errorRecord
                } else {
                    return $mockExistingConfiguration
                }
            }

            # Act
            $result = New-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Configuration $config -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 2
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCreatedConfiguration }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            # Arrange
            $config = [PSCustomObject]@{
                settings = @{
                    definitionRef = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
                }
                type     = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
                resource = @{ type = 'environment'; id = 1 }
            }

            # Act & Assert
            { New-AdoCheckConfiguration -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -Configuration $config -Confirm:$false } | Should -Throw
        }

        It 'Should throw error for invalid GUID in definitionRef' {
            # Arrange
            $config = [PSCustomObject]@{
                settings = @{
                    definitionRef = @{ id = 'invalid-guid' }
                }
                type     = @{ id = 'type-id' }
                resource = @{ type = 'environment'; id = 1 }
            }

            # Act & Assert
            { New-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Configuration $config -Confirm:$false } | Should -Throw '*Invalid GUID format*'
        }
    }

    Context 'API Interaction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCreatedConfiguration }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct REST API URI for creating configuration' {
            # Arrange
            $config = [PSCustomObject]@{
                settings = @{
                    definitionRef = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
                }
                type     = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
                resource = @{ type = 'environment'; id = 1 }
            }

            # Act
            New-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Configuration $config -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/pipelines/checks/configurations' -and
                $Version -eq '7.2-preview.1' -and
                $Method -eq 'POST'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Arrange
            $config = [PSCustomObject]@{
                settings = @{
                    definitionRef = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
                }
                type     = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
                resource = @{ type = 'environment'; id = 1 }
            }

            # Act
            New-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Configuration $config -Confirm:$false

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should propagate errors other than already exists' {
            # Arrange
            $config = [PSCustomObject]@{
                settings = @{
                    definitionRef = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
                }
                type     = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
                resource = @{ type = 'environment'; id = 1 }
            }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { New-AdoCheckConfiguration -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Configuration $config -Confirm:$false } | Should -Throw '*API Error: Unauthorized*'
        }
    }
}
