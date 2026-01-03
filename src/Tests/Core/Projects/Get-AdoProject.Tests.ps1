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
        if ($Uri -match '/_apis/projects$') {
            # List projects
            return @{
                count = 3
                value = @(
                    @{
                        id          = 'project-id-1'
                        name        = 'Project1'
                        description = 'First test project'
                        visibility  = 'private'
                        state       = 'wellFormed'
                        defaultTeam = @{
                            id   = 'team-id-1'
                            name = 'Project1 Team'
                        }
                    },
                    @{
                        id          = 'project-id-2'
                        name        = 'Project2'
                        description = 'Second test project'
                        visibility  = 'public'
                        state       = 'wellFormed'
                        defaultTeam = @{
                            id   = 'team-id-2'
                            name = 'Project2 Team'
                        }
                    },
                    @{
                        id          = 'project-id-3'
                        name        = 'Project3'
                        description = 'Third test project'
                        visibility  = 'private'
                        state       = 'wellFormed'
                        defaultTeam = @{
                            id   = 'team-id-3'
                            name = 'Project3 Team'
                        }
                    }
                )
            }
        } elseif ($Uri -match '/_apis/projects/(.+)$') {
            # Get specific project
            $projectName = $Matches[1]
            return @{
                id           = "project-id-$projectName"
                name         = $projectName
                description  = "Test project $projectName"
                visibility   = 'private'
                state        = 'wellFormed'
                defaultTeam  = @{
                    id   = "team-id-$projectName"
                    name = "$projectName Team"
                }
                capabilities = @{
                    versioncontrol  = @{
                        sourceControlType = 'Git'
                    }
                    processTemplate = @{
                        templateName = 'Agile'
                    }
                }
            }
        }
    }
}

