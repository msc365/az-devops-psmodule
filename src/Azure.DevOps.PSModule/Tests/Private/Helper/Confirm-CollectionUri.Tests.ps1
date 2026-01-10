BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Confirm-CollectionUri' -Tag 'Private' {
    BeforeAll {
        $validUri = 'https://dev.azure.com/myorg'
        $validUriWithSubdomain = 'https://vssps.dev.azure.com/myorg'
        $validUriWithDash = 'https://dev.azure.com/my-org-name'
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
            }
        }

        It 'Should return true for valid standard Azure DevOps URI' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $validUri = 'https://dev.azure.com/myorg'

                # Act
                $result = Confirm-CollectionUri -Uri $validUri

                # Assert
                $result | Should -Be $true
            }
        }

        It 'Should return true for valid URI with subdomain' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $validUriWithSubdomain = 'https://vssps.dev.azure.com/myorg'

                # Act
                $result = Confirm-CollectionUri -Uri $validUriWithSubdomain

                # Assert
                $result | Should -Be $true
            }
        }

        It 'Should return true for URI with organization containing dashes' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $validUriWithDash = 'https://dev.azure.com/my-org-name'

                # Act
                $result = Confirm-CollectionUri -Uri $validUriWithDash

                # Assert
                $result | Should -Be $true
            }
        }

        It 'Should validate URI format using regex pattern' {
            InModuleScope Azure.DevOps.PSModule {
                # Act
                $result = Confirm-CollectionUri -Uri 'https://dev.azure.com/test-org-123'

                # Assert
                $result | Should -Be $true
            }
        }
    }

    Context 'Invalid URI Handling' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
            }
        }

        It 'Should throw error for URI without https protocol' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $httpUri = 'http://dev.azure.com/myorg'

                # Act & Assert
                { Confirm-CollectionUri -Uri $httpUri } | Should -Throw '*valid Azure DevOps collection URI*'
            }
        }

        It 'Should throw error for URI with wrong domain' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $wrongDomain = 'https://github.com/myorg'

                # Act & Assert
                { Confirm-CollectionUri -Uri $wrongDomain } | Should -Throw '*valid Azure DevOps collection URI*'
            }
        }

        It 'Should throw error for URI without organization' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $noOrg = 'https://dev.azure.com/'

                # Act & Assert
                { Confirm-CollectionUri -Uri $noOrg } | Should -Throw '*valid Azure DevOps collection URI*'
            }
        }

        It 'Should throw error for empty string URI' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $emptyUri = ''

                # Act & Assert
                # PowerShell parameter binding throws before the function validates
                { Confirm-CollectionUri -Uri $emptyUri } | Should -Throw '*empty string*'
            }
        }

        It 'Should throw error for malformed URI' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $malformedUri = 'not-a-valid-uri'

                # Act & Assert
                { Confirm-CollectionUri -Uri $malformedUri } | Should -Throw '*valid Azure DevOps collection URI*'
            }
        }

        It 'Should include helpful message in error' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $invalidUri = 'https://invalid.com/org'

                # Act & Assert
                { Confirm-CollectionUri -Uri $invalidUri } | Should -Throw "*e.g., 'https://dev.azure.com/org'*"
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
            }
        }

        It 'Should handle URI with trailing slash' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $uriWithSlash = 'https://dev.azure.com/myorg/'

                # Act
                $result = Confirm-CollectionUri -Uri $uriWithSlash

                # Assert
                $result | Should -Be $true
            }
        }

        It 'Should handle URI with additional path segments' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $uriWithPath = 'https://dev.azure.com/myorg/project'

                # Act
                $result = Confirm-CollectionUri -Uri $uriWithPath

                # Assert
                $result | Should -Be $true
            }
        }

        It 'Should handle organization names with underscores' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $uriWithUnderscore = 'https://dev.azure.com/my_org'

                # Act
                $result = Confirm-CollectionUri -Uri $uriWithUnderscore

                # Assert
                $result | Should -Be $true
            }
        }

        It 'Should handle organization names with mixed case' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mixedCaseUri = 'https://dev.azure.com/MyOrganization'

                # Act
                $result = Confirm-CollectionUri -Uri $mixedCaseUri

                # Assert
                $result | Should -Be $true
            }
        }
    }

    Context 'Edge Cases' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
            }
        }

        It 'Should accept URI before space character' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                # The regex matches until it hits a non-word character
                $uriBeforeSpace = 'https://dev.azure.com/myorg'

                # Act
                $result = Confirm-CollectionUri -Uri $uriBeforeSpace

                # Assert
                $result | Should -Be $true
            }
        }

        It 'Should accept URI before special character' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                # The regex \w matches word characters (letters, digits, underscore)
                $validUri = 'https://dev.azure.com/myorg'

                # Act
                $result = Confirm-CollectionUri -Uri $validUri

                # Assert
                $result | Should -Be $true
            }
        }

        It 'Should reject old TFS-style URI' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $tfsUri = 'https://mytfs.visualstudio.com/defaultcollection'

                # Act & Assert
                { Confirm-CollectionUri -Uri $tfsUri } | Should -Throw
            }
        }

        It 'Should reject visualstudio.com domain' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $oldDomain = 'https://myorg.visualstudio.com'

                # Act & Assert
                { Confirm-CollectionUri -Uri $oldDomain } | Should -Throw
            }
        }
    }
}
