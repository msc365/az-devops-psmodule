BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Set-AdoDefault' {
    BeforeAll {
        # Sample values for testing
        $mockOrganization = 'my-org'
        $mockProject = 'my-project'
        $expectedCollectionUri = "https://dev.azure.com/$mockOrganization"
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            # Clean up environment variables before each test
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should set Organization environment variable' {
            # Act
            $result = Set-AdoDefault -Organization $mockOrganization -Project $mockProject -Confirm:$false

            # Assert
            $env:DefaultAdoOrganization | Should -Be $mockOrganization
            $result.Organization | Should -Be $mockOrganization

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should set CollectionUri environment variable based on Organization' {
            # Act
            $result = Set-AdoDefault -Organization $mockOrganization -Project $mockProject -Confirm:$false

            # Assert
            $env:DefaultAdoCollectionUri | Should -Be $expectedCollectionUri
            $result.CollectionUri | Should -Be $expectedCollectionUri

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should set Project environment variable' {
            # Act
            $result = Set-AdoDefault -Organization $mockOrganization -Project $mockProject -Confirm:$false

            # Assert
            $env:DefaultAdoProject | Should -Be $mockProject
            $result.ProjectName | Should -Be $mockProject

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should return PSCustomObject with expected properties' {
            # Act
            $result = Set-AdoDefault -Organization $mockOrganization -Project $mockProject -Confirm:$false

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'Organization'
            $result.PSObject.Properties.Name | Should -Contain 'CollectionUri'
            $result.PSObject.Properties.Name | Should -Contain 'ProjectName'

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should set all environment variables correctly in single call' {
            # Act
            Set-AdoDefault -Organization $mockOrganization -Project $mockProject -Confirm:$false

            # Assert
            $env:DefaultAdoOrganization | Should -Be $mockOrganization
            $env:DefaultAdoCollectionUri | Should -Be $expectedCollectionUri
            $env:DefaultAdoProject | Should -Be $mockProject

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }
    }

    Context 'Null Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            # Set initial values
            $env:DefaultAdoOrganization = $mockOrganization
            $env:DefaultAdoCollectionUri = $expectedCollectionUri
            $env:DefaultAdoProject = $mockProject
        }

        It 'Should clear Organization when set to null' {
            # Act
            Set-AdoDefault -Organization $null -Project $mockProject -Confirm:$false

            # Assert
            $env:DefaultAdoOrganization | Should -BeNullOrEmpty

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should clear Project when set to null' {
            # Act
            Set-AdoDefault -Organization $mockOrganization -Project $null -Confirm:$false

            # Assert
            $env:DefaultAdoProject | Should -BeNullOrEmpty

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should clear all environment variables when both parameters are null' {
            # Act
            Set-AdoDefault -Organization $null -Project $null -Confirm:$false

            # Assert
            $env:DefaultAdoOrganization | Should -BeNullOrEmpty
            $env:DefaultAdoCollectionUri | Should -Match 'https://dev.azure.com/$'
            $env:DefaultAdoProject | Should -BeNullOrEmpty

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should handle empty string for Organization' {
            # Act
            Set-AdoDefault -Organization '' -Project $mockProject -Confirm:$false

            # Assert
            $env:DefaultAdoOrganization | Should -Be ''
            $env:DefaultAdoCollectionUri | Should -Be 'https://dev.azure.com/'

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }
    }

    Context 'ShouldProcess Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should make changes when Confirm is bypassed' {
            # Act
            Set-AdoDefault -Organization $mockOrganization -Project $mockProject -Confirm:$false

            # Assert
            $env:DefaultAdoOrganization | Should -Be $mockOrganization

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }
    }

    Context 'Parameter Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should accept Organization parameter' {
            # Act & Assert
            { Set-AdoDefault -Organization $mockOrganization -Confirm:$false } | Should -Not -Throw

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should accept Project parameter' {
            # Act & Assert
            { Set-AdoDefault -Project $mockProject -Confirm:$false } | Should -Not -Throw

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should accept both parameters' {
            # Act & Assert
            { Set-AdoDefault -Organization $mockOrganization -Project $mockProject -Confirm:$false } | Should -Not -Throw

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
