BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'New-AdoAuthHeader' -Tag 'Private' {
    BeforeAll {
        $mockPAT = 'fake-pat-token-12345'
        $mockAccessToken = 'fake-access-token-67890'
        $principalAppId = '499b84ac-1321-427f-aa17-267ca6975798'
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
                $script:header = $null
            }
        }

        It 'Should create Basic auth header when PAT is provided' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockPAT = 'fake-pat-token-12345'
                $expectedBase64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$mockPAT"))
                $expectedAuth = "Basic $expectedBase64"

                # Act
                New-AdoAuthHeader -PAT $mockPAT

                # Assert
                $script:header | Should -Not -BeNullOrEmpty
                $script:header.Authorization | Should -Be $expectedAuth
                $script:header.Authorization | Should -Match '^Basic '
            }
        }

        It 'Should create Bearer auth header when no PAT is provided' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockAccessToken = 'fake-access-token-67890'
                $principalAppId = '499b84ac-1321-427f-aa17-267ca6975798'
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
                $mockSecureToken = ConvertTo-SecureString -String $mockAccessToken -AsPlainText -Force
                $mockContext = @{ Account = 'test@example.com' }
                $mockTokenResponse = @{ token = $mockSecureToken }

                Mock Get-AzContext { return $mockContext }
                Mock Get-AzAccessToken { return $mockTokenResponse }

                # Act
                New-AdoAuthHeader -PAT ''

                # Assert
                $script:header | Should -Not -BeNullOrEmpty
                $script:header.Authorization | Should -Match '^Bearer '
                Should -Invoke Get-AzAccessToken -Times 1 -ParameterFilter {
                    $Resource -eq $principalAppId -and $AsSecureString -eq $true
                }
            }
        }

        It 'Should call Get-AzAccessToken with correct parameters' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockAccessToken = 'fake-access-token-67890'
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
                $mockSecureToken = ConvertTo-SecureString -String $mockAccessToken -AsPlainText -Force
                $mockContext = @{ Account = 'test@example.com' }
                $mockTokenResponse = @{ token = $mockSecureToken }

                Mock Get-AzContext { return $mockContext }
                Mock Get-AzAccessToken { return $mockTokenResponse }

                # Act
                New-AdoAuthHeader

                # Assert
                Should -Invoke Get-AzAccessToken -Times 1 -ParameterFilter {
                    $Resource -eq '499b84ac-1321-427f-aa17-267ca6975798'
                }
            }
        }

        It 'Should set script-scoped header variable' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockPAT = 'fake-pat-token-12345'
                $script:header = $null

                # Act
                New-AdoAuthHeader -PAT $mockPAT

                # Assert
                $script:header | Should -Not -BeNullOrEmpty
                $script:header.Keys | Should -Contain 'Authorization'
            }
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
                $script:header = $null
            }
        }

        It 'Should throw error when Get-AzContext returns null Account' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockContext = @{ Account = $null }
                Mock Get-AzContext { return $mockContext }
                Mock Write-Error { }

                # Act & Assert
                { New-AdoAuthHeader -ErrorAction Stop } | Should -Throw
            }
        }

        It 'Should throw meaningful error when not logged in to Azure' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                Mock Get-AzContext { return @{ Account = $null } }
                Mock Get-AzAccessToken { throw }
                Mock Write-Error { }

                # Act & Assert
                { New-AdoAuthHeader -ErrorAction Stop 2>$null } | Should -Throw '*login to Azure PowerShell*'
            }
        }

        It 'Should handle Get-AzAccessToken failure gracefully' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockContext = @{ Account = 'test@example.com' }
                Mock Get-AzContext { return $mockContext }
                Mock Get-AzAccessToken { throw 'Access token error' }

                # Act & Assert
                { New-AdoAuthHeader } | Should -Throw
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
                $script:header = $null
            }
        }

        It 'Should handle empty string PAT' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockAccessToken = 'fake-access-token-67890'
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
                $mockSecureToken = ConvertTo-SecureString -String $mockAccessToken -AsPlainText -Force
                $mockContext = @{ Account = 'test@example.com' }
                $mockTokenResponse = @{ token = $mockSecureToken }

                Mock Get-AzContext { return $mockContext }
                Mock Get-AzAccessToken { return $mockTokenResponse }

                # Act
                New-AdoAuthHeader -PAT ''

                # Assert
                $script:header.Authorization | Should -Match '^Bearer '
                Should -Invoke Get-AzAccessToken -Times 1
            }
        }

        It 'Should handle PAT with special characters' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $specialPAT = 'pat!@#$%^&*()_+-=[]{}|;:,.<>?'

                # Act
                New-AdoAuthHeader -PAT $specialPAT

                # Assert
                $script:header | Should -Not -BeNullOrEmpty
                $script:header.Authorization | Should -Match '^Basic '
            }
        }
    }
}
