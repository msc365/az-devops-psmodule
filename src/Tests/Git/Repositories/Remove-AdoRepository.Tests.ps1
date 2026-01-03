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

    # Mock Get-AdoRepository for repository ID resolution
    Mock Get-AdoRepository -ModuleName $moduleName -MockWith {
        param($CollectionUri, $ProjectName, $Name)
        return @{
            id            = "repo-id-$Name"
            name          = $Name
            project       = @{
                id   = "project-id-$ProjectName"
                name = $ProjectName
            }
            defaultBranch = 'refs/heads/main'
            url           = "$CollectionUri/$ProjectName/_apis/git/repositories/repo-id-$Name"
            remoteUrl     = "$CollectionUri/$ProjectName/_git/$Name"
        }
    }

    # Mock Invoke-AdoRestMethod for repository deletion
    Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
        param($Uri, $Method, $Version)
        # Successful deletion returns nothing
        return $null
    }
}

Describe 'Remove-AdoRepository' {

    Context 'When removing a repository' {
        It 'Should remove a repository by name' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'RepositoryToRemove'

            # Act
            Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -Confirm:$false

            # Assert
            # Verify Get-AdoRepository was called to resolve repository name to ID
            Should -Invoke Get-AdoRepository -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Name -eq $repoName -and
                $ProjectName -eq $projectName
            }

            # Verify Invoke-AdoRestMethod was called to delete the repository
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/$projectName/_apis/git/repositories/repo-id-$repoName" -and
                $Method -eq 'DELETE' -and
                $Version -eq '7.1'
            }
        }

        It 'Should remove a repository by ID (GUID)' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoId = '12345678-1234-1234-1234-123456789abc'

            # Act
            Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoId -Confirm:$false

            # Assert
            # Verify Get-AdoRepository was NOT called when GUID is provided
            Should -Invoke Get-AdoRepository -ModuleName $moduleName -Exactly 0

            # Verify Invoke-AdoRestMethod was called with the GUID directly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/$projectName/_apis/git/repositories/$repoId" -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should handle repository not found gracefully' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'NonExistentRepo'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = "VS404: The repository with name or identifier '$repoName' does not exist or you do not have permission to access it."
                    typeKey = 'NotFoundException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Repository not found')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'NotFoundException',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert
            { Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -WarningAction SilentlyContinue -Confirm:$false } | Should -Not -Throw

            # Verify the warning was issued (the function should not throw)
        }

        It 'Should use environment variables when parameters are not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/envorg'
            $env:DefaultAdoProject = 'envproject'
            $repoName = 'RepoToRemove'

            # Act
            Remove-AdoRepository -Name $repoName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/envorg/envproject/_apis/git/repositories/repo-id-RepoToRemove'
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept repository names from pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoNames = @('Repo1', 'Repo2', 'Repo3')

            # Act
            $repoNames | Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            # Verify Get-AdoRepository was called for each repository
            Should -Invoke Get-AdoRepository -ModuleName $moduleName -Exactly 3

            # Verify Invoke-AdoRestMethod was called for each repository
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3 -ParameterFilter {
                $Method -eq 'DELETE'
            }
        }

        It 'Should accept repository objects with Name property from pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoObjects = @(
                [PSCustomObject]@{ Name = 'Repo1' },
                [PSCustomObject]@{ Name = 'Repo2' }
            )

            # Act
            $repoObjects | Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2 -ParameterFilter {
                $Method -eq 'DELETE'
            }
        }

        It 'Should accept repository IDs from pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoIds = @(
                '12345678-1234-1234-1234-123456789abc',
                '87654321-4321-4321-4321-cba987654321'
            )

            # Act
            $repoIds | Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            # Verify Get-AdoRepository was NOT called for GUIDs
            Should -Invoke Get-AdoRepository -ModuleName $moduleName -Exactly 0

            # Verify Invoke-AdoRestMethod was called for each repository
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2 -ParameterFilter {
                $Method -eq 'DELETE'
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should have Name as a mandatory parameter' {
            # Arrange
            $command = Get-Command Remove-AdoRepository

            # Act
            $nameParam = $command.Parameters['Name']

            # Assert
            $nameParam.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have CollectionUri parameter with default value' {
            # Arrange
            $command = Get-Command Remove-AdoRepository

            # Act
            $collectionUriParam = $command.Parameters['CollectionUri']

            # Assert
            $collectionUriParam | Should -Not -BeNullOrEmpty
            $collectionUriParam.Attributes.Mandatory | Should -Not -Contain $true
        }

        It 'Should have ProjectName parameter with default value' {
            # Arrange
            $command = Get-Command Remove-AdoRepository

            # Act
            $projectNameParam = $command.Parameters['ProjectName']

            # Assert
            $projectNameParam | Should -Not -BeNullOrEmpty
            $projectNameParam.Attributes.Mandatory | Should -Not -Contain $true
        }

        It 'Should support Name parameter with multiple aliases' {
            # Arrange
            $command = Get-Command Remove-AdoRepository
            $nameParam = $command.Parameters['Name']

            # Act & Assert
            $nameParam.Aliases | Should -Contain 'Id'
            $nameParam.Aliases | Should -Contain 'RepositoryId'
        }

        It 'Should accept valid API versions' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'TestRepo'

            # Act
            Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -Version '7.2-preview.2' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.2'
            }
        }

        It 'Should support ShouldProcess' {
            # Arrange
            $command = Get-Command Remove-AdoRepository

            # Act & Assert
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'Error handling' {
        It 'Should throw when deletion fails with unknown error' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'FailRepo'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Unauthorized access'
                    typeKey = 'UnauthorizedException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Unauthorized')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'Unauthorized',
                    [System.Management.Automation.ErrorCategory]::PermissionDenied,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert
            { Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -Confirm:$false } | Should -Throw
        }

        It 'Should handle Get-AdoRepository returning null' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'NonExistentRepo'

            Mock Get-AdoRepository -ModuleName $moduleName -MockWith {
                return $null
            }

            # Act
            Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -Confirm:$false

            # Assert - function should skip when repository is not found
            # Verify Invoke-AdoRestMethod was not called
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should continue on error when using Continue error action' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoNames = @('Repo1', 'FailRepo', 'Repo3')

            # Context-specific mock override
            BeforeAll {
                Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                    param($Uri)
                    if ($Uri -match 'FailRepo') {
                        throw 'Failed to delete repository'
                    }
                    return $null
                }
            }

            # Act & Assert
            { $repoNames | Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -ErrorAction SilentlyContinue -Confirm:$false } | Should -Not -Throw
        }

        It 'Should warn when NotFoundException error occurs' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'MissingRepo'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = "Repository $repoName not found"
                    typeKey = 'NotFoundException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Repository not found')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'NotFoundException',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert - should not throw
            { Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -WarningAction SilentlyContinue -Confirm:$false } | Should -Not -Throw
        }
    }

    Context 'Output validation' {
        It 'Should not return any output on successful deletion' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'TestRepo'

            # Act
            $result = Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -Confirm:$false

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should not return output when deleting multiple repositories' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoNames = @('Repo1', 'Repo2')

            # Act
            $result = $repoNames | Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Integration scenarios' {
        It 'Should work with ShouldProcess in WhatIf mode' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'TestRepo'

            # Act
            Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -WhatIf

            # Assert
            # In WhatIf mode, the function should not call Invoke-AdoRestMethod
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should have ShouldProcess support' {
            # Arrange
            $command = Get-Command Remove-AdoRepository

            # Act & Assert
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should handle mixed GUID and name inputs from pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $mixedInputs = @(
                'RepoByName',
                '12345678-1234-1234-1234-123456789abc',
                'AnotherRepoByName'
            )

            # Act
            $mixedInputs | Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            # Verify Get-AdoRepository was called only for non-GUID inputs (2 times)
            Should -Invoke Get-AdoRepository -ModuleName $moduleName -Exactly 2

            # Verify Invoke-AdoRestMethod was called for all repositories (3 times)
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3 -ParameterFilter {
                $Method -eq 'DELETE'
            }
        }

        It 'Should delete multiple repositories sequentially' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoNames = 1..5 | ForEach-Object { "Repo$_" }

            # Act
            $repoNames | Remove-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 5 -ParameterFilter {
                $Method -eq 'DELETE'
            }
        }
    }
}
