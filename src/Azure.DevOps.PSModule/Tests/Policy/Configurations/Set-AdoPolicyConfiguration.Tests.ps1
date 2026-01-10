BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Set-AdoPolicyConfiguration' {
    BeforeAll {
        # Sample environment values for mocking
        $mockCollectionUri = 'https://dev.azure.com/my-org'
        $mockProject = 'my-project'
        $mockConfigId = 42
        $mockPolicyTypeId = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'

        $mockConfiguration = [PSCustomObject]@{
            isEnabled  = $true
            isBlocking = $true
            type       = @{
                id = $mockPolicyTypeId
            }
            settings   = @{
                minimumApproverCount             = 3
                creatorVoteCounts                = $true
                allowDownvotes                   = $false
                resetOnSourcePush                = $false
                requireVoteOnLastIteration       = $false
                resetRejectionsOnSourcePush      = $false
                blockLastPusherVote              = $false
                requireVoteOnEachIteration       = $false
                scope                            = @(
                    @{
                        repositoryId = $null
                        refName      = $null
                        matchKind    = 'DefaultBranch'
                    }
                )
            }
        }

        $mockResponse = @{
            id          = $mockConfigId
            type        = @{
                id          = $mockPolicyTypeId
                displayName = 'Minimum Approver Count'
            }
            revision    = 2
            isEnabled   = $true
            isBlocking  = $true
            isDeleted   = $false
            settings    = $mockConfiguration.settings
            createdBy   = @{
                displayName = 'Test User'
                id          = '12345'
            }
            createdDate = '2025-01-01T00:00:00Z'
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockResponse
            }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }

            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        AfterEach {
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should update an existing policy configuration' {
            # Act
            $result = Set-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId -Configuration $mockConfiguration -Confirm:$false

            # Assert
            $result.id | Should -Be $mockConfigId
            $result.revision | Should -Be 2
            $result.isEnabled | Should -Be $true
        }

        It 'Should include projectName and collectionUri in output' {
            # Act
            $result = Set-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId -Configuration $mockConfiguration -Confirm:$false

            # Assert
            $result.projectName | Should -Be $mockProject
            $result.collectionUri | Should -Be $mockCollectionUri
        }

        It 'Should return PSCustomObject with expected properties' {
            # Act
            $result = Set-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId -Configuration $mockConfiguration -Confirm:$false

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'id'
            $result.PSObject.Properties.Name | Should -Contain 'type'
            $result.PSObject.Properties.Name | Should -Contain 'revision'
            $result.PSObject.Properties.Name | Should -Contain 'isEnabled'
            $result.PSObject.Properties.Name | Should -Contain 'isBlocking'
            $result.PSObject.Properties.Name | Should -Contain 'settings'
            $result.PSObject.Properties.Name | Should -Contain 'projectName'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should support pipeline input for configuration IDs' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockResponse
            }

            # Act
            $result = 42, 43 | Set-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Configuration $mockConfiguration -Confirm:$false

            # Assert
            $result.Count | Should -Be 2
        }

        It 'Should preserve updated configuration settings in output' {
            # Act
            $result = Set-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId -Configuration $mockConfiguration -Confirm:$false

            # Assert
            $result.settings.minimumApproverCount | Should -Be 3
            $result.settings.creatorVoteCounts | Should -Be $true
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }

            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        AfterEach {
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should reject invalid CollectionUri format' {
            # Act & Assert
            { Set-AdoPolicyConfiguration -CollectionUri 'invalid-uri' -ProjectName $mockProject -Id $mockConfigId -Configuration $mockConfiguration -Confirm:$false } | Should -Throw
        }

        It 'Should require Id parameter' {
            # Arrange
            $metadata = (Get-Command Set-AdoPolicyConfiguration).Parameters['Id']

            # Assert
            $metadata.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should require Configuration parameter' {
            # Arrange
            $metadata = (Get-Command Set-AdoPolicyConfiguration).Parameters['Configuration']

            # Assert
            $metadata.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should use default CollectionUri from environment when not specified' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockResponse
            }

            # Act
            $result = Set-AdoPolicyConfiguration -ProjectName $mockProject -Id $mockConfigId -Configuration $mockConfiguration -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -like "*$mockCollectionUri*"
            }
        }

        It 'Should use default ProjectName from environment when not specified' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockResponse
            }

            # Act
            $result = Set-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -Id $mockConfigId -Configuration $mockConfiguration -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -like "*/$mockProject/*"
            }
        }

        It 'Should accept PSCustomObject configuration' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockResponse
            }

            # Act
            $result = Set-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId -Configuration $mockConfiguration -Confirm:$false

            # Assert
            $result.id | Should -Be $mockConfigId
        }
    }

    Context 'API Interaction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                return $mockResponse
            }

            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        AfterEach {
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should construct correct URI for updating configuration' {
            # Act
            Set-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId -Configuration $mockConfiguration -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Uri -eq "$mockCollectionUri/$mockProject/_apis/policy/configurations/$mockConfigId"
            }
        }

        It 'Should use PUT HTTP method' {
            # Act
            Set-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId -Configuration $mockConfiguration -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Method -eq 'PUT'
            }
        }

        It 'Should use correct API version' {
            # Act
            Set-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId -Configuration $mockConfiguration -Version '7.1' -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should send configuration object in request body' {
            # Act
            Set-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId -Configuration $mockConfiguration -Confirm:$false

            # Assert
            Should -Invoke -ModuleName Azure.DevOps.PSModule -CommandName Invoke-AdoRestMethod
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }

            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        AfterEach {
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should propagate API exceptions' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                throw 'Simulated API error'
            }

            # Act & Assert
            { Set-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId -Configuration $mockConfiguration -Confirm:$false -ErrorAction Stop } | Should -Throw
        }

        It 'Should handle invalid configuration object gracefully' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                throw 'Invalid configuration'
            }
            $invalidConfig = [PSCustomObject]@{
                isEnabled = $true
            }

            # Act & Assert
            { Set-AdoPolicyConfiguration -CollectionUri $mockCollectionUri -ProjectName $mockProject -Id $mockConfigId -Configuration $invalidConfig -Confirm:$false -ErrorAction Stop } | Should -Throw
        }
    }
}
