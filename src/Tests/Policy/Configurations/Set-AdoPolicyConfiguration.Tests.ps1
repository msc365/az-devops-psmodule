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

Describe 'Set-AdoPolicyConfiguration' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $policyTypeId = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When updating a policy configuration' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body, $Uri)
                $configIdFromUri = $Uri -replace '.*/configurations/(\d+).*', '$1'

                return @{
                    id          = [int]$configIdFromUri
                    type        = $Body.type
                    revision    = 2
                    isEnabled   = $Body.isEnabled
                    isBlocking  = $Body.isBlocking
                    isDeleted   = $false
                    settings    = $Body.settings
                    createdBy   = @{
                        displayName = 'User Name'
                        id          = '11111111-1111-1111-1111-111111111111'
                    }
                    createdDate = '2025-01-01T00:00:00Z'
                }
            }
        }

        It 'Should update a policy configuration' {
            # Arrange
            $config = [PSCustomObject]@{
                isEnabled  = $false
                isBlocking = $true
                type       = @{ id = $policyTypeId }
                settings   = @{
                    minimumApproverCount        = 3
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
            $result = Set-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 1 -Configuration $config -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            $result.isEnabled | Should -Be $false
            $result.isBlocking | Should -Be $true
            $result.revision | Should -Be 2
            $result.collectionUri | Should -Be $collectionUri
            $result.projectName | Should -Be $projectName
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/policy/configurations/1" -and
                $Method -eq 'PUT'
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
            Set-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 1 -Configuration $config -Version '7.2-preview.1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should accept ID via pipeline input' {
            # Arrange
            $config = [PSCustomObject]@{
                isEnabled  = $true
                isBlocking = $false
                type       = @{ id = $policyTypeId }
                settings   = @{ minimumApproverCount = 1 }
            }

            # Act
            $result = 1 | Set-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $config -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should update configuration with complex settings' {
            # Arrange
            $config = [PSCustomObject]@{
                isEnabled  = $true
                isBlocking = $true
                type       = @{ id = $policyTypeId }
                settings   = @{
                    minimumApproverCount        = 5
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
                            refName      = 'refs/heads/develop'
                            matchKind    = 'Exact'
                        }
                    )
                }
            }

            # Act
            $result = Set-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 5 -Configuration $config -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 5
            $result.settings.minimumApproverCount | Should -Be 5
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Method -eq 'PUT'
            }
        }
    }

    Context 'When updating multiple configurations' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body, $Uri)
                $configIdFromUri = $Uri -replace '.*/configurations/(\d+).*', '$1'

                return @{
                    id          = [int]$configIdFromUri
                    type        = $Body.type
                    revision    = 3
                    isEnabled   = $Body.isEnabled
                    isBlocking  = $Body.isBlocking
                    isDeleted   = $false
                    settings    = $Body.settings
                    createdBy   = @{ displayName = 'User' }
                    createdDate = '2025-01-01T00:00:00Z'
                }
            }
        }

        It 'Should update multiple configurations via pipeline' {
            # Arrange
            $config = [PSCustomObject]@{
                isEnabled  = $true
                isBlocking = $true
                type       = @{ id = $policyTypeId }
                settings   = @{ minimumApproverCount = 2 }
            }

            # Act
            $result = @(1, 2, 3) | Set-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Configuration $config -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].id | Should -Be 1
            $result[1].id | Should -Be 2
            $result[2].id | Should -Be 3
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
        }
    }

    Context 'When handling errors' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'TF401232: Policy configuration with ID ''999'' does not exist or you do not have permissions to access it.'
                    typeKey = 'NotFoundException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Not Found')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'NotFoundException',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }
        }

        It 'Should handle non-existing configuration with warning' {
            # Arrange
            $config = [PSCustomObject]@{
                isEnabled  = $true
                isBlocking = $true
                type       = @{ id = $policyTypeId }
                settings   = @{ minimumApproverCount = 1 }
            }

            # Act
            $result = Set-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 999 -Configuration $config -Confirm:$false -WarningVariable warnings -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
            $warnings | Should -Not -BeNullOrEmpty
            $warnings | Should -BeLike '*does not exist*'
        }
    }

    Context 'When using default parameters' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id          = 10
                    type        = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }
                    revision    = 2
                    isEnabled   = $true
                    isBlocking  = $true
                    isDeleted   = $false
                    settings    = @{ }
                    createdBy   = @{ displayName = 'User' }
                    createdDate = '2025-01-01T00:00:00Z'
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
            $result = Set-AdoPolicyConfiguration -ProjectName $projectName -Id 10 -Configuration $config -Confirm:$false

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
            $result = Set-AdoPolicyConfiguration -CollectionUri $collectionUri -Id 10 -Configuration $config -Confirm:$false

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
            $command = Get-Command Set-AdoPolicyConfiguration
            $command.Parameters.ContainsKey('CollectionUri') | Should -Be $true
        }

        It 'Should have ProjectName parameter with ProjectId alias' {
            $command = Get-Command Set-AdoPolicyConfiguration
            $command.Parameters.ContainsKey('ProjectName') | Should -Be $true
            $command.Parameters['ProjectName'].Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Id parameter as mandatory with ConfigurationId alias' {
            $command = Get-Command Set-AdoPolicyConfiguration
            $idParam = $command.Parameters['Id']
            $mandatoryAttr = $idParam.Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory
            }
            $mandatoryAttr | Should -Not -BeNullOrEmpty
            $idParam.Aliases | Should -Contain 'ConfigurationId'
        }

        It 'Should have Configuration parameter as mandatory' {
            $command = Get-Command Set-AdoPolicyConfiguration
            $configParam = $command.Parameters['Configuration']
            $mandatoryAttr = $configParam.Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory
            }
            $mandatoryAttr | Should -Not -BeNullOrEmpty
        }

        It 'Should have Version parameter with ApiVersion alias' {
            $command = Get-Command Set-AdoPolicyConfiguration
            $command.Parameters.ContainsKey('Version') | Should -Be $true
            $command.Parameters['Version'].Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Set-AdoPolicyConfiguration
            $command.Parameters.ContainsKey('WhatIf') -and $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should validate API Version values' {
            $command = Get-Command Set-AdoPolicyConfiguration
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
                    id          = 1
                    type        = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }
                    revision    = 2
                    isEnabled   = $false
                    isBlocking  = $true
                    isDeleted   = $false
                    settings    = @{ minimumApproverCount = 2 }
                    createdBy   = @{ id = '11111111-1111-1111-1111-111111111111' }
                    createdDate = '2024-01-01T00:00:00Z'
                }
            }
        }

        It 'Should not call API when WhatIf is specified' {
            $config = [PSCustomObject]@{
                isEnabled  = $false
                isBlocking = $true
                type       = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }
                settings   = @{ minimumApproverCount = 2 }
            }

            Set-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 1 -Configuration $config -WhatIf

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should call API when Confirm is false' {
            $config = [PSCustomObject]@{
                isEnabled  = $false
                isBlocking = $true
                type       = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }
                settings   = @{ minimumApproverCount = 2 }
            }

            Set-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 1 -Configuration $config -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id          = 20
                    type        = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }
                    revision    = 2
                    isEnabled   = $true
                    isBlocking  = $true
                    isDeleted   = $false
                    settings    = @{ minimumApproverCount = 2 }
                    createdBy   = @{ displayName = 'User' }
                    createdDate = '2025-01-01T00:00:00Z'
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
            $result = Set-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 20 -Configuration $config -Confirm:$false

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
                param($Body, $Uri)
                $configIdFromUri = $Uri -replace '.*/configurations/(\d+).*', '$1'

                return @{
                    id          = [int]$configIdFromUri
                    type        = $Body.type
                    revision    = 4
                    isEnabled   = $Body.isEnabled
                    isBlocking  = $Body.isBlocking
                    isDeleted   = $false
                    settings    = $Body.settings
                    createdBy   = @{ displayName = 'User' }
                    createdDate = '2025-01-01T00:00:00Z'
                }
            }
        }

        It 'Should disable a policy configuration' {
            # Arrange
            $config = [PSCustomObject]@{
                isEnabled  = $false
                isBlocking = $true
                type       = @{ id = $policyTypeId }
                settings   = @{ minimumApproverCount = 1 }
            }

            # Act
            $result = Set-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 25 -Configuration $config -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.isEnabled | Should -Be $false
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should change policy from blocking to non-blocking' {
            # Arrange
            $config = [PSCustomObject]@{
                isEnabled  = $true
                isBlocking = $false
                type       = @{ id = $policyTypeId }
                settings   = @{ minimumApproverCount = 1 }
            }

            # Act
            $result = Set-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 30 -Configuration $config -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.isBlocking | Should -Be $false
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }
}
