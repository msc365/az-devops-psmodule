BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Remove-AdoProject' {
    BeforeAll {
        # Sample project data for mocking
        $mockProject = @{
            id            = '12345678-1234-1234-1234-123456789012'
            name          = 'TestProject'
            description   = 'Test project to delete'
            visibility    = 'Private'
            state         = 'wellFormed'
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
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockOperationSucceeded }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should delete a project by name' {
            # Act
            Remove-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects/12345678-1234-1234-1234-123456789012' -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should delete a project by GUID' {
            # Act
            Remove-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name '12345678-1234-1234-1234-123456789012' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects/12345678-1234-1234-1234-123456789012' -and
                $Method -eq 'DELETE'
            }
            # Should not call Get-AdoProject when GUID is provided
            Should -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule -Times 0
        }

        It 'Should accept project names via pipeline' {
            # Act
            @('TestProject1', 'TestProject2') | Remove-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
        }

        It 'Should poll for deletion completion' {
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
            Remove-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
            Should -Invoke Start-Sleep -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should retrieve project ID when name is provided' {
            # Act
            Remove-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Name -eq 'TestProject'
            }
        }

        It 'Should construct correct REST API URI' {
            # Act
            Remove-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects/12345678-1234-1234-1234-123456789012' -and
                $Version -eq '7.1' -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should parse valid GUID correctly and skip Get-AdoProject' {
            # Act
            Remove-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name '12345678-1234-1234-1234-123456789012' -Confirm:$false

            # Assert - Should not call Get-AdoProject for valid GUID
            Should -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule -Times 0
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockOperationSucceeded }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Remove-AdoProject -CollectionUri 'invalid-uri' -Name 'TestProject' } | Should -Throw
        }

        It 'Should require Name parameter' {
            # Act & Assert
            # Cannot test required parameter directly as it prompts for input
            # This is enforced by PowerShell parameter validation
            $commandMetadata = (Get-Command Remove-AdoProject).Parameters['Name']
            $commandMetadata.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            Remove-AdoProject -Name 'TestProject' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*dev.azure.com/default-org*'
            }

            # Cleanup
            Remove-Item env:DefaultAdoCollectionUri -ErrorAction SilentlyContinue
        }
    }

    Context 'Edge Cases and Error Handling' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should throw error when project deletion fails' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockOperationFailed }

            # Act & Assert
            { Remove-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject' -Confirm:$false } | Should -Throw '*Project deletion failed*'
        }

        It 'Should warn when project does not exist (ProjectDoesNotExistWithNameException)' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('ProjectDoesNotExistWithNameException: The project with ID NonExistentProject does not exist.')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'ProjectDoesNotExist', 'ObjectNotFound', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('ProjectDoesNotExistWithNameException: The project with ID NonExistentProject does not exist.')
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act & Assert - Should write warning but not throw
            { Remove-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'NonExistentProject' -Confirm:$false -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should continue to next item when Get-AdoProject returns null' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $null }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockOperationSucceeded }

            # Act
            Remove-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'NonExistentProject' -Confirm:$false

            # Assert - Should not invoke delete API if project ID not found
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 0
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockProject }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { Remove-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject' -Confirm:$false } | Should -Throw '*API Error: Unauthorized*'
        }
    }
}