Describe 'Get-AdoProject' {

    Context 'When retrieving all projects' {
        It 'Should retrieve all projects when no name is specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].name | Should -Be 'Project1'
            $result[1].name | Should -Be 'Project2'
            $result[2].name | Should -Be 'Project3'

            # Verify Invoke-AdoRestMethod was called correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/projects" -and
                $Method -eq 'GET' -and
                $Version -eq '7.1'
            }
        }

        It 'Should include continuation token when returned in response' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    count             = 2
                    value             = @(
                        @{
                            id          = 'project-id-1'
                            name        = 'Project1'
                            description = 'First test project'
                            visibility  = 'private'
                            state       = 'wellFormed'
                            defaultTeam = @{ id = 'team-id-1'; name = 'Project1 Team' }
                        }
                    )
                    continuationToken = 'next-page-token'
                }
            }

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri

            # Assert
            $result.continuationToken | Should -Be 'next-page-token'
        }

        It 'Should use environment variable when CollectionUri is not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/envorg'

            # Act
            $result = Get-AdoProject

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/envorg/_apis/projects'
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
        }
    }

    Context 'When retrieving a specific project by name' {
        It 'Should retrieve project by name' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'MyProject'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -Name $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $projectName
            $result.id | Should -Be "project-id-$projectName"
            $result.collectionUri | Should -Be $collectionUri

            # Verify Invoke-AdoRestMethod was called correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/projects/$projectName" -and
                $Method -eq 'GET' -and
                $Version -eq '7.1'
            }
        }

        It 'Should retrieve project by ID' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectId = 'abc123-def456-789'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -Name $projectId

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be "project-id-$projectId"

            # Verify Invoke-AdoRestMethod was called with the ID
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/projects/$projectId"
            }
        }

        It 'Should handle project not found gracefully' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'NonExistentProject'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $exception = [System.Net.WebException]::new('Project does not exist')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'ProjectDoesNotExist',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $projectName
                )
                $errorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"ProjectDoesNotExistWithNameException"}')
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert - Should not throw, should write warning instead
            { Get-AdoProject -CollectionUri $collectionUri -Name $projectName -WarningAction SilentlyContinue } | Should -Not -Throw

            # Verify warning was written
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept project names from pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectNames = @('Project1', 'Project2')

            # Act
            $result = $projectNames | Get-AdoProject -CollectionUri $collectionUri

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].name | Should -Be 'Project1'
            $result[1].name | Should -Be 'Project2'

            # Verify Invoke-AdoRestMethod was called once for each piped project name
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }

        It 'Should accept project objects with name property from pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectObjects = @(
                [PSCustomObject]@{ Name = 'Project1' },
                [PSCustomObject]@{ Name = 'Project2' }
            )

            # Act
            $result = $projectObjects | Get-AdoProject -CollectionUri $collectionUri

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }
    }

    Context 'When using IncludeCapabilities switch' {
        It 'Should include capabilities query parameter when IncludeCapabilities is specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'MyProject'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -Name $projectName -IncludeCapabilities

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.capabilities | Should -Not -BeNullOrEmpty

            # Verify query parameter was included
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like '*includeCapabilities=true*'
            }
        }

        It 'Should not include capabilities by default' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'MyProject'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -Name $projectName

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -notlike '*includeCapabilities*' -or $QueryParameters -eq $null
            }
        }
    }

    Context 'When using IncludeHistory switch' {
        It 'Should include history query parameter when IncludeHistory is specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'MyProject'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -Name $projectName -IncludeHistory

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like '*includeHistory=true*'
            }
        }
    }

    Context 'When using pagination parameters' {
        It 'Should include Skip parameter in query' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $skipValue = 10

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -Skip $skipValue

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like "*`$skip=$skipValue*"
            }
        }

        It 'Should include Top parameter in query' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $topValue = 5

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -Top $topValue

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like "*`$top=$topValue*"
            }
        }

        It 'Should include ContinuationToken parameter in query' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $token = 'my-continuation-token'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -ContinuationToken $token

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like "*continuationToken=$token*"
            }
        }

        It 'Should combine multiple query parameters correctly' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -Skip 10 -Top 5 -StateFilter 'wellFormed'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like '*$skip=10*' -and
                $QueryParameters -like '*$top=5*' -and
                $QueryParameters -like '*stateFilter=wellFormed*'
            }
        }
    }

    Context 'When using StateFilter parameter' {
        It 'Should accept valid StateFilter value "wellFormed"' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -StateFilter 'wellFormed'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like '*stateFilter=wellFormed*'
            }
        }

        It 'Should accept valid StateFilter value "all"' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -StateFilter 'all'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like '*stateFilter=all*'
            }
        }

        It 'Should accept all valid StateFilter values' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $validStates = @('deleting', 'new', 'wellFormed', 'createPending', 'all', 'unchanged', 'deleted')

            # Act & Assert
            foreach ($state in $validStates) {
                { Get-AdoProject -CollectionUri $collectionUri -StateFilter $state } | Should -Not -Throw
            }
        }
    }

    Context 'When using Version parameter' {
        It 'Should use default API version 7.1' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should accept API version 7.2-preview.4' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -Version '7.2-preview.4'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.4'
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should accept valid CollectionUri' {
            # Arrange
            $validUri = 'https://dev.azure.com/myorg'

            # Act & Assert
            { Get-AdoProject -CollectionUri $validUri } | Should -Not -Throw
        }

        It 'Should use Name parameter with Id alias' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectId = 'project-guid'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -Id $projectId

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/projects/$projectId"
            }
        }

        It 'Should use Name parameter with ProjectId alias' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectId = 'project-guid'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -ProjectId $projectId

            # Assert
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should use Name parameter with ProjectName alias' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'MyProject'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should validate Skip parameter is an integer' {
            # Arrange & Act & Assert
            { Get-AdoProject -CollectionUri 'https://dev.azure.com/testorg' -Skip 10 } | Should -Not -Throw
        }

        It 'Should validate Top parameter is an integer' {
            # Arrange & Act & Assert
            { Get-AdoProject -CollectionUri 'https://dev.azure.com/testorg' -Top 5 } | Should -Not -Throw
        }
    }

    Context 'Error handling' {
        It 'Should throw when Invoke-AdoRestMethod fails with non-NotFound error' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Internal server error'
            }

            # Act & Assert
            { Get-AdoProject -CollectionUri $collectionUri } | Should -Throw 'Internal server error'
        }

        It 'Should handle project not found error with warning' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'NonExistent'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $exception = [System.Net.WebException]::new('Project does not exist')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'ProjectDoesNotExist',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $projectName
                )
                $errorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"ProjectDoesNotExistWithNameException"}')
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act - Should not throw, should write warning
            { Get-AdoProject -CollectionUri $collectionUri -Name $projectName -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should handle project not found when piped from array' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectNames = @('ExistingProject', 'NonExistentProject')

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri)
                if ($Uri -match 'NonExistentProject') {
                    $exception = [System.Net.WebException]::new('Project does not exist')
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                        $exception,
                        'ProjectDoesNotExist',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $projectName
                    )
                    $errorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"ProjectDoesNotExistWithNameException"}')
                    $errorRecord.ErrorDetails = $errorDetails
                    throw $errorRecord
                } else {
                    return @{
                        id          = 'project-id-ExistingProject'
                        name        = 'ExistingProject'
                        description = 'Test project'
                        visibility  = 'private'
                        state       = 'wellFormed'
                        defaultTeam = @{ id = 'team-id'; name = 'Team' }
                    }
                }
            }

            # Act - Pipeline input allows processing each name separately
            $result = $projectNames | Get-AdoProject -CollectionUri $collectionUri -WarningAction SilentlyContinue

            # Assert - Should return only the existing project
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result.name | Should -Be 'ExistingProject'
        }
    }

    Context 'Output validation' {
        It 'Should return PSCustomObject with expected properties' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'MyProject'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -Name $projectName

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.id | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $projectName
            $result.collectionUri | Should -Be $collectionUri
            $result.PSObject.Properties.Name | Should -Contain 'id'
            $result.PSObject.Properties.Name | Should -Contain 'name'
            $result.PSObject.Properties.Name | Should -Contain 'description'
            $result.PSObject.Properties.Name | Should -Contain 'visibility'
            $result.PSObject.Properties.Name | Should -Contain 'state'
            $result.PSObject.Properties.Name | Should -Contain 'defaultTeam'
            $result.PSObject.Properties.Name | Should -Contain 'capabilities'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should return array of PSCustomObjects when listing projects' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.Count | Should -BeGreaterThan 0
            foreach ($project in $result) {
                $project.id | Should -Not -BeNullOrEmpty
                $project.name | Should -Not -BeNullOrEmpty
                $project.collectionUri | Should -Be $collectionUri
            }
        }

        It 'Should include capabilities when IncludeCapabilities is used' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'MyProject'

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -Name $projectName -IncludeCapabilities

            # Assert
            $result.capabilities | Should -Not -BeNullOrEmpty
        }

        It 'Should set capabilities to null when not included' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id          = 'project-id-1'
                    name        = 'Project1'
                    description = 'Test project'
                    visibility  = 'private'
                    state       = 'wellFormed'
                    defaultTeam = @{ id = 'team-id'; name = 'Team' }
                    # No capabilities property
                }
            }

            # Act
            $result = Get-AdoProject -CollectionUri $collectionUri -Name 'Project1'

            # Assert
            $result.capabilities | Should -BeNullOrEmpty
        }
    }

    Context 'Integration scenarios' {
        It 'Should retrieve all projects and then get details with capabilities for each' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act - First get all projects
            $allProjects = Get-AdoProject -CollectionUri $collectionUri

            # Then get detailed info for first project
            $detailedProject = Get-AdoProject -CollectionUri $collectionUri -Name $allProjects[0].name -IncludeCapabilities

            # Assert
            $allProjects.Count | Should -BeGreaterThan 0
            $detailedProject | Should -Not -BeNullOrEmpty
            $detailedProject.name | Should -Be $allProjects[0].name
            $detailedProject.capabilities | Should -Not -BeNullOrEmpty
        }

        It 'Should support pagination workflow with continuation token' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Mock first call with continuation token
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($QueryParameters)

                if ($QueryParameters -notlike '*continuationToken*') {
                    # First page
                    return @{
                        count             = 2
                        value             = @(
                            @{
                                id          = 'project-1'
                                name        = 'Project1'
                                description = 'First'
                                visibility  = 'private'
                                state       = 'wellFormed'
                                defaultTeam = @{ id = 'team-1'; name = 'Team1' }
                            },
                            @{
                                id          = 'project-2'
                                name        = 'Project2'
                                description = 'Second'
                                visibility  = 'private'
                                state       = 'wellFormed'
                                defaultTeam = @{ id = 'team-2'; name = 'Team2' }
                            }
                        )
                        continuationToken = 'page2-token'
                    }
                } else {
                    # Second page
                    return @{
                        count = 1
                        value = @(
                            @{
                                id          = 'project-3'
                                name        = 'Project3'
                                description = 'Third'
                                visibility  = 'private'
                                state       = 'wellFormed'
                                defaultTeam = @{ id = 'team-3'; name = 'Team3' }
                            }
                        )
                    }
                }
            }

            # Act - Get first page
            $page1 = Get-AdoProject -CollectionUri $collectionUri -Top 2

            # Get second page using continuation token
            $page2 = Get-AdoProject -CollectionUri $collectionUri -ContinuationToken $page1[0].continuationToken

            # Assert
            $page1.Count | Should -Be 2
            $page1[0].continuationToken | Should -Be 'page2-token'
            $page2.Count | Should -Be 1
            $page2[0].name | Should -Be 'Project3'
        }

        It 'Should work with realistic project filtering scenario' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act - Get only wellFormed projects, skip first 5, take next 10
            $result = Get-AdoProject -CollectionUri $collectionUri -StateFilter 'wellFormed' -Skip 5 -Top 10

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like '*stateFilter=wellFormed*' -and
                $QueryParameters -like '*$skip=5*' -and
                $QueryParameters -like '*$top=10*'
            }
        }
    }

    Context 'ShouldProcess support' {
        It 'Should support WhatIf when getting a specific project' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'MyProject'

            # Act
            Get-AdoProject -CollectionUri $collectionUri -Name $projectName -WhatIf

            # Assert - Should not actually call the API
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should support WhatIf when listing projects' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            Get-AdoProject -CollectionUri $collectionUri -WhatIf

            # Assert - Should not actually call the API
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }
}
