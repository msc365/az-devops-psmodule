BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoServiceEndpoint' {
    BeforeAll {
        # Sample service endpoint data for mocking
        $mockEndpoints = @{
            value = @(
                @{
                    id            = '11111111-1111-1111-1111-111111111111'
                    name          = 'TestEndpoint1'
                    type          = 'azurerm'
                    description   = 'Test Azure RM endpoint'
                    authorization = @{
                        scheme     = 'ServicePrincipal'
                        parameters = @{ tenantid = '22222222-2222-2222-2222-222222222222' }
                    }
                    isShared      = $false
                    isReady       = $true
                    owner         = 'library'
                    data          = @{
                        subscriptionId   = '33333333-3333-3333-3333-333333333333'
                        subscriptionName = 'TestSubscription'
                    }
                    serviceEndpointProjectReferences = @(
                        @{
                            projectReference = @{
                                id   = '44444444-4444-4444-4444-444444444444'
                                name = 'TestProject'
                            }
                        }
                    )
                }
                @{
                    id            = '55555555-5555-5555-5555-555555555555'
                    name          = 'TestEndpoint2'
                    type          = 'github'
                    description   = 'Test GitHub endpoint'
                    authorization = @{
                        scheme     = 'PersonalAccessToken'
                        parameters = @{}
                    }
                    isShared      = $true
                    isReady       = $true
                    owner         = 'library'
                    data          = @{}
                    serviceEndpointProjectReferences = @(
                        @{
                            projectReference = @{
                                id   = '44444444-4444-4444-4444-444444444444'
                                name = 'TestProject'
                            }
                        }
                    )
                }
            )
        }

        $mockSingleEndpoint = @{
            value = @(
                @{
                    id            = '11111111-1111-1111-1111-111111111111'
                    name          = 'TestEndpoint1'
                    type          = 'azurerm'
                    description   = 'Test Azure RM endpoint'
                    authorization = @{
                        scheme     = 'ServicePrincipal'
                        parameters = @{ tenantid = '22222222-2222-2222-2222-222222222222' }
                    }
                    isShared      = $false
                    isReady       = $true
                    owner         = 'library'
                    data          = @{
                        subscriptionId   = '33333333-3333-3333-3333-333333333333'
                        subscriptionName = 'TestSubscription'
                    }
                    serviceEndpointProjectReferences = @(
                        @{
                            projectReference = @{
                                id   = '44444444-4444-4444-4444-444444444444'
                                name = 'TestProject'
                            }
                        }
                    )
                }
            )
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockEndpoints }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should retrieve all service endpoints when no parameters provided' {
            # Act
            $result = Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $result | Should -HaveCount 2
            $result[0].name | Should -Be 'TestEndpoint1'
            $result[1].name | Should -Be 'TestEndpoint2'
        }

        It 'Should retrieve service endpoints by name' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleEndpoint }

            # Act
            $result = Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Names 'TestEndpoint1'

            # Assert
            $result | Should -HaveCount 1
            $result.name | Should -Be 'TestEndpoint1'
            $result.id | Should -Be '11111111-1111-1111-1111-111111111111'
        }

        It 'Should retrieve service endpoints by ID' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleEndpoint }

            # Act
            $result = Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Ids '11111111-1111-1111-1111-111111111111'

            # Assert
            $result | Should -HaveCount 1
            $result.id | Should -Be '11111111-1111-1111-1111-111111111111'
        }

        It 'Should return endpoint with all expected properties' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleEndpoint }

            # Act
            $result = Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Names 'TestEndpoint1'

            # Assert
            $result.id | Should -Be '11111111-1111-1111-1111-111111111111'
            $result.name | Should -Be 'TestEndpoint1'
            $result.type | Should -Be 'azurerm'
            $result.description | Should -Be 'Test Azure RM endpoint'
            $result.isShared | Should -Be $false
            $result.isReady | Should -Be $true
            $result.owner | Should -Be 'library'
            $result.projectName | Should -Be 'TestProject'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should accept endpoint names via pipeline' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleEndpoint }

            # Act
            $result = 'TestEndpoint1' | Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'TestEndpoint1'
        }

        It 'Should support multiple endpoint names' {
            # Act
            Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Names 'TestEndpoint1', 'TestEndpoint2'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*endpointNames=TestEndpoint1,TestEndpoint2*'
            }
        }

        It 'Should support multiple endpoint IDs' {
            # Act
            Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Ids '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*endpointIds=11111111-1111-1111-1111-111111111111,55555555-5555-5555-5555-555555555555*'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockEndpoints }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Get-AdoServiceEndpoint -CollectionUri 'invalid-uri' -ProjectName 'TestProject' } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            $result = Get-AdoServiceEndpoint -ProjectName 'TestProject'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*dev.azure.com/default-org*'
            }

            # Cleanup
            Remove-Item env:DefaultAdoCollectionUri -ErrorAction SilentlyContinue
        }

        It 'Should use default ProjectName from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoProject = 'DefaultProject'

            # Act
            $result = Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*DefaultProject*'
            }

            # Cleanup
            Remove-Item env:DefaultAdoProject -ErrorAction SilentlyContinue
        }
    }

    Context 'API Interaction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockEndpoints }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct REST API URI' {
            # Act
            Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/TestProject/_apis/serviceendpoint/endpoints' -and
                $Version -eq '7.1' -and
                $Method -eq 'GET'
            }
        }

        It 'Should support Owner parameter with library value' {
            # Act
            Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Owner 'library'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*owner=library*'
            }
        }

        It 'Should support Type parameter' {
            # Act
            Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Type 'azurerm'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*type=azurerm*'
            }
        }

        It 'Should support IncludeFailed switch parameter' {
            # Act
            Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -IncludeFailed

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*includeFailed=true*'
            }
        }

        It 'Should support ActionFilter parameter' {
            # Act
            Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Ids '11111111-1111-1111-1111-111111111111' -ActionFilter 'manage'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*actionFilter=manage*'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Act
            Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should handle empty endpoint list from API' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return @{ value = @() } }

            # Act
            $result = Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject'

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should warn when endpoint does not exist by ID (NotFoundException)' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('NotFoundException: Service endpoint not found')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'EndpointNotFound', 'ObjectNotFound', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('NotFoundException: Service endpoint not found')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act & Assert - Should write warning but not throw
            { Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Ids 'NonExistentId' -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should warn when endpoint does not exist by name (NotFoundException)' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('NotFoundException: Service endpoint not found')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'EndpointNotFound', 'ObjectNotFound', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('NotFoundException: Service endpoint not found')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act & Assert - Should write warning but not throw
            { Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Names 'NonExistentEndpoint' -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { Get-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' } | Should -Throw '*API Error: Unauthorized*'
        }
    }
}
