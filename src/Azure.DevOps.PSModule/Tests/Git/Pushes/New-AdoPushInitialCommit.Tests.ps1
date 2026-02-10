BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'New-AdoPushInitialCommit' {
    BeforeAll {
        # Sample push response data for mocking successful push
        $mockPushResponse = @{
            pushId      = 12345
            date        = '2024-01-15T10:30:00Z'
            pushedBy    = @{
                displayName = 'Test User'
                id          = 'user-guid-123'
            }
            commits     = @(
                @{
                    commitId = 'abc123def456'
                    comment  = 'Initial commit'
                    author   = @{
                        name = 'Test User'
                    }
                }
            )
            refUpdates  = @(
                @{
                    name        = 'refs/heads/main'
                    oldObjectId = '0000000000000000000000000000000000000000'
                    newObjectId = 'abc123def456'
                }
            )
            projectName = 'TestProject'
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockPushResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should create initial commit with default parameters' {
            # Act
            $result = New-AdoPushInitialCommit -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -RepositoryName 'TestRepo' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.pushId | Should -Be 12345
            $result.commits | Should -Not -BeNullOrEmpty
            $result.refUpdates | Should -Not -BeNullOrEmpty
        }

        It 'Should return all expected properties' {
            # Act
            $result = New-AdoPushInitialCommit -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -RepositoryName 'TestRepo' -Confirm:$false

            # Assert
            $result.pushId | Should -Be 12345
            $result.commits | Should -Not -BeNullOrEmpty
            $result.refUpdates | Should -Not -BeNullOrEmpty
            $result.pushedBy | Should -Not -BeNullOrEmpty
            $result.date | Should -Be '2024-01-15T10:30:00Z'
            $result.projectName | Should -Be 'TestProject'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should accept repository name via pipeline' {
            # Act
            $result = 'TestRepo' | New-AdoPushInitialCommit -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.pushId | Should -Be 12345
        }

        It 'Should create commit with multiple files' {
            # Arrange
            $files = @(
                @{
                    path        = '/README.md'
                    content     = '# My Project'
                    contentType = 'rawtext'
                },
                @{
                    path        = '/src/app.ps1'
                    content     = 'Write-Host "Hello World"'
                    contentType = 'rawtext'
                },
                @{
                    path        = '/.gitignore'
                    content     = 'bin/`nobj/'
                    contentType = 'rawtext'
                }
            )

            # Act
            $result = New-AdoPushInitialCommit -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -RepositoryName 'TestRepo' -Files $files -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should handle base64encoded content type' {
            # Arrange
            $files = @(
                @{
                    path        = '/assets/logo.png'
                    content     = 'aGVsbG8gd29ybGQ='
                    contentType = 'base64encoded'
                }
            )

            # Act
            $result = New-AdoPushInitialCommit -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -RepositoryName 'TestRepo' -Files $files -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.pushId | Should -Be 12345
        }

        It 'Should use custom branch name' {
            # Act
            $result = New-AdoPushInitialCommit -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -RepositoryName 'TestRepo' -BranchName 'develop' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.pushId | Should -Be 12345
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/git/repositories/TestRepo/pushes'
            }
        }

        It 'Should use custom commit message' {
            # Act
            $result = New-AdoPushInitialCommit -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -RepositoryName 'TestRepo' -Message 'Custom initial commit' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.pushId | Should -Be 12345
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/git/repositories/TestRepo/pushes'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockPushResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { New-AdoPushInitialCommit -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -RepositoryName 'TestRepo' -Confirm:$false } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            try {
                # Act
                $result = New-AdoPushInitialCommit -ProjectName 'TestProject' -RepositoryName 'TestRepo' -Confirm:$false

                # Assert
                Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                    $Uri -like '*dev.azure.com/default-org*'
                }
            } finally {
                # Cleanup
                Remove-Item env:DefaultAdoCollectionUri -ErrorAction SilentlyContinue
            }
        }

        It 'Should use default ProjectName from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoProject = 'DefaultProject'

            try {
                # Act
                $result = New-AdoPushInitialCommit -CollectionUri 'https://dev.azure.com/my-org' -RepositoryName 'TestRepo' -Confirm:$false

                # Assert
                Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                    $Uri -like '*DefaultProject*'
                }
            } finally {
                # Cleanup
                Remove-Item env:DefaultAdoProject -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'API Interaction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockPushResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should construct correct REST API URI' {
            # Act
            New-AdoPushInitialCommit -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -RepositoryName 'TestRepo' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/git/repositories/TestRepo/pushes' -and
                $Version -eq '7.1' -and
                $Method -eq 'POST'
            }
        }

        It 'Should use POST method when creating push' {
            # Act
            New-AdoPushInitialCommit -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -RepositoryName 'TestRepo' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'POST'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Act
            New-AdoPushInitialCommit -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -RepositoryName 'TestRepo' -Confirm:$false

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should handle GitReferenceStaleException gracefully' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('GitReferenceStaleException: The reference has already been initialized.')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'GitReferenceStaleException', 'InvalidOperation', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('GitReferenceStaleException: The reference has already been initialized.')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act
            $result = New-AdoPushInitialCommit -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -RepositoryName 'TestRepo' -BranchName 'main' -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $result | Should -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { New-AdoPushInitialCommit -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -RepositoryName 'TestRepo' -Confirm:$false } | Should -Throw '*API Error: Unauthorized*'
        }
    }
}
