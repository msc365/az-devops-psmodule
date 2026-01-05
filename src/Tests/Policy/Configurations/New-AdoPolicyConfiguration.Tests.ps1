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

Describe 'New-AdoPolicyConfiguration' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $policyTypeId = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When creating a new policy configuration' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                return @{
                    id          = 10
                    type        = $Body.type
                    revision    = 1
                    isEnabled   = $Body.isEnabled
                    isBlocking  = $Body.isBlocking
                    isDeleted   = $false
                    settings    = $Body.settings
                    createdBy   = @{
                        displayName = 'User Name'
                        id          = '11111111-1111-1111-1111-111111111111'
                    }
                    createdDate = '2025-01-05T00:00:00Z'
                }
            }
        }

        It 'Should create a new policy configuration' {
            # Arrange
            $config = [PSCustomObject]@{
                isEnabled  = $true
                isBlocking = $true
                type       = @{
                    id = $policyTypeId
                }
                settings   = @{
                    minimumApproverCount        = 2
                    creatorVoteCounts           = $true
                    allowDownvotes              = $false
                    resetOnSourcePush           = $false
                    requireVoteOnLastIteration  = $false
                    resetRejectionsOnSourcePush = $false
                    blockLastPusherVote         = $false
                    requireVoteOnEachIteration  = $false
                    scope                       = @(
                        @{
                            repositoryId = $null
                            refName      = $null
                            matchKind    = 'DefaultBranch'
                        }
                    )
                }
            }

            # Act
            $result = New-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $config

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 10
            $result.isEnabled | Should -Be $true
            $result.isBlocking | Should -Be $true
            $result.revision | Should -Be 1
            $result.collectionUri | Should -Be $collectionUri
            $result.projectName | Should -Be $projectName
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/policy/configurations`$" -and
                $Method -eq 'POST'
            }
        }

        It 'Should use correct API version' {
            # Arrange
            $config = [PSCustomObject]@{
                isEnabled  = $true
                isBlocking = $true
                type       = @{ id = $policyTypeId }
                settings   = @{ minimumApproverCount = 1 }
            }

            # Act
            New-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $config -Version '7.2-preview.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should accept configuration via pipeline by property name' {
            # Arrange
            $inputObject = [PSCustomObject]@{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                Configuration = [PSCustomObject]@{
                    isEnabled  = $true
                    isBlocking = $false
                    type       = @{ id = $policyTypeId }
                    settings   = @{ minimumApproverCount = 1 }
                }
            }

            # Act
            $result = $inputObject | New-AdoPolicyConfiguration

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 10
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should create configuration with complex settings' {
            # Arrange
            $config = [PSCustomObject]@{
                isEnabled  = $true
                isBlocking = $true
                type       = @{ id = $policyTypeId }
                settings   = @{
                    minimumApproverCount        = 3
                    creatorVoteCounts           = $false
                    allowDownvotes              = $true
                    resetOnSourcePush           = $true
                    requireVoteOnLastIteration  = $true
                    resetRejectionsOnSourcePush = $true
                    blockLastPusherVote         = $true
                    requireVoteOnEachIteration  = $true
                    scope                       = @(
                        @{
                            repositoryId = '22222222-2222-2222-2222-222222222222'
                            refName      = 'refs/heads/main'
                            matchKind    = 'Exact'
                        }
                    )
                }
            }

            # Act
            $result = New-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $config

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.settings.minimumApproverCount | Should -Be 3
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Method -eq 'POST'
            }
        }
    }

    Context 'When handling errors' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'A policy configuration with the same settings already exists.'
                    typeKey = 'PolicyConfigurationAlreadyExistsException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Conflict')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'PolicyConfigurationAlreadyExistsException',
                    [System.Management.Automation.ErrorCategory]::ResourceExists,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }
        }

        It 'Should handle duplicate configuration with warning' {
            # Arrange
            $config = [PSCustomObject]@{
                isEnabled  = $true
                isBlocking = $true
                type       = @{ id = $policyTypeId }
                settings   = @{ minimumApproverCount = 1 }
            }

            # Act
            $result = New-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $config -WarningVariable warnings -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
            $warnings | Should -Not -BeNullOrEmpty
            $warnings | Should -BeLike '*already exists*'
        }
    }

    Context 'When using default parameters' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id          = 15
                    type        = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }
                    revision    = 1
                    isEnabled   = $true
                    isBlocking  = $true
                    isDeleted   = $false
                    settings    = @{ }
                    createdBy   = @{ displayName = 'User' }
                    createdDate = '2025-01-05T00:00:00Z'
                }
            }
        }

        It 'Should use default CollectionUri from environment' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'
            $config = [PSCustomObject]@{
                isEnabled  = $true
                isBlocking = $true
                type       = @{ id = $policyTypeId }
                settings   = @{ minimumApproverCount = 1 }
            }

            # Act
            $result = New-AdoPolicyConfiguration -ProjectName $projectName -Configuration $config

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match 'default-org'
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
        }

        It 'Should use default ProjectName from environment' {
            # Arrange
            $env:DefaultAdoProject = 'default-project'
            $config = [PSCustomObject]@{
                isEnabled  = $true
                isBlocking = $true
                type       = @{ id = $policyTypeId }
                settings   = @{ minimumApproverCount = 1 }
            }

            # Act
            $result = New-AdoPolicyConfiguration -CollectionUri $collectionUri -Configuration $config

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match 'default-project'
            }

            # Cleanup
            $env:DefaultAdoProject = $null
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter' {
            $command = Get-Command New-AdoPolicyConfiguration
            $command.Parameters.ContainsKey('CollectionUri') | Should -Be $true
        }

        It 'Should have ProjectName parameter with ProjectId alias' {
            $command = Get-Command New-AdoPolicyConfiguration
            $command.Parameters.ContainsKey('ProjectName') | Should -Be $true
            $command.Parameters['ProjectName'].Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Configuration parameter as mandatory' {
            $command = Get-Command New-AdoPolicyConfiguration
            $configParam = $command.Parameters['Configuration']
            $mandatoryAttr = $configParam.Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory
            }
            $mandatoryAttr | Should -Not -BeNullOrEmpty
        }

        It 'Should have Version parameter with ApiVersion alias' {
            $command = Get-Command New-AdoPolicyConfiguration
            $command.Parameters.ContainsKey('Version') | Should -Be $true
            $command.Parameters['Version'].Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command New-AdoPolicyConfiguration
            $command.Parameters.ContainsKey('WhatIf') -and $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should validate API Version values' {
            $command = Get-Command New-AdoPolicyConfiguration
            $versionParam = $command.Parameters['Version']
            $validateSet = $versionParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet.ValidValues | Should -Contain '7.1'
            $validateSet.ValidValues | Should -Contain '7.2-preview.1'
        }
    }

    Context 'ShouldProcess support' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id          = 20
                    type        = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }
                    revision    = 1
                    isEnabled   = $true
                    isBlocking  = $true
                    isDeleted   = $false
                    settings    = @{ minimumApproverCount = 1 }
                    createdBy   = @{ id = '11111111-1111-1111-1111-111111111111' }
                    createdDate = '2024-01-01T00:00:00Z'
                }
            }
        }

        It 'Should not call API when WhatIf is specified' {
            $config = [PSCustomObject]@{
                isEnabled  = $true
                isBlocking = $true
                type       = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }
                settings   = @{ minimumApproverCount = 1 }
            }

            New-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $config -WhatIf

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should call API when Confirm is false' {
            $config = [PSCustomObject]@{
                isEnabled  = $true
                isBlocking = $true
                type       = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }
                settings   = @{ minimumApproverCount = 1 }
            }

            New-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $config -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id          = 20
                    type        = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }
                    revision    = 1
                    isEnabled   = $true
                    isBlocking  = $true
                    isDeleted   = $false
                    settings    = @{ minimumApproverCount = 2 }
                    createdBy   = @{ displayName = 'User' }
                    createdDate = '2025-01-05T00:00:00Z'
                }
            }
        }

        It 'Should return PSCustomObject with required properties' {
            # Arrange
            $config = [PSCustomObject]@{
                isEnabled  = $true
                isBlocking = $true
                type       = @{ id = $policyTypeId }
                settings   = @{ minimumApproverCount = 2 }
            }

            # Act
            $result = New-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $config

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.PSObject.Properties.Name | Should -Contain 'id'
            $result.PSObject.Properties.Name | Should -Contain 'type'
            $result.PSObject.Properties.Name | Should -Contain 'revision'
            $result.PSObject.Properties.Name | Should -Contain 'isEnabled'
            $result.PSObject.Properties.Name | Should -Contain 'isBlocking'
            $result.PSObject.Properties.Name | Should -Contain 'isDeleted'
            $result.PSObject.Properties.Name | Should -Contain 'settings'
            $result.PSObject.Properties.Name | Should -Contain 'createdBy'
            $result.PSObject.Properties.Name | Should -Contain 'createdDate'
            $result.PSObject.Properties.Name | Should -Contain 'projectName'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }
    }

    Context 'Integration scenarios' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                return @{
                    id          = [System.Random]::new().Next(1, 1000)
                    type        = $Body.type
                    revision    = 1
                    isEnabled   = $Body.isEnabled
                    isBlocking  = $Body.isBlocking
                    isDeleted   = $false
                    settings    = $Body.settings
                    createdBy   = @{ displayName = 'User' }
                    createdDate = '2025-01-05T00:00:00Z'
                }
            }
        }

        It 'Should create multiple policy configurations' {
            # Arrange
            $configs = @(
                [PSCustomObject]@{
                    isEnabled  = $true
                    isBlocking = $true
                    type       = @{ id = $policyTypeId }
                    settings   = @{ minimumApproverCount = 1 }
                }
                [PSCustomObject]@{
                    isEnabled  = $true
                    isBlocking = $false
                    type       = @{ id = $policyTypeId }
                    settings   = @{ minimumApproverCount = 2 }
                }
            )

            # Act
            $results = $configs | ForEach-Object {
                New-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $_
            }

            # Assert
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }
}
