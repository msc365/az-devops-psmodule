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

    # Mock Invoke-AdoRestMethod for successful responses
    Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
        param($Uri, $Method, $Version, $QueryParameters)

        # Return different mock data based on URI pattern
        if ($Uri -match '/_apis/git/repositories/([^/]+)$' -and $Matches[1] -ne '') {
            # Get specific repository
            $repoName = $Matches[1]
            return @{
                id            = "repo-id-$repoName"
                name          = $repoName
                url           = "$Uri"
                remoteUrl     = "https://dev.azure.com/testorg/testproject/_git/$repoName"
                defaultBranch = 'refs/heads/main'
                project       = @{
                    id   = 'project-id-123'
                    name = 'testproject'
                }
            }
        } else {
            # List repositories
            return @{
                count = 3
                value = @(
                    @{
                        id            = 'repo-id-1'
                        name          = 'Repository1'
                        url           = 'https://dev.azure.com/testorg/testproject/_apis/git/repositories/repo-id-1'
                        remoteUrl     = 'https://dev.azure.com/testorg/testproject/_git/Repository1'
                        defaultBranch = 'refs/heads/main'
                        project       = @{
                            id   = 'project-id-123'
                            name = 'testproject'
                        }
                    },
                    @{
                        id            = 'repo-id-2'
                        name          = 'Repository2'
                        url           = 'https://dev.azure.com/testorg/testproject/_apis/git/repositories/repo-id-2'
                        remoteUrl     = 'https://dev.azure.com/testorg/testproject/_git/Repository2'
                        defaultBranch = 'refs/heads/develop'
                        project       = @{
                            id   = 'project-id-123'
                            name = 'testproject'
                        }
                    },
                    @{
                        id            = 'repo-id-3'
                        name          = 'Repository3'
                        url           = 'https://dev.azure.com/testorg/testproject/_apis/git/repositories/repo-id-3'
                        remoteUrl     = 'https://dev.azure.com/testorg/testproject/_git/Repository3'
                        defaultBranch = 'refs/heads/main'
                        project       = @{
                            id   = 'project-id-123'
                            name = 'testproject'
                        }
                    }
                )
            }
        }
    }
}

