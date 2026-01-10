BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Remove-AdoServiceEndpoint' {
    BeforeAll {
        # Sample endpoint data for mocking
        $mockEndpoint = [PSCustomObject]@{
            id                               = '11111111-1111-1111-1111-111111111111'
            name                             = 'TestEndpoint1'
            type                             = 'azurerm'
            description                      = 'Test Azure RM endpoint'
            authorization                    = @{
                scheme     = 'ServicePrincipal'
                parameters = @{ tenantid = '22222222-2222-2222-2222-222222222222' }
            }
            isShared                         = $false
            isReady                          = $true
            owner                            = 'library'
            data                             = @{
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
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $null }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should remove a service endpoint by ID' {
            # Act
            Remove-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Id '11111111-1111-1111-1111-111111111111' -ProjectIds '44444444-4444-4444-4444-444444444444' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'DELETE' -and
                $Uri -like '*11111111-1111-1111-1111-111111111111*'
            }
        }

        It 'Should accept endpoint ID via pipeline' {
            # Act
            '11111111-1111-1111-1111-111111111111' | Remove-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectIds '44444444-4444-4444-4444-444444444444' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*11111111-1111-1111-1111-111111111111*'
            }
        }

        It 'Should accept endpoint object via pipeline' {
            # Act
            $mockEndpoint | Remove-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -ProjectIds '44444444-4444-4444-4444-444444444444' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*11111111-1111-1111-1111-111111111111*'
            }
        }

        It 'Should support multiple project IDs' {
            # Act
            Remove-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Id '11111111-1111-1111-1111-111111111111' -ProjectIds '44444444-4444-4444-4444-444444444444', '55555555-5555-5555-5555-555555555555' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*projectIds=44444444-4444-4444-4444-444444444444,55555555-5555-5555-5555-555555555555*'
            }
        }

        It 'Should support Deep switch parameter' {
            # Act
            Remove-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Id '11111111-1111-1111-1111-111111111111' -ProjectIds '44444444-4444-4444-4444-444444444444' -Deep -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*deep=true*'
            }
        }

        It 'Should use specified API version' {
            # Act
            Remove-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Id '11111111-1111-1111-1111-111111111111' -ProjectIds '44444444-4444-4444-4444-444444444444' -Version '7.2-preview.4' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.2-preview.4'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $null }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { Remove-AdoServiceEndpoint -CollectionUri 'invalid-uri' -Id '11111111-1111-1111-1111-111111111111' -ProjectIds '44444444-4444-4444-4444-444444444444' -Confirm:$false } | Should -Throw
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            Remove-AdoServiceEndpoint -Id '11111111-1111-1111-1111-111111111111' -ProjectIds '44444444-4444-4444-4444-444444444444' -Confirm:$false

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
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $null }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct REST API URI' {
            # Act
            Remove-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Id '11111111-1111-1111-1111-111111111111' -ProjectIds '44444444-4444-4444-4444-444444444444' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/my-org/_apis/serviceendpoint/endpoints/11111111-1111-1111-1111-111111111111' -and
                $Version -eq '7.1' -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should include project IDs in query parameters' {
            # Act
            Remove-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Id '11111111-1111-1111-1111-111111111111' -ProjectIds '44444444-4444-4444-4444-444444444444' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*projectIds=44444444-4444-4444-4444-444444444444*'
            }
        }

        It 'Should call Confirm-Default to validate defaults' {
            # Act
            Remove-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Id '11111111-1111-1111-1111-111111111111' -ProjectIds '44444444-4444-4444-4444-444444444444' -Confirm:$false

            # Assert
            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should warn when endpoint does not exist' {
            # Arrange
            $exception = New-Object System.Management.Automation.RuntimeException('No service connection found with the specified ID')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'EndpointNotFound', 'ObjectNotFound', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('No service connection found with the specified ID')
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            # Act & Assert - Should write warning but not throw
            { Remove-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Id 'NonExistentId' -ProjectIds '44444444-4444-4444-4444-444444444444' -WarningAction SilentlyContinue -Confirm:$false } | Should -Not -Throw
        }

        It 'Should propagate other errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            # Act & Assert
            { Remove-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Id '11111111-1111-1111-1111-111111111111' -ProjectIds '44444444-4444-4444-4444-444444444444' -Confirm:$false } | Should -Throw '*API Error: Unauthorized*'
        }
    }
}
