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

    # Mock Get-AdoProcess for process template lookup
    Mock Get-AdoProcess -ModuleName $moduleName -MockWith {
        param($Name)
        return @{
            id   = 'process-template-id-' + $Name.ToLower()
            name = $Name
        }
    }

    # Mock Get-AdoProject for retrieving created project
    Mock Get-AdoProject -ModuleName $moduleName -MockWith {
        param($CollectionUri, $Name)
        return @{
            id            = "project-id-$Name"
            name          = $Name
            description   = 'Test project description'
            visibility    = 'private'
            state         = 'wellFormed'
            defaultTeam   = @{
                id   = "team-id-$Name"
                name = "$Name Team"
            }
            collectionUri = $CollectionUri
        }
    }

    # Mock Invoke-AdoRestMethod for project creation
    Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
        param($Uri, $Method, $Version, $Body)

        if ($Method -eq 'POST') {
            # Return initial creation response
            return @{
                id     = 'operation-id-123'
                status = 'succeeded'
                url    = "$Uri/operations/operation-id-123"
            }
        } elseif ($Method -eq 'GET') {
            # Return polling response
            return @{
                id     = 'operation-id-123'
                status = 'succeeded'
            }
        }
    }
}

Describe 'New-AdoProject' {

    Context 'When creating a new project' {
        It 'Should create a new project with required parameters' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'NewProject'

            # Act
            $result = New-AdoProject -CollectionUri $collectionUri -Name $projectName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $projectName
            $result.id | Should -Be "project-id-$projectName"
            $result.collectionUri | Should -Be $collectionUri

            # Verify Invoke-AdoRestMethod was called to create the project
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/projects" -and
                $Method -eq 'POST' -and
                $Version -eq '7.1'
            }

            # Verify Get-AdoProject was called to retrieve the created project
            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Name -eq $projectName
            }
        }

        It 'Should create a project with all parameters specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'NewProject'
            $description = 'My test project'
            $process = 'Scrum'
            $sourceControl = 'Git'
            $visibility = 'Public'

            # Act
            $result = New-AdoProject -CollectionUri $collectionUri -Name $projectName -Description $description -Process $process -SourceControl $sourceControl -Visibility $visibility -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $projectName
            $result.description | Should -Be 'Test project description'

            # Verify Get-AdoProcess was called with correct process
            Should -Invoke Get-AdoProcess -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Name -eq $process
            }
        }

        It 'Should use default values for optional parameters' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'NewProject'

            # Act
            $result = New-AdoProject -CollectionUri $collectionUri -Name $projectName -Confirm:$false

            # Assert
            Should -Invoke Get-AdoProcess -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Name -eq 'Agile'
            }
        }

        It 'Should handle existing project and return it' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'ExistingProject'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Method)

                if ($Method -eq 'POST') {
                    $exception = [System.Net.WebException]::new('Project already exists')
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                        $exception,
                        'ProjectAlreadyExists',
                        [System.Management.Automation.ErrorCategory]::ResourceExists,
                        $projectName
                    )
                    $errorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"ProjectAlreadyExistsException: The project ' + $projectName + ' already exists."}')
                    $errorRecord.ErrorDetails = $errorDetails
                    throw $errorRecord
                }
            }

            # Act
            $result = New-AdoProject -CollectionUri $collectionUri -Name $projectName -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $projectName

            # Verify Get-AdoProject was called to retrieve existing project
            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Name -eq $projectName
            }
        }

        It 'Should use environment variable when CollectionUri is not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/envorg'
            $projectName = 'NewProject'

            # Act
            $result = New-AdoProject -Name $projectName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/envorg/_apis/projects'
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept project names from pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectNames = @('Project1', 'Project2')

            # Act
            $result = $projectNames | New-AdoProject -CollectionUri $collectionUri -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].name | Should -Be 'Project1'
            $result[1].name | Should -Be 'Project2'

            # Verify Invoke-AdoRestMethod was called for each project
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2 -ParameterFilter {
                $Method -eq 'POST'
            }
        }

        It 'Should accept project objects with name property from pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectObjects = @(
                [PSCustomObject]@{ Name = 'Project1'; Description = 'First project' },
                [PSCustomObject]@{ Name = 'Project2'; Description = 'Second project' }
            )

            # Act
            $result = $projectObjects | New-AdoProject -CollectionUri $collectionUri -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }
    }

    Context 'Parameter validation' {
        It 'Should have Name as a mandatory parameter' {
            # Arrange
            $command = Get-Command New-AdoProject

            # Act
            $nameParam = $command.Parameters['Name']

            # Assert
            $nameParam.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should accept valid Process values' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $validProcesses = @('Agile', 'Scrum', 'CMMI', 'Basic')

            # Act & Assert
            foreach ($process in $validProcesses) {
                { New-AdoProject -CollectionUri $collectionUri -Name "Test-$process" -Process $process -Confirm:$false } | Should -Not -Throw
            }
        }

        It 'Should accept valid SourceControl values' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $validSourceControls = @('Git', 'Tfvc')

            # Act & Assert
            foreach ($sourceControl in $validSourceControls) {
                { New-AdoProject -CollectionUri $collectionUri -Name "Test-$sourceControl" -SourceControl $sourceControl -Confirm:$false } | Should -Not -Throw
            }
        }

        It 'Should accept valid Visibility values' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $validVisibilities = @('Private', 'Public')

            # Act & Assert
            foreach ($visibility in $validVisibilities) {
                { New-AdoProject -CollectionUri $collectionUri -Name "Test-$visibility" -Visibility $visibility -Confirm:$false } | Should -Not -Throw
            }
        }

        It 'Should accept valid API versions' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = New-AdoProject -CollectionUri $collectionUri -Name 'TestProject' -Version '7.2-preview.4' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.4'
            }
        }
    }

    Context 'Error handling' {
        It 'Should throw when project creation fails' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'NewProject'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Method)

                if ($Method -eq 'POST') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'inProgress'
                        url    = 'https://dev.azure.com/testorg/_apis/projects/operations/operation-id-123'
                    }
                } elseif ($Method -eq 'GET') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'failed'
                    }
                }
            }

            # Act & Assert
            { New-AdoProject -CollectionUri $collectionUri -Name $projectName -Confirm:$false } | Should -Throw 'Project creation failed.'
        }

        It 'Should throw when Invoke-AdoRestMethod fails with non-AlreadyExists error' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'NewProject'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Internal server error'
            }

            # Act & Assert
            { New-AdoProject -CollectionUri $collectionUri -Name $projectName -Confirm:$false } | Should -Throw 'Internal server error'
        }
    }

    Context 'Output validation' {
        It 'Should return PSCustomObject with expected properties' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'NewProject'

            # Act
            $result = New-AdoProject -CollectionUri $collectionUri -Name $projectName -Confirm:$false

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.PSObject.Properties.Name | Should -Contain 'id'
            $result.PSObject.Properties.Name | Should -Contain 'name'
            $result.PSObject.Properties.Name | Should -Contain 'description'
            $result.PSObject.Properties.Name | Should -Contain 'visibility'
            $result.PSObject.Properties.Name | Should -Contain 'state'
            $result.PSObject.Properties.Name | Should -Contain 'defaultTeam'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should return array of PSCustomObjects when creating multiple projects' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectNames = @('Project1', 'Project2', 'Project3')

            # Act
            $result = New-AdoProject -CollectionUri $collectionUri -Name $projectNames -Confirm:$false

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.Count | Should -Be 3
            foreach ($project in $result) {
                $project.id | Should -Not -BeNullOrEmpty
                $project.name | Should -Not -BeNullOrEmpty
                $project.collectionUri | Should -Be $collectionUri
            }
        }
    }

    Context 'ShouldProcess support' {
        It 'Should support WhatIf when creating a project' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'NewProject'

            # Act
            New-AdoProject -CollectionUri $collectionUri -Name $projectName -WhatIf

            # Assert - Should not actually call the API
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0 -ParameterFilter {
                $Method -eq 'POST'
            }
        }

        It 'Should support Confirm:$false to bypass confirmation' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'NewProject'

            # Act
            $result = New-AdoProject -CollectionUri $collectionUri -Name $projectName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty

            # Verify API was called
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Method -eq 'POST'
            }
        }
    }
}
