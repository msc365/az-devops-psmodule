BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'New-AdoProject' {
    BeforeAll {
        # Sample process data for mocking
        $mockProcess = @{
            id          = 'adcc42ab-9882-485e-a3ed-7678f01f66bc'
            name        = 'Agile'
            description = 'This template is flexible and will work great for most teams using Agile planning methods.'
        }

        # Sample project creation response (operation status)
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

        # Sample created project
        $mockCreatedProject = @{
            id          = '12345678-1234-1234-1234-123456789012'
            name        = 'NewTestProject'
            description = 'A new test project'
            visibility  = 'Private'
            state       = 'wellFormed'
            defaultTeam = @{
                id   = 'team-id-1'
                name = 'NewTestProject Team'
            }
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProcess { return $mockProcess }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockOperationSucceeded }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockCreatedProject }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should create a new project with default parameters' {
            # Act
            $result = New-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'NewTestProject' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'NewTestProject'
            $result.id | Should -Be '12345678-1234-1234-1234-123456789012'
        }

        It 'Should create a project with custom description and visibility' {
            # Act
            $result = New-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'NewTestProject' -Description 'Custom description' -Visibility 'Public' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects' -and
                $Method -eq 'POST'
            }
        }

        It 'Should create a project with specified Process template' {
            # Arrange
            $mockScrumProcess = @{
                id   = '6b724908-ef14-45cf-84f8-768b5384da45'
                name = 'Scrum'
            }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProcess { return $mockScrumProcess }

            # Act
            $result = New-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'NewTestProject' -Process 'Scrum' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoProcess -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Name -eq 'Scrum'
            }
        }

        It 'Should create a project with specified SourceControl type' {
            # Act
            $result = New-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'NewTestProject' -SourceControl 'Tfvc' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should accept multiple project names via pipeline' {
            # Act
            $result = @('Project1', 'Project2') | New-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
            Should -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule -Times 2
        }

        It 'Should poll for operation completion' {
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
            $result = New-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'NewTestProject' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
            Should -Invoke Start-Sleep -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should retrieve created project details after successful creation' {
            # Act
            $result = New-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'NewTestProject' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Name -eq 'NewTestProject'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProcess { return $mockProcess }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockOperationSucceeded }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockCreatedProject }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { New-AdoProject -CollectionUri 'invalid-uri' -Name 'TestProject' } | Should -Throw
        }

        It 'Should require Name parameter' {
            # Act & Assert
            $commandMetadata = (Get-Command New-AdoProject).Parameters['Name']
            $commandMetadata.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            $result = New-AdoProject -Name 'TestProject' -Confirm:$false

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
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProcess { return $mockProcess }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockOperationSucceeded }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockCreatedProject }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should construct correct REST API URI' {
            # Act
            New-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/projects' -and
                $Version -eq '7.1' -and
                $Method -eq 'POST'
            }
        }

        It 'Should call Get-AdoProcess before creating project' {
            # Act
            New-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject' -Process 'Agile' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoProcess -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Name -eq 'Agile'
            }
        }
    }

    Context 'Edge Cases and Error Handling' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProcess { return $mockProcess }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should throw error when process template is not found' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProcess { return $null }

            # Act & Assert
            { New-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject' -Process 'Agile' } | Should -Throw "*Process template 'Agile' not found*"
        }

        It 'Should throw error when project creation fails' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockOperationFailed }

            # Act & Assert
            { New-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject' -Confirm:$false } | Should -Throw '*Project creation failed*'
        }

        It 'Should handle ProjectAlreadyExistsException and return existing project' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('ProjectAlreadyExistsException: The project TestProject already exists.')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'ProjectAlreadyExists', 'ResourceExists', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('ProjectAlreadyExistsException: The project TestProject already exists.')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockCreatedProject }

            # Act
            $result = New-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject' -Confirm:$false -WarningAction SilentlyContinue

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'NewTestProject'
            Should -Invoke Get-AdoProject -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { New-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject' -Confirm:$false } | Should -Throw '*API Error: Unauthorized*'
        }

        It 'Should poll multiple times until status is succeeded' {
            # Arrange
            $script:callCount = 0
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                $script:callCount++
                if ($script:callCount -le 3) {
                    return $mockOperationPending
                } else {
                    return $mockOperationSucceeded
                }
            }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoProject { return $mockCreatedProject }

            # Act
            $result = New-AdoProject -CollectionUri 'https://dev.azure.com/my-org' -Name 'TestProject' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 4
            Should -Invoke Start-Sleep -ModuleName Azure.DevOps.PSModule -Times 3
        }
    }
}
