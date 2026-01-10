BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'New-AdoServiceEndpoint' {
    BeforeAll {
        # Sample configuration for mocking
        $mockConfiguration = [PSCustomObject]@{
            data                             = [PSCustomObject]@{
                creationMode     = 'Manual'
                environment      = 'AzureCloud'
                scopeLevel       = 'Subscription'
                subscriptionId   = '00000000-0000-0000-0000-000000000000'
                subscriptionName = 'TestSubscription'
            }
            name                             = 'TestEndpoint1'
            type                             = 'AzureRM'
            url                              = 'https://management.azure.com/'
            authorization                    = [PSCustomObject]@{
                parameters = [PSCustomObject]@{
                    serviceprincipalid = '11111111-1111-1111-1111-111111111111'
                    tenantid           = '22222222-2222-2222-2222-222222222222'
                    scope              = '/subscriptions/00000000-0000-0000-0000-000000000000'
                }
                scheme     = 'WorkloadIdentityFederation'
            }
            isShared                         = $false
            serviceEndpointProjectReferences = [PSCustomObject[]]@(
                [PSCustomObject]@{
                    name             = 'TestEndpoint1'
                    projectReference = [PSCustomObject]@{
                        id   = '33333333-3333-3333-3333-333333333333'
                        name = 'TestProject'
                    }
                }
            )
        }

        $mockCreatedEndpoint = @{
            id                               = '44444444-4444-4444-4444-444444444444'
            name                             = 'TestEndpoint1'
            type                             = 'AzureRM'
            description                      = 'Test endpoint description'
            authorization                    = @{
                parameters = @{
                    serviceprincipalid = '11111111-1111-1111-1111-111111111111'
                    tenantid           = '22222222-2222-2222-2222-222222222222'
                }
                scheme     = 'WorkloadIdentityFederation'
            }
            url                              = 'https://management.azure.com/'
            isShared                         = $false
            isReady                          = $true
            owner                            = 'library'
            data                             = @{
                subscriptionId   = '00000000-0000-0000-0000-000000000000'
                subscriptionName = 'TestSubscription'
            }
            serviceEndpointProjectReferences = @(
                @{
                    name             = 'TestEndpoint1'
                    projectReference = @{
                        id   = '33333333-3333-3333-3333-333333333333'
                        name = 'TestProject'
                    }
                }
            )
        }

        $mockExistingEndpoint = @{
            value = @(
                @{
                    id                               = '55555555-5555-5555-5555-555555555555'
                    name                             = 'TestEndpoint1'
                    type                             = 'AzureRM'
                    description                      = 'Existing endpoint'
                    authorization                    = @{}
                    isShared                         = $false
                    isReady                          = $true
                    url                              = 'https://management.azure.com/'
                    owner                            = 'library'
                    data                             = @{}
                    serviceEndpointProjectReferences = @()
                }
            )
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCreatedEndpoint }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should create a new service endpoint' {
            # Act
            $result = New-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Configuration $mockConfiguration -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'TestEndpoint1'
            $result.id | Should -Be '44444444-4444-4444-4444-444444444444'
        }

        It 'Should return endpoint with all expected properties' {
            # Act
            $result = New-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Configuration $mockConfiguration -Confirm:$false

            # Assert
            $result.id | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'TestEndpoint1'
            $result.type | Should -Be 'AzureRM'
            $result.isShared | Should -Be $false
            $result.isReady | Should -Be $true
            $result.owner | Should -Be 'library'
            $result.projectName | Should -Be 'TestProject'
            $result.collectionUri | Should -Be 'https://dev.azure.com/my-org'
        }

        It 'Should accept configuration object with ValueFromPipelineByPropertyName' {
            # Arrange
            $pipelineObject = [PSCustomObject]@{
                Configuration = $mockConfiguration
                CollectionUri = 'https://dev.azure.com/my-org'
            }

            # Act
            $result = $pipelineObject | New-AdoServiceEndpoint -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'TestEndpoint1'
        }

        It 'Should pass configuration object to Invoke-AdoRestMethod' {
            # Act
            New-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Configuration $mockConfiguration -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'POST'
            }
        }

        It 'Should use specified API version' {
            # Act
            New-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Configuration $mockConfiguration -Version '7.2-preview.4' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.2-preview.4'
            }
        }

        It 'Should extract project name from configuration' {
            # Act
            $result = New-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Configuration $mockConfiguration -Confirm:$false

            # Assert
            $result.projectName | Should -Be 'TestProject'
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCreatedEndpoint }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { New-AdoServiceEndpoint -CollectionUri 'invalid-uri' -Configuration $mockConfiguration -Confirm:$false } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            $result = New-AdoServiceEndpoint -Configuration $mockConfiguration -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*dev.azure.com/default-org*'
            }

            # Cleanup
            Remove-Item env:DefaultAdoCollectionUri -ErrorAction SilentlyContinue
        }
    }

    Context 'API Interaction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCreatedEndpoint }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct REST API URI' {
            # Act
            New-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Configuration $mockConfiguration -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/serviceendpoint/endpoints' -and
                $Version -eq '7.1' -and
                $Method -eq 'POST'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Act
            New-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Configuration $mockConfiguration -Confirm:$false

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should handle duplicate endpoint by retrieving existing one' {
            # Arrange
            $duplicateException = New-Object System.Management.Automation.RuntimeException('DuplicateServiceConnectionException: Service endpoint already exists')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($duplicateException, 'DuplicateEndpoint', 'ResourceExists', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('DuplicateServiceConnectionException: Service endpoint already exists')

            # First call (POST) throws duplicate error, second call (GET) returns existing endpoint
            $script:callCount = 0
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                $script:callCount++
                if ($script:callCount -eq 1) {
                    throw $errorRecord
                } else {
                    return $mockExistingEndpoint
                }
            }

            # Act
            $result = New-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Configuration $mockConfiguration -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be '55555555-5555-5555-5555-555555555555'
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
        }

        It 'Should use GET method when retrieving existing duplicate endpoint' {
            # Arrange
            $duplicateException = New-Object System.Management.Automation.RuntimeException('DuplicateServiceConnectionException: Service endpoint already exists')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($duplicateException, 'DuplicateEndpoint', 'ResourceExists', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('DuplicateServiceConnectionException: Service endpoint already exists')

            $script:callCount = 0
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                $script:callCount++
                if ($script:callCount -eq 1) {
                    throw $errorRecord
                } else {
                    return $mockExistingEndpoint
                }
            }

            # Act
            $result = New-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Configuration $mockConfiguration -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'GET' -and $Uri -like '*TestProject*' -and $QueryParameters -like '*endpointNames=TestEndpoint1*'
            }
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { New-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Configuration $mockConfiguration -Confirm:$false } | Should -Throw '*API Error: Unauthorized*'
        }
    }
}
