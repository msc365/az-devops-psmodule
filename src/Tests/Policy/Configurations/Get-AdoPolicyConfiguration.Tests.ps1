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

Describe 'Get-AdoPolicyConfiguration' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $policyTypeId = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When retrieving a specific policy configuration by ID' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id          = 1
                    type        = @{
                        id          = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
                        displayName = 'Minimum number of reviewers'
                    }
                    revision    = 1
                    isEnabled   = $true
                    isBlocking  = $true
                    isDeleted   = $false
                    settings    = @{
                        minimumApproverCount = 2
                        creatorVoteCounts    = $true
                        scope                = @(
                            @{
                                repositoryId = $null
                                refName      = $null
                                matchKind    = 'DefaultBranch'
                            }
                        )
                    }
                    createdBy   = @{
                        displayName = 'User Name'
                        id          = '11111111-1111-1111-1111-111111111111'
                    }
                    createdDate = '2025-01-01T00:00:00Z'
                }
            }
        }

        It 'Should retrieve policy configuration by ID' {
            # Act
            $result = Get-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 1

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            $result.isEnabled | Should -Be $true
            $result.isBlocking | Should -Be $true
            $result.collectionUri | Should -Be $collectionUri
            $result.projectName | Should -Be $projectName
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/policy/configurations/1" -and
                $Method -eq 'GET'
            }
        }

        It 'Should use correct API version' {
            # Act
            Get-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 1 -Version '7.2-preview.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should accept pipeline input for ID' {
            # Act
            $result = 1 | Get-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should retrieve multiple configurations via pipeline' {
            # Act
            $result = @(1, 2, 3) | Get-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
        }
    }

    Context 'When retrieving all policy configurations' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{
                            id          = 1
                            type        = @{
                                id          = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
                                displayName = 'Minimum number of reviewers'
                            }
                            revision    = 1
                            isEnabled   = $true
                            isBlocking  = $true
                            isDeleted   = $false
                            settings    = @{ minimumApproverCount = 2 }
                            createdBy   = @{ displayName = 'User Name' }
                            createdDate = '2025-01-01T00:00:00Z'
                        }
                        @{
                            id          = 2
                            type        = @{
                                id          = '0609b952-1397-4640-95ec-e00a01b2c241'
                                displayName = 'Work item linking'
                            }
                            revision    = 2
                            isEnabled   = $false
                            isBlocking  = $false
                            isDeleted   = $false
                            settings    = @{ }
                            createdBy   = @{ displayName = 'User Name' }
                            createdDate = '2025-01-02T00:00:00Z'
                        }
                    )
                }
            }
        }

        It 'Should retrieve all policy configurations' {
            # Act
            $result = Get-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].id | Should -Be 1
            $result[1].id | Should -Be 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/policy/configurations`$" -and
                $Method -eq 'GET'
            }
        }
    }

    Context 'When filtering by PolicyType' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{
                            id          = 1
                            type        = @{
                                id          = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
                                displayName = 'Minimum number of reviewers'
                            }
                            revision    = 1
                            isEnabled   = $true
                            isBlocking  = $true
                            isDeleted   = $false
                            settings    = @{ minimumApproverCount = 2 }
                            createdBy   = @{ displayName = 'User Name' }
                            createdDate = '2025-01-01T00:00:00Z'
                        }
                    )
                }
            }
        }

        It 'Should filter configurations by PolicyType' {
            # Act
            $result = Get-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -PolicyType $policyTypeId

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match "policyType=$policyTypeId" -and
                $Method -eq 'GET'
            }
        }
    }

    Context 'When using pagination parameters' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{
                            id               = 1
                            type             = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }
                            revision         = 1
                            isEnabled        = $true
                            isBlocking       = $true
                            isDeleted        = $false
                            settings         = @{ }
                            createdBy        = @{ displayName = 'User' }
                            createdDate      = '2025-01-01T00:00:00Z'
                            continuationToken = 'next-page-token'
                        }
                    )
                }
            }
        }

        It 'Should use Top parameter for pagination' {
            # Act
            $result = Get-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Top 10

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match '\$top=10'
            }
        }

        It 'Should use ContinuationToken parameter' {
            # Act
            $result = Get-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -ContinuationToken 'next-page-token'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.continuationToken | Should -Be 'next-page-token'
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match 'continuationToken=next-page-token'
            }
        }

        It 'Should use Scope parameter' {
            # Act
            Get-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Scope 'refs/heads/main'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match 'scope=refs/heads/main'
            }
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
            # Act
            $result = Get-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 999 -WarningVariable warnings -WarningAction SilentlyContinue

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
                    id          = 1
                    type        = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }
                    revision    = 1
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

            # Act
            $result = Get-AdoPolicyConfiguration -ProjectName $projectName -Id 1

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

            # Act
            $result = Get-AdoPolicyConfiguration -CollectionUri $collectionUri -Id 1

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
            $command = Get-Command Get-AdoPolicyConfiguration
            $command.Parameters.ContainsKey('CollectionUri') | Should -Be $true
        }

        It 'Should have ProjectName parameter with ProjectId alias' {
            $command = Get-Command Get-AdoPolicyConfiguration
            $command.Parameters.ContainsKey('ProjectName') | Should -Be $true
            $command.Parameters['ProjectName'].Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Id parameter with ConfigurationId alias' {
            $command = Get-Command Get-AdoPolicyConfiguration
            $command.Parameters.ContainsKey('Id') | Should -Be $true
            $command.Parameters['Id'].Aliases | Should -Contain 'ConfigurationId'
        }

        It 'Should have PolicyType parameter' {
            $command = Get-Command Get-AdoPolicyConfiguration
            $command.Parameters.ContainsKey('PolicyType') | Should -Be $true
        }

        It 'Should have Version parameter with ApiVersion alias' {
            $command = Get-Command Get-AdoPolicyConfiguration
            $command.Parameters.ContainsKey('Version') | Should -Be $true
            $command.Parameters['Version'].Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Get-AdoPolicyConfiguration
            $command.Parameters.ContainsKey('WhatIf') -and $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should validate API Version values' {
            $command = Get-Command Get-AdoPolicyConfiguration
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
            Get-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 1 -WhatIf

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should call API when Confirm is false' {
            Get-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 1 -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id          = 1
                    type        = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }
                    revision    = 1
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
            # Act
            $result = Get-AdoPolicyConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 1

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
}
