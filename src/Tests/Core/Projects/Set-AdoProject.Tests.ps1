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
}

Describe 'Set-AdoProject' {

    Context 'When updating individual properties' {
        BeforeAll {
            # Mock Invoke-AdoRestMethod for successful responses
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri, $Method, $Version, $Body)

                if ($Method -eq 'PATCH') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                        url    = "$Uri/operations/operation-id-123"
                    }
                } elseif ($Method -eq 'GET') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                    }
                }
            }

            # Mock Get-AdoProject for retrieving updated project details
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                param($CollectionUri, $Name, $Id, $IncludeCapabilities)

                return @{
                    id            = if ($Id) { $Id } else { $Name }
                    name          = "updated-$(if ($Id) { $Id } else { $Name })"
                    description   = 'Updated description'
                    visibility    = 'Private'
                    state         = 'wellFormed'
                    defaultTeam   = @{
                        id   = "team-id-$(if ($Id) { $Id } else { $Name })"
                        name = "$(if ($Id) { $Id } else { $Name }) Team"
                    }
                    capabilities  = @{
                        versioncontrol  = @{
                            sourceControlType = 'Git'
                        }
                        processTemplate = @{
                            templateName = 'Agile'
                        }
                    }
                    collectionUri = $CollectionUri
                }
            }
        }

        It 'Should update project <Property>' -ForEach @(
            @{ Property = 'Name'; ParameterValue = 'renamed-project'; BodyProperty = 'name' }
            @{ Property = 'Description'; ParameterValue = 'Updated description'; BodyProperty = 'description' }
            @{ Property = 'Visibility'; ParameterValue = 'Public'; BodyProperty = 'visibility' }
        ) {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectId = 'my-project-1'

            # Act
            $params = @{
                CollectionUri = $collectionUri
                Id            = $projectId
                $Property     = $ParameterValue
                Confirm       = $false
            }
            $result = Set-AdoProject @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.collectionUri | Should -Be $collectionUri

            # Verify PATCH was called with correct property
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/projects/$projectId" -and
                $Method -eq 'PATCH' -and
                $Body.$BodyProperty -eq $ParameterValue
            }

            # Verify Get-AdoProject was called to retrieve updated details
            # Note: Called twice - once for name resolution (since not a GUID), once for updated details
            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 2
        }

        It 'Should update multiple properties together' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectId = 'my-project-1'

            # Act
            $result = Set-AdoProject -CollectionUri $collectionUri -Id $projectId -Name 'renamed' -Description 'New desc' -Visibility 'Public' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty

            # Verify PATCH was called with all properties
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Body.name -eq 'renamed' -and
                $Body.description -eq 'New desc' -and
                $Body.visibility -eq 'Public'
            }
        }
    }

    Context 'When updating multiple projects' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri, $Method, $Version, $Body)

                if ($Method -eq 'PATCH') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                        url    = "$Uri/operations/operation-id-123"
                    }
                } elseif ($Method -eq 'GET') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                    }
                }
            }

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                param($CollectionUri, $Name, $Id, $IncludeCapabilities)

                return @{
                    id            = if ($Id) { $Id } else { $Name }
                    name          = "updated-$(if ($Id) { $Id } else { $Name })"
                    description   = 'Updated description'
                    visibility    = 'Private'
                    state         = 'wellFormed'
                    defaultTeam   = @{ id = 'team-id'; name = 'Team' }
                    collectionUri = $CollectionUri
                }
            }
        }

        It 'Should update multiple projects by ID array' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectIds = @('project-1', 'project-2', 'project-3')

            # Act
            $result = $projectIds | Set-AdoProject -CollectionUri $collectionUri -Description 'Batch updated' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3

            # Verify PATCH was called for each project
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3 -ParameterFilter {
                $Method -eq 'PATCH' -and
                $Body.description -eq 'Batch updated'
            }
        }

        It 'Should update multiple projects via pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projects = @(
                [PSCustomObject]@{ Id = 'project-1'; Description = 'Description 1' },
                [PSCustomObject]@{ Id = 'project-2'; Description = 'Description 2' }
            )

            # Act
            $result = $projects | Set-AdoProject -CollectionUri $collectionUri -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2

            # Verify PATCH was called for each
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2 -ParameterFilter {
                $Method -eq 'PATCH'
            }
        }
    }

    Context 'When operation requires polling' {
        BeforeAll {
            # Override mock for polling scenarios
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Method)

                if ($Method -eq 'PATCH') {
                    return @{
                        id     = 'operation-id-456'
                        status = 'inProgress'
                        url    = 'https://dev.azure.com/testorg/_apis/operations/operation-id-456'
                    }
                } elseif ($Method -eq 'GET') {
                    return @{
                        id     = 'operation-id-456'
                        status = 'succeeded'
                    }
                }
            }

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                param($CollectionUri, $Name, $Id, $IncludeCapabilities)

                return @{
                    id            = if ($Id) { $Id } else { $Name }
                    name          = "updated-$(if ($Id) { $Id } else { $Name })"
                    description   = 'Updated description'
                    visibility    = 'Private'
                    state         = 'wellFormed'
                    defaultTeam   = @{ id = 'team-id'; name = 'Team' }
                    collectionUri = $CollectionUri
                }
            }
        }

        It 'Should poll for operation completion' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = Set-AdoProject -CollectionUri $collectionUri -Id 'my-project-1' -Name 'updated-project' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty

            # Verify polling occurred
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -ParameterFilter {
                $Method -eq 'GET'
            }
        }
    }

    Context 'When resolving project name to ID' {
        It 'Should resolve project name to ID before updating' {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri, $Method, $Version, $Body)

                if ($Method -eq 'PATCH') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                        url    = "$Uri/operations/operation-id-123"
                    }
                } elseif ($Method -eq 'GET') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                    }
                }
            }

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                param($Name, $CollectionUri, $Id, $IncludeCapabilities)

                if ($Name -eq 'my-project-name') {
                    return @{
                        id            = 'resolved-project-id-123'
                        name          = 'my-project-name'
                        description   = 'Test project'
                        visibility    = 'Private'
                        state         = 'wellFormed'
                        defaultTeam   = @{ id = 'team-id'; name = 'Team' }
                        collectionUri = $CollectionUri
                    }
                } elseif ($Id -eq 'resolved-project-id-123') {
                    return @{
                        id            = 'resolved-project-id-123'
                        name          = 'updated-name'
                        description   = 'Test project'
                        visibility    = 'Private'
                        state         = 'wellFormed'
                        defaultTeam   = @{ id = 'team-id'; name = 'Team' }
                        collectionUri = $CollectionUri
                    }
                } else {
                    return $null
                }
            }

            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'my-project-name'

            # Act
            $result = Set-AdoProject -CollectionUri $collectionUri -Id $projectName -Name 'updated-name' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty

            # Verify Get-AdoProject was called twice: once for name resolution, once for updated details
            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 2

            # Verify PATCH was called with resolved ID
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/projects/resolved-project-id-123" -and
                $Method -eq 'PATCH'
            }
        }

        It 'Should use ID directly when valid GUID is provided' {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri, $Method, $Version, $Body)

                if ($Method -eq 'PATCH') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                        url    = "$Uri/operations/operation-id-123"
                    }
                } elseif ($Method -eq 'GET') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                    }
                }
            }

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                param($CollectionUri, $Name, $Id, $IncludeCapabilities)

                # Should only be called once to get updated details, not for name resolution
                return @{
                    id            = '12345678-1234-1234-1234-123456789012'
                    name          = 'updated'
                    description   = 'Test project'
                    visibility    = 'Private'
                    state         = 'wellFormed'
                    defaultTeam   = @{ id = 'team-id'; name = 'Team' }
                    collectionUri = $CollectionUri
                }
            }

            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectId = '12345678-1234-1234-1234-123456789012'

            # Act
            $result = Set-AdoProject -CollectionUri $collectionUri -Id $projectId -Name 'updated' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty

            # Verify Get-AdoProject was called only once (for updated details, not for name resolution)
            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 1

            # Verify PATCH was called with provided GUID
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/projects/$projectId" -and
                $Method -eq 'PATCH'
            }
        }

        It 'Should skip project when name cannot be resolved' {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Invoke-AdoRestMethod should not be called when name is not resolved'
            }

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return $null
            }

            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'non-existent-name'

            # Act
            $result = Set-AdoProject -CollectionUri $collectionUri -Id $projectName -Name 'updated' -Confirm:$false

            # Assert - Should not throw, but also should not return result
            $result | Should -BeNullOrEmpty

            # Verify Get-AdoProject was called
            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 1

            # Verify PATCH was NOT called
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0 -ParameterFilter {
                $Method -eq 'PATCH'
            }
        }
    }

    Context 'When using environment variable for CollectionUri' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri, $Method, $Version, $Body)

                if ($Method -eq 'PATCH') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                        url    = "$Uri/operations/operation-id-123"
                    }
                } elseif ($Method -eq 'GET') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                    }
                }
            }

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                param($CollectionUri, $Name, $Id, $IncludeCapabilities)

                return @{
                    id            = if ($Id) { $Id } else { $Name }
                    name          = "updated-$(if ($Id) { $Id } else { $Name })"
                    description   = 'Updated description'
                    visibility    = 'Private'
                    state         = 'wellFormed'
                    defaultTeam   = @{ id = 'team-id'; name = 'Team' }
                    collectionUri = $CollectionUri
                }
            }
        }

        It 'Should use environment variable when CollectionUri is not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/envorg'
            $projectId = 'my-project-1'

            # Act
            $result = Set-AdoProject -Id $projectId -Name 'updated-project' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty

            # Verify correct URI was used
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/envorg/_apis/projects/my-project-1'
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
        }
    }

    Context 'When using different API versions' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri, $Method, $Version, $Body)

                if ($Method -eq 'PATCH') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                        url    = "$Uri/operations/operation-id-123"
                    }
                } elseif ($Method -eq 'GET') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                    }
                }
            }

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                param($CollectionUri, $Name, $Id, $IncludeCapabilities)

                return @{
                    id            = if ($Id) { $Id } else { $Name }
                    name          = "updated-$(if ($Id) { $Id } else { $Name })"
                    description   = 'Updated description'
                    visibility    = 'Private'
                    state         = 'wellFormed'
                    defaultTeam   = @{ id = 'team-id'; name = 'Team' }
                    collectionUri = $CollectionUri
                }
            }
        }

        It 'Should accept API version <Version>' -ForEach @(
            @{ Version = '7.1' }
            @{ Version = '7.2-preview.4' }
        ) {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = Set-AdoProject -CollectionUri $collectionUri -Id 'my-project-1' -Name 'updated' -Version $Version -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq $Version -and $Method -eq 'PATCH'
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should have Id as a mandatory parameter' {
            # Arrange
            $command = Get-Command Set-AdoProject

            # Act
            $idParam = $command.Parameters['Id']

            # Assert
            $idParam.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should accept <Property> parameter from pipeline by property name' -ForEach @(
            @{ Property = 'Name'; Value = 'new-name'; BodyProperty = 'name' }
            @{ Property = 'Description'; Value = 'Pipeline description'; BodyProperty = 'description' }
            @{ Property = 'Visibility'; Value = 'Public'; BodyProperty = 'visibility' }
        ) {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri, $Method, $Version, $Body)

                if ($Method -eq 'PATCH') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                        url    = "$Uri/operations/operation-id-123"
                    }
                } elseif ($Method -eq 'GET') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                    }
                }
            }

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return @{
                    id            = 'my-project-1'
                    name          = 'updated-my-project'
                    description   = 'Updated'
                    visibility    = 'Private'
                    state         = 'wellFormed'
                    defaultTeam   = @{ id = 'team-id'; name = 'Team' }
                    collectionUri = 'https://dev.azure.com/testorg'
                }
            }

            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectInput = [PSCustomObject]@{
                Id        = 'my-project-1'
                $Property = $Value
            }

            # Act
            $result = $projectInput | Set-AdoProject -CollectionUri $collectionUri -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Body.$BodyProperty -eq $Value
            }
        }

        It 'Should validate Visibility parameter accepts only Private or Public' {
            # Arrange
            $command = Get-Command Set-AdoProject
            $visibilityParam = $command.Parameters['Visibility']

            # Act
            $validateSet = $visibilityParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            # Assert
            $validateSet.ValidValues | Should -Contain 'Private'
            $validateSet.ValidValues | Should -Contain 'Public'
            $validateSet.ValidValues.Count | Should -Be 2
        }

        It 'Should accept string for Id parameter' {
            # Arrange
            $command = Get-Command Set-AdoProject
            $idParam = $command.Parameters['Id']

            # Assert
            $idParam.ParameterType.Name | Should -Be 'String'
        }

        It 'Should have <Parameter> as an optional parameter' -ForEach @(
            @{ Parameter = 'Name' }
            @{ Parameter = 'Description' }
            @{ Parameter = 'Visibility' }
        ) {
            # Arrange
            $command = Get-Command Set-AdoProject
            $param = $command.Parameters[$Parameter]

            # Assert
            $param.Attributes.Mandatory | Should -Not -Contain $true
        }
    }

    Context 'Error handling' {
        BeforeAll {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Start-Sleep -ModuleName $moduleName -MockWith { }
        }

        It 'Should throw when operation fails' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id     = 'operation-id-789'
                    status = 'failed'
                }
            }

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return @{
                    id            = 'my-project-1'
                    name          = 'updated'
                    description   = 'Test'
                    visibility    = 'Private'
                    state         = 'wellFormed'
                    defaultTeam   = @{ id = 'team-id'; name = 'Team' }
                    collectionUri = $collectionUri
                }
            }

            # Act & Assert
            { Set-AdoProject -CollectionUri $collectionUri -Id 'my-project-1' -Name 'updated' -Confirm:$false } | Should -Throw 'Project update failed.'
        }

        It 'Should handle project not found error' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $exception = [System.Net.WebException]::new('Project does not exist')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'NotFoundException',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    'non-existent-project'
                )
                $errorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"ProjectDoesNotExistWithNameException: The project does not exist."}')
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act - Should write warning and not throw
            { Set-AdoProject -CollectionUri $collectionUri -Id 'non-existent-project' -Name 'updated' -Confirm:$false -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should handle multiple projects with some not found' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectIds = @('existing-project', 'non-existent-project', 'another-existing')

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri)

                if ($Uri -match 'non-existent-project') {
                    $exception = [System.Net.WebException]::new('Project does not exist')
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                        $exception,
                        'NotFoundException',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        'non-existent-project'
                    )
                    $errorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"ProjectDoesNotExistWithNameException: The project does not exist."}')
                    $errorRecord.ErrorDetails = $errorDetails
                    throw $errorRecord
                }

                return @{
                    id     = 'operation-id'
                    status = 'succeeded'
                }
            }

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                param($CollectionUri, $Id)
                return @{
                    id            = $Id
                    name          = 'updated'
                    description   = 'Test description'
                    visibility    = 'Private'
                    state         = 'wellFormed'
                    defaultTeam   = @{ id = 'team-id'; name = 'Team' }
                    collectionUri = $CollectionUri
                }
            }

            # Act
            $result = $projectIds | Set-AdoProject -CollectionUri $collectionUri -Name 'updated' -Confirm:$false -WarningAction SilentlyContinue

            # Assert - Should return 2 projects (non-existent one skipped)
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }

        It 'Should throw when Invoke-AdoRestMethod fails with non-NotFound error' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Internal server error'
            }

            # Act & Assert
            { Set-AdoProject -CollectionUri $collectionUri -Id 'my-project-1' -Name 'updated' -Confirm:$false } | Should -Throw
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri, $Method, $Version, $Body)

                if ($Method -eq 'PATCH') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                        url    = "$Uri/operations/operation-id-123"
                    }
                } elseif ($Method -eq 'GET') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                    }
                }
            }

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                param($CollectionUri, $Name, $Id, $IncludeCapabilities)

                return @{
                    id            = if ($Id) { $Id } else { $Name }
                    name          = "updated-$(if ($Id) { $Id } else { $Name })"
                    description   = 'Updated description'
                    visibility    = 'Private'
                    state         = 'wellFormed'
                    defaultTeam   = @{ id = 'team-id'; name = 'Team' }
                    collectionUri = $CollectionUri
                }
            }
        }

        It 'Should return PSCustomObject with expected properties' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectId = 'my-project-1'

            # Act
            $result = Set-AdoProject -CollectionUri $collectionUri -Id $projectId -Name 'updated' -Confirm:$false

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

        It 'Should return array of PSCustomObjects when updating multiple projects' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectIds = @('project-1', 'project-2')

            # Act
            $result = $projectIds | Set-AdoProject -CollectionUri $collectionUri -Name 'updated' -Confirm:$false

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.Count | Should -Be 2
            foreach ($project in $result) {
                $project.id | Should -Not -BeNullOrEmpty
                $project.name | Should -Not -BeNullOrEmpty
                $project.collectionUri | Should -Be $collectionUri
            }
        }
    }

    Context 'ShouldProcess support' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri, $Method, $Version, $Body)

                if ($Method -eq 'PATCH') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                        url    = "$Uri/operations/operation-id-123"
                    }
                } elseif ($Method -eq 'GET') {
                    return @{
                        id     = 'operation-id-123'
                        status = 'succeeded'
                    }
                }
            }

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return @{
                    id            = 'my-project-1'
                    name          = 'updated-my-project'
                    description   = 'Updated'
                    visibility    = 'Private'
                    state         = 'wellFormed'
                    defaultTeam   = @{ id = 'team-id'; name = 'Team' }
                    collectionUri = 'https://dev.azure.com/testorg'
                }
            }
        }

        It 'Should support WhatIf when updating a project' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            Set-AdoProject -CollectionUri $collectionUri -Id 'my-project-1' -Name 'updated' -WhatIf

            # Assert - Should not actually call the API
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0 -ParameterFilter {
                $Method -eq 'PATCH'
            }
        }

        It 'Should support Confirm:$false to bypass confirmation' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = Set-AdoProject -CollectionUri $collectionUri -Id 'my-project-1' -Name 'updated' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty

            # Verify API was called
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Method -eq 'PATCH'
            }
        }

        It 'Should have ConfirmImpact set to High' {
            # Arrange
            $command = Get-Command Set-AdoProject

            # Act
            $confirmImpact = $command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }

            # Assert
            $confirmImpact.ConfirmImpact | Should -Be 'High'
        }
    }
}
