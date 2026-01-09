BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Set-AdoProject' {
    BeforeAll {
        # Sample project data for mocking
        $mockProject = @{
            id          = '12345678-1234-1234-1234-123456789012'
            name        = 'TestProject'
            description = 'Original description'
            visibility  = 'Private'
            state       = 'wellFormed'
            defaultTeam = @{
                id   = 'team-id-1'
                name = 'TestProject Team'
            }
        }

        # Sample operation responses
        $mockOperationPending = @{
            id     = 'operation-id-123'
            status = 'inProgress'
            url    = 'https://dev.azure.com/my-org/_apis/operations/operation-id-123'
        }

        $mockOperationSucceeded = @{
            id     = 'operation-id-123'
            status = 'succeeded'
            url    = 'https://dev.azure.com/my-org/_apis/operations/operation-id-123'
        }

        $mockOperationFailed = @{
            id     = 'operation-id-123'
            status = 'failed'
            url    = 'https://dev.azure.com/my-org/_apis/operations/operation-id-123'
        }

        # Updated project
        $mockUpdatedProject = @{
            id           = '12345678-1234-1234-1234-123456789012'
            name         = 'UpdatedTestProject'
            description  = 'Updated description'
            visibility   = 'Public'
            state        = 'wellFormed'
            defaultTeam  = @{
                id   = 'team-id-1'
                name = 'UpdatedTestProject Team'
            }
            capabilities = @{
                versioncontrol = @{ sourceControlType = 'Git' }
            }
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockUpdatedProject }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockOperationSucceeded }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should update a project by ID' {
            # Act
            $result = Set-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Id '12345678-1234-1234-1234-123456789012' -Name 'UpdatedTestProject' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'UpdatedTestProject'
        }

        It 'Should update only the Name property' {
            # Act
            Set-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Id '12345678-1234-1234-1234-123456789012' -Name 'NewName' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should update only the Description property' {
            # Act
            Set-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Id '12345678-1234-1234-1234-123456789012' -Description 'New description' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should update only the Visibility property' {
            # Act
            Set-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Id '12345678-1234-1234-1234-123456789012' -Visibility 'Public' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should update multiple properties at once' {
            # Act
            Set-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Id '12345678-1234-1234-1234-123456789012' -Name 'NewName' -Description 'New desc' -Visibility 'Public' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'PATCH'
            }
        }

        It 'Should accept project via pipeline with properties' {
            # Arrange
            $projectInput = [PSCustomObject]@{
                Id          = '12345678-1234-1234-1234-123456789012'
                Name        = 'UpdatedName'
                Description = 'Updated desc'
            }

            # Act
            $result = $projectInput | Set-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should poll for update completion' {
            # Arrange
            $script:callCount = 0
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                $script:callCount++
                if ($script:callCount -eq 1) {
                    return $mockOperationPending
                } else {
                    return $mockOperationSucceeded
                }
            }

            # Act
            Set-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Id '12345678-1234-1234-1234-123456789012' -Name 'NewName' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
            Should -Invoke Start-Sleep -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should retrieve updated project details after successful update' {
            # Act
            $result = Set-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Id '12345678-1234-1234-1234-123456789012' -Name 'NewName' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Id -eq '12345678-1234-1234-1234-123456789012' -and
                $IncludeCapabilities -eq $true
            }
        }

        It 'Should resolve project name to ID before updating' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject } -ParameterFilter { $Name -eq 'TestProject' }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockUpdatedProject } -ParameterFilter { $Id -eq '12345678-1234-1234-1234-123456789012' }

            # Act
            Set-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Id 'TestProject' -Description 'New desc' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Name -eq 'TestProject'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockUpdatedProject }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockOperationSucceeded }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Set-AdoProject -CollectionUri 'invalid-uri' -Id '12345678-1234-1234-1234-123456789012' -Name 'NewName' } | Should -Throw
        }

        It 'Should require Id parameter' {
            # Act & Assert
            # Cannot test required parameter directly as it prompts for input
            # This is enforced by PowerShell parameter validation
            $commandMetadata = (Get-Command Set-AdoProject).Parameters['Id']
            $commandMetadata.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            Set-AdoProject -Id '12345678-1234-1234-1234-123456789012' -Name 'NewName' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*dev.azure.com/default-org*'
            }

            # Cleanup
            Remove-Item env:DefaultAdoCollectionUri -ErrorAction SilentlyContinue
        }
    }

    Context 'API Interaction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockUpdatedProject }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockOperationSucceeded }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should construct correct REST API URI' {
            # Act
            Set-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Id '12345678-1234-1234-1234-123456789012' -Name 'NewName' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects/12345678-1234-1234-1234-123456789012' -and
                $Version -eq '7.1' -and
                $Method -eq 'PATCH'
            }
        }
    }

    Context 'Edge Cases and Error Handling' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should throw error when project update fails' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockOperationFailed }

            # Act & Assert
            { Set-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Id '12345678-1234-1234-1234-123456789012' -Name 'NewName' -Confirm:$false } | Should -Throw '*Project update failed*'
        }

        It 'Should warn when project does not exist (ProjectDoesNotExistWithNameException)' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('ProjectDoesNotExistWithNameException: The project with ID NonExistentProject does not exist.')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'ProjectDoesNotExist', 'ObjectNotFound', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('ProjectDoesNotExistWithNameException: The project with ID NonExistentProject does not exist.')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act & Assert - Should write warning but not throw
            { Set-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Id 'NonExistentProject' -Name 'NewName' -Confirm:$false -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { Set-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Id '12345678-1234-1234-1234-123456789012' -Name 'NewName' -Confirm:$false } | Should -Throw '*API Error: Unauthorized*'
        }
    }
}