Describe 'Get-AdoRepository' {

    Context 'When retrieving all repositories' {
        It 'Should retrieve all repositories when no name is specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'

            # Act
            $result = Get-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].name | Should -Be 'Repository1'
            $result[1].name | Should -Be 'Repository2'
            $result[2].name | Should -Be 'Repository3'
            $result[0].projectName | Should -Be $projectName
            $result[0].collectionUri | Should -Be $collectionUri

            # Verify Invoke-AdoRestMethod was called correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/$projectName/_apis/git/repositories" -and
                $Method -eq 'GET' -and
                $Version -eq '7.1'
            }
        }

        It 'Should include query parameters when switches are specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'

            # Act
            $result = Get-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -IncludeLinks -IncludeHidden -IncludeAllUrls

            # Assert
            $result | Should -Not -BeNullOrEmpty

            # Verify Invoke-AdoRestMethod was called with query parameters
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/$projectName/_apis/git/repositories" -and
                $QueryParameters -like '*includeLinks=*' -and
                $QueryParameters -like '*includeHidden=*' -and
                $QueryParameters -like '*includeAllUrls=*'
            }
        }

        It 'Should use environment variables when parameters are not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/envorg'
            $env:DefaultAdoProject = 'envproject'

            # Act
            $result = Get-AdoRepository

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/envorg/envproject/_apis/git/repositories'
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }
    }

    Context 'When retrieving a specific repository' {
        It 'Should retrieve a repository by name' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'MyRepository'

            # Act
            $result = Get-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $repoName
            $result.id | Should -Be "repo-id-$repoName"
            $result.projectName | Should -Be $projectName
            $result.collectionUri | Should -Be $collectionUri

            # Verify Invoke-AdoRestMethod was called correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/$projectName/_apis/git/repositories/$repoName" -and
                $Method -eq 'GET'
            }
        }

        It 'Should retrieve a repository by ID' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoId = '12345678-1234-1234-1234-123456789abc'

            # Act
            $result = Get-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoId

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be "repo-id-$repoId"

            # Verify Invoke-AdoRestMethod was called correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/$projectName/_apis/git/repositories/$repoId"
            }
        }

        It 'Should accept repository name from pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoNames = @('Repo1', 'Repo2')

            # Act
            $result = $repoNames | Get-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].name | Should -Be 'Repo1'
            $result[1].name | Should -Be 'Repo2'

            # Verify Invoke-AdoRestMethod was called for each repository
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }

    Context 'Parameter validation' {
        It 'Should have ProjectName parameter with default value' {
            # Arrange
            $command = Get-Command Get-AdoRepository

            # Act
            $projectNameParam = $command.Parameters['ProjectName']

            # Assert
            $projectNameParam | Should -Not -BeNullOrEmpty
            $projectNameParam.Attributes.Mandatory | Should -Not -Contain $true
        }

        It 'Should have CollectionUri parameter with default value' {
            # Arrange
            $command = Get-Command Get-AdoRepository

            # Act
            $collectionUriParam = $command.Parameters['CollectionUri']

            # Assert
            $collectionUriParam | Should -Not -BeNullOrEmpty
            $collectionUriParam.Attributes.Mandatory | Should -Not -Contain $true
        }

        It 'Should support Name parameter with multiple aliases' {
            # Arrange
            $command = Get-Command Get-AdoRepository
            $nameParam = $command.Parameters['Name']

            # Act & Assert
            $nameParam.Aliases | Should -Contain 'Repository'
            $nameParam.Aliases | Should -Contain 'RepositoryId'
            $nameParam.Aliases | Should -Contain 'RepositoryName'
        }

        It 'Should accept valid API versions' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'

            # Act
            $result = Get-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Version '7.2-preview.2'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.2'
            }
        }

        It 'Should have IncludeLinks as a switch parameter' {
            # Arrange
            $command = Get-Command Get-AdoRepository

            # Act
            $includeLinksparam = $command.Parameters['IncludeLinks']

            # Assert
            $includeLinksparam.SwitchParameter | Should -Be $true
        }

        It 'Should have IncludeHidden as a switch parameter' {
            # Arrange
            $command = Get-Command Get-AdoRepository

            # Act
            $includeHiddenparam = $command.Parameters['IncludeHidden']

            # Assert
            $includeHiddenparam.SwitchParameter | Should -Be $true
        }

        It 'Should have IncludeAllUrls as a switch parameter' {
            # Arrange
            $command = Get-Command Get-AdoRepository

            # Act
            $includeAllUrlsparam = $command.Parameters['IncludeAllUrls']

            # Assert
            $includeAllUrlsparam.SwitchParameter | Should -Be $true
        }
    }

    Context 'Error handling' {
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
            { Get-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -WarningAction SilentlyContinue } | Should -Not -Throw

            # Verify the warning was issued (we can't directly test for Write-Warning, but the function should not throw)
        }

        It 'Should throw on other errors' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'TestRepo'

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
            { Get-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName } | Should -Throw
        }
    }

    Context 'Output validation' {
        It 'Should return PSCustomObject with expected properties' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'TestRepo'

            # Act
            $result = Get-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.PSObject.Properties.Name | Should -Contain 'id'
            $result.PSObject.Properties.Name | Should -Contain 'name'
            $result.PSObject.Properties.Name | Should -Contain 'project'
            $result.PSObject.Properties.Name | Should -Contain 'defaultBranch'
            $result.PSObject.Properties.Name | Should -Contain 'url'
            $result.PSObject.Properties.Name | Should -Contain 'remoteUrl'
            $result.PSObject.Properties.Name | Should -Contain 'projectName'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should return array of repositories when listing all' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'

            # Act
            $result = Get-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.Count | Should -BeGreaterThan 0
        }

        It 'Should return single repository when querying by name' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'SingleRepo'

            # Act
            $result = Get-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            # Single object should not have a Count property or Count should be null
            $result.name | Should -Be $repoName
        }
    }

    Context 'Integration scenarios' {
        It 'Should work with ShouldProcess in WhatIf mode' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'

            # Act
            $result = Get-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -WhatIf

            # Assert
            # In WhatIf mode, the function should not call Invoke-AdoRestMethod but should still process
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should handle multiple repositories from pipeline efficiently' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoNames = 1..5 | ForEach-Object { "Repo$_" }

            # Act
            $result = $repoNames | Get-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result.Count | Should -Be 5
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 5
        }

        It 'Should support different parameter set for list vs specific repository' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'

            # Act - List parameter set
            $listResult = Get-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -IncludeLinks

            # Act - ByNameOrId parameter set
            $specificResult = Get-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name 'SpecificRepo'

            # Assert
            $listResult.Count | Should -Be 3
            $specificResult.name | Should -Be 'SpecificRepo'
        }
    }
}
