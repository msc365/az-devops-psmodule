BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Remove-AdoDefault' {
    BeforeAll {
        # Sample values for testing
        $mockOrganization = 'my-org'
        $mockProject = 'my-project'
        $mockCollectionUri = "https://dev.azure.com/$mockOrganization"
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            # Set initial environment variables
            $env:DefaultAdoOrganization = $mockOrganization
            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        It 'Should remove all default environment variables' {
            # Act
            Remove-AdoDefault

            # Assert
            $env:DefaultAdoOrganization | Should -BeNullOrEmpty
            $env:DefaultAdoProject | Should -BeNullOrEmpty

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should handle when environment variables are already null' {
            # Arrange
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null

            # Act & Assert
            { Remove-AdoDefault } | Should -Not -Throw

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should call Set-AdoDefault internally' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Set-AdoDefault { }

            # Act
            Remove-AdoDefault

            # Assert
            Should -Invoke Set-AdoDefault -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            $env:DefaultAdoOrganization = $mockOrganization
            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        It 'Should propagate exceptions from Set-AdoDefault' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Set-AdoDefault {
                throw 'Simulated Set-AdoDefault error'
            }

            # Act & Assert
            { Remove-AdoDefault -ErrorAction Stop } | Should -Throw 'Simulated Set-AdoDefault error'
        }
    }

    Context 'Integration Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            # Set initial values
            $env:DefaultAdoOrganization = $mockOrganization
            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        It 'Should clear Organization environment variable' {
            # Act
            Remove-AdoDefault

            # Assert
            $env:DefaultAdoOrganization | Should -BeNullOrEmpty

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should clear Project environment variable' {
            # Act
            Remove-AdoDefault

            # Assert
            $env:DefaultAdoProject | Should -BeNullOrEmpty

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should return result from Set-AdoDefault' {
            # Act
            $result = Remove-AdoDefault

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Organization | Should -BeNullOrEmpty
            $result.Project | Should -BeNullOrEmpty

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }
    }

    AfterAll {
        # Final cleanup
        $env:DefaultAdoOrganization = $null
        $env:DefaultAdoCollectionUri = $null
        $env:DefaultAdoProject = $null
    }
}

