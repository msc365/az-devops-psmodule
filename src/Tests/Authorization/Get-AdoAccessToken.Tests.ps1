[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Required for Pester test mocking')]
param()

BeforeAll {
    # Import the module for testing
    $moduleName = 'Azure.DevOps.PSModule'
    $modulePath = Join-Path -Path (Get-Item $PSScriptRoot).Parent.Parent.FullName -ChildPath $moduleName

    # Remove module if already loaded
    if (Get-Module -Name $moduleName -ErrorAction SilentlyContinue) {
        Remove-Module -Name $moduleName -Force
    }

    # Import the module
    Import-Module $modulePath -Force -ErrorAction Stop

    # Set up module-level mocks that work across all tests
    Mock Get-AzContext -ModuleName $moduleName -MockWith {
        return @{
            Tenant      = @{
                Id = '11111111-1111-1111-1111-111111111111'
            }
            Environment = 'AzureCloud'
        }
    }

    Mock Get-AzAccessToken -ModuleName $moduleName -MockWith {
        return @{
            Token = ConvertTo-SecureString 'mock-token-value' -AsPlainText -Force
        }
    }
}

Describe 'Get-AdoAccessToken' {

    Context 'When retrieving access token with default tenant ID' {
        It 'Should retrieve access token using tenant ID from current Azure context' {
            # Act
            $result = Get-AdoAccessToken

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [System.Security.SecureString]

            # Verify Get-AzContext was called
            Should -Invoke Get-AzContext -ModuleName $moduleName -Exactly 1

            # Verify Get-AzAccessToken was called with correct parameters
            Should -Invoke Get-AzAccessToken -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $ResourceUrl -eq '499b84ac-1321-427f-aa17-267ca6975798' -and
                $TenantId -eq '11111111-1111-1111-1111-111111111111'
            }
        }
    }

    Context 'When retrieving access token with specified tenant ID' {
        It 'Should retrieve access token using specified tenant ID' {
            # Arrange
            $specifiedTenantId = '22222222-2222-2222-2222-222222222222'

            # Act
            $result = Get-AdoAccessToken -TenantId $specifiedTenantId

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [System.Security.SecureString]

            # Verify Get-AzContext was NOT called when TenantId is provided
            Should -Invoke Get-AzContext -ModuleName $moduleName -Exactly 0

            # Verify Get-AzAccessToken was called with the specified tenant ID
            Should -Invoke Get-AzAccessToken -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $ResourceUrl -eq '499b84ac-1321-427f-aa17-267ca6975798' -and
                $TenantId -eq $specifiedTenantId
            }
        }

        It 'Should accept empty string as tenant ID and use context tenant ID' {
            # Act
            $result = Get-AdoAccessToken -TenantId ''

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [System.Security.SecureString]

            # Verify Get-AzContext was called because TenantId was empty
            Should -Invoke Get-AzContext -ModuleName $moduleName -Exactly 1

            # Verify Get-AzAccessToken was called with context tenant ID
            Should -Invoke Get-AzAccessToken -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $ResourceUrl -eq '499b84ac-1321-427f-aa17-267ca6975798' -and
                $TenantId -eq '11111111-1111-1111-1111-111111111111'
            }
        }
    }

    Context 'When Azure DevOps service principal configuration is used' {
        It 'Should use the correct immutable Azure DevOps application ID' {
            # Act
            Get-AdoAccessToken

            # Assert - Verify the correct Azure DevOps service principal app ID is used
            Should -Invoke Get-AzAccessToken -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $ResourceUrl -eq '499b84ac-1321-427f-aa17-267ca6975798'
            }
        }
    }

    Context 'When Get-AzContext fails' {
        It 'Should throw an error when Get-AzContext fails' {
            # Arrange
            Mock Get-AzContext -ModuleName $moduleName -MockWith {
                throw 'No Azure context found'
            }

            # Act & Assert
            { Get-AdoAccessToken } | Should -Throw
        }

        It 'Should throw an error when Get-AzContext returns null' {
            # Arrange - Mock Get-AzContext to return null
            Mock Get-AzContext -ModuleName $moduleName -MockWith {
                return $null
            }

            # Act & Assert
            { Get-AdoAccessToken } | Should -Throw
        }
    }

    Context 'When Get-AzAccessToken fails' {
        It 'Should throw an error when Get-AzAccessToken fails' {
            # Arrange
            Mock Get-AzAccessToken -ModuleName $moduleName -MockWith {
                throw 'Failed to get access token'
            }

            # Act & Assert
            { Get-AdoAccessToken } | Should -Throw 'Failed to get access token'
        }

        It 'Should handle Get-AzAccessToken returning null gracefully' {
            # Arrange - Mock Get-AzAccessToken to return null
            Mock Get-AzAccessToken -ModuleName $moduleName -MockWith {
                return $null
            }

            # Act & Assert - PowerShell will try to access .Token on null, which returns null
            # The function should handle this by returning null or empty SecureString
            $result = Get-AdoAccessToken

            # The result might be null or an empty secure string depending on how PowerShell handles it
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Parameter validation' {
        It 'Should accept valid GUID as TenantId' {
            # Arrange
            $validGuid = '12345678-1234-1234-1234-123456789012'

            # Act & Assert
            { Get-AdoAccessToken -TenantId $validGuid } | Should -Not -Throw
        }

        It 'Should accept string values for TenantId parameter' {
            # Arrange
            $tenantIdString = 'tenant-name-or-id'

            # Act & Assert
            { Get-AdoAccessToken -TenantId $tenantIdString } | Should -Not -Throw
        }
    }

    Context 'Output validation' {
        It 'Should return SecureString type' {
            # Act
            $result = Get-AdoAccessToken

            # Assert
            $result | Should -BeOfType [System.Security.SecureString]
        }

        It 'Should return non-null SecureString' {
            # Act
            $result = Get-AdoAccessToken

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Length | Should -BeGreaterThan 0
        }
    }

    Context 'Integration scenarios' {
        It 'Should work with different Azure environments' {
            # Arrange
            Mock Get-AzContext -ModuleName $moduleName -MockWith {
                return @{
                    Tenant      = @{
                        Id = '33333333-3333-3333-3333-333333333333'
                    }
                    Environment = 'AzureUSGovernment'
                }
            }

            # Act
            $result = Get-AdoAccessToken

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [System.Security.SecureString]

            # Verify correct tenant ID from different environment
            Should -Invoke Get-AzAccessToken -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $TenantId -eq '33333333-3333-3333-3333-333333333333'
            }
        }

        It 'Should handle multiple consecutive calls correctly' {
            # Act
            $result1 = Get-AdoAccessToken
            $result2 = Get-AdoAccessToken -TenantId '44444444-4444-4444-4444-444444444444'

            # Assert
            $result1 | Should -BeOfType [System.Security.SecureString]
            $result2 | Should -BeOfType [System.Security.SecureString]

            # Verify both calls were made correctly
            Should -Invoke Get-AzAccessToken -ModuleName $moduleName -Exactly 2
        }
    }
}
