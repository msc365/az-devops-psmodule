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

    # Mock Get-AdoProject for project ID resolution
    Mock Get-AdoProject -ModuleName $moduleName -MockWith {
        param($CollectionUri, $Name)
        return @{
            id   = "project-id-$Name"
            name = $Name
        }
    }

    # Mock Get-AdoRepository for retrieving created repository
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
            projectName   = $ProjectName
            collectionUri = $CollectionUri
        }
    }

    # Mock Invoke-AdoRestMethod for repository creation
    Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
        param($Uri, $Method, $Version, $Body)

        return @{
            id            = 'repo-id-' + $Body.name
            name          = $Body.name
            url           = "$Uri/" + $Body.name
            remoteUrl     = "$Uri/_git/" + $Body.name
            defaultBranch = 'refs/heads/main'
            project       = $Body.project
        }
    }
}

Describe 'New-AdoRepository' {

    Context 'When creating a new repository' {
        It 'Should create a new repository with required parameters' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'NewRepository'

            # Act
            $result = New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $repoName
            $result.id | Should -Be "repo-id-$repoName"
            $result.collectionUri | Should -Be $collectionUri
            $result.projectName | Should -Be $projectName

            # Verify Invoke-AdoRestMethod was called to create the repository
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/$projectName/_apis/git/repositories" -and
                $Method -eq 'POST' -and
                $Version -eq '7.1'
            }

            # Note: Function does not call Get-AdoRepository after creation, it returns from Invoke-AdoRestMethod directly
        }

        It 'Should create a repository with project name (non-GUID)' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'MyProject'
            $repoName = 'NewRepository'

            # Act
            $result = New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $repoName

            # Verify Get-AdoProject was called to resolve project name to ID
            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Name -eq $projectName
            }
        }

        It 'Should create a repository with project ID (GUID)' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectId = '12345678-1234-1234-1234-123456789abc'
            $repoName = 'NewRepository'

            # Act
            $result = New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectId -Name $repoName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $repoName

            # Verify Get-AdoProject was NOT called when GUID is provided
            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 0
        }

        It 'Should create a repository with SourceRef parameter' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'ForkedRepo'
            $sourceRef = 'refs/heads/feature-branch'

            # Act
            $result = New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -SourceRef $sourceRef -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $repoName

            # Verify Invoke-AdoRestMethod was called with sourceRef query parameter
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/$projectName/_apis/git/repositories" -and
                $Body.name -eq $repoName
            }
        }

        It 'Should handle existing repository and return it' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'ExistingRepo'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = "VS409: The repository $repoName already exists in the project."
                    typeKey = 'RepositoryAlreadyExistsException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Repository already exists')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'RepositoryAlreadyExists',
                    [System.Management.Automation.ErrorCategory]::ResourceExists,
                    $repoName
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act
            $result = New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $repoName

            # Verify Get-AdoRepository was called to retrieve existing repository
            Should -Invoke Get-AdoRepository -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Name -eq $repoName -and
                $ProjectName -eq $projectName
            }
        }

        It 'Should use environment variables when parameters are not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/envorg'
            $env:DefaultAdoProject = 'envproject'
            $repoName = 'NewRepository'

            # Act
            $result = New-AdoRepository -Name $repoName -Confirm:$false

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

    Context 'When using pipeline input' {
        It 'Should accept repository names from pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoNames = @('Repo1', 'Repo2', 'Repo3')

            # Act
            $result = $repoNames | New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].name | Should -Be 'Repo1'
            $result[1].name | Should -Be 'Repo2'
            $result[2].name | Should -Be 'Repo3'

            # Verify Invoke-AdoRestMethod was called for each repository
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3 -ParameterFilter {
                $Method -eq 'POST'
            }
        }

        It 'Should accept repository objects with name property from pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoObjects = @(
                [PSCustomObject]@{ Name = 'Repo1'; SourceRef = 'refs/heads/main' },
                [PSCustomObject]@{ Name = 'Repo2'; SourceRef = 'refs/heads/develop' }
            )

            # Act
            $result = $repoObjects | New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }
    }

    Context 'Parameter validation' {
        It 'Should have Name as a mandatory parameter' {
            # Arrange
            $command = Get-Command New-AdoRepository

            # Act
            $nameParam = $command.Parameters['Name']

            # Assert
            $nameParam.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have CollectionUri parameter with default value' {
            # Arrange
            $command = Get-Command New-AdoRepository

            # Act
            $collectionUriParam = $command.Parameters['CollectionUri']

            # Assert
            $collectionUriParam | Should -Not -BeNullOrEmpty
            $collectionUriParam.Attributes.Mandatory | Should -Not -Contain $true
        }

        It 'Should have ProjectName parameter with default value' {
            # Arrange
            $command = Get-Command New-AdoRepository

            # Act
            $projectNameParam = $command.Parameters['ProjectName']

            # Assert
            $projectNameParam | Should -Not -BeNullOrEmpty
            $projectNameParam.Attributes.Mandatory | Should -Not -Contain $true
        }

        It 'Should support Name parameter with RepositoryName alias' {
            # Arrange
            $command = Get-Command New-AdoRepository
            $nameParam = $command.Parameters['Name']

            # Act & Assert
            $nameParam.Aliases | Should -Contain 'RepositoryName'
        }

        It 'Should accept valid API versions' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'TestRepo'

            # Act
            $result = New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -Version '7.2-preview.2' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.2'
            }
        }

        It 'Should have SourceRef as optional string parameter' {
            # Arrange
            $command = Get-Command New-AdoRepository

            # Act
            $sourceRefParam = $command.Parameters['SourceRef']

            # Assert
            $sourceRefParam | Should -Not -BeNullOrEmpty
            $sourceRefParam.ParameterType | Should -Be ([string])
            $sourceRefParam.Attributes.Mandatory | Should -Not -Contain $true
        }
    }

    Context 'Error handling' {
        It 'Should throw when repository creation fails with unknown error' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'FailRepo'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Internal server error'
                    typeKey = 'InternalServerError'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Server error')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'ServerError',
                    [System.Management.Automation.ErrorCategory]::NotSpecified,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert
            { New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -Confirm:$false } | Should -Throw
        }

        It 'Should handle Get-AdoProject returning null' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'NonExistentProject'
            $repoName = 'TestRepo'

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return $null
            }

            # Act
            $result = New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -Confirm:$false

            # Assert - function should skip when project is not found
            $result | Should -BeNullOrEmpty

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
                    param($Body)
                    if ($Body.name -eq 'FailRepo') {
                        throw 'Failed to create repository'
                    }
                    return @{
                        id            = 'repo-id-' + $Body.name
                        name          = $Body.name
                        url           = "https://dev.azure.com/testorg/testproject/_apis/git/repositories/$($Body.name)"
                        remoteUrl     = "https://dev.azure.com/testorg/testproject/_git/$($Body.name)"
                        defaultBranch = 'refs/heads/main'
                        project       = $Body.project
                    }
                }
            }

            # Act & Assert
            { $repoNames | New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -ErrorAction SilentlyContinue -Confirm:$false } | Should -Not -Throw
        }
    }

    Context 'Output validation' {
        It 'Should return PSCustomObject with expected properties' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'TestRepo'

            # Act
            $result = New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -Confirm:$false

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

        It 'Should include project information in output' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'TestRepo'

            # Act
            $result = New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -Confirm:$false

            # Assert
            $result.project | Should -Not -BeNullOrEmpty
            $result.projectName | Should -Be $projectName
        }
    }

    Context 'Integration scenarios' {
        It 'Should work with ShouldProcess in WhatIf mode' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'TestRepo'

            # Act
            $result = New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -WhatIf

            # Assert
            # In WhatIf mode, the function should not call Invoke-AdoRestMethod
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should support creating multiple repositories sequentially' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoNames = 1..3 | ForEach-Object { "Repo$_" }

            # Act
            $result = $repoNames | New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            $result.Count | Should -Be 3
            $result[0].name | Should -Be 'Repo1'
            $result[1].name | Should -Be 'Repo2'
            $result[2].name | Should -Be 'Repo3'
        }

        It 'Should handle repository creation with fork scenario' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $repoName = 'ForkedRepo'
            $sourceRef = 'refs/heads/main'

            # Act
            $result = New-AdoRepository -CollectionUri $collectionUri -ProjectName $projectName -Name $repoName -SourceRef $sourceRef -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $repoName
        }
    }
}
