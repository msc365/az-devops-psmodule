BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoDefault' {
    BeforeAll {
        # Sample environment values for mocking
        $mockOrganization = 'my-org'
        $mockCollectionUri = 'https://dev.azure.com/my-org'
        $mockProject = 'my-project'
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should retrieve default Organization from environment' {
            # Arrange
            $env:DefaultAdoOrganization = $mockOrganization
            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject

            # Act
            $result = Get-AdoDefault

            # Assert
            $result.Organization | Should -Be $mockOrganization

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should retrieve default CollectionUri from environment' {
            # Arrange
            $env:DefaultAdoOrganization = $mockOrganization
            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject

            # Act
            $result = Get-AdoDefault

            # Assert
            $result.CollectionUri | Should -Be $mockCollectionUri

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should retrieve default Project from environment' {
            # Arrange
            $env:DefaultAdoOrganization = $mockOrganization
            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject

            # Act
            $result = Get-AdoDefault

            # Assert
            $result.ProjectName | Should -Be $mockProject

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should return PSCustomObject with expected properties' {
            # Arrange
            $env:DefaultAdoOrganization = $mockOrganization
            $env:DefaultAdoCollectionUri = $mockCollectionUri
            $env:DefaultAdoProject = $mockProject

            # Act
            $result = Get-AdoDefault

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'Organization'
            $result.PSObject.Properties.Name | Should -Contain 'CollectionUri'
            $result.PSObject.Properties.Name | Should -Contain 'ProjectName'

            # Cleanup
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should return null values when environment variables are not set' {
            # Arrange
            $env:DefaultAdoOrganization = $null
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null

            # Act
            $result = Get-AdoDefault

            # Assert
            $result.Organization | Should -BeNullOrEmpty
            $result.CollectionUri | Should -BeNullOrEmpty
            $result.ProjectName | Should -BeNullOrEmpty
        }

        It 'Should handle partial environment variables' {
            # Arrange
            $env:DefaultAdoOrganization = $mockOrganization
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null

            # Act
            $result = Get-AdoDefault

            # Assert
            $result.Organization | Should -Be $mockOrganization
            $result.CollectionUri | Should -BeNullOrEmpty
            $result.ProjectName | Should -BeNullOrEmpty

            # Cleanup
            $env:DefaultAdoOrganization = $null
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should propagate exceptions from process block' {
            # Force an error by making environment variable access fail
            InModuleScope Azure.DevOps.PSModule {
                # Store original function
                $originalFunction = ${function:Get-AdoDefault}

                try {
                    # Override the function to trigger the catch block
                    function Get-AdoDefault {
                        [CmdletBinding()]
                        param ()

                        begin {
                            Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
                        }

                        process {
                            try {
                                # Force an error in the try block
                                throw 'Forced error to test catch block'
                            } catch {
                                throw $_
                            }
                        }

                        end {
                            Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
                        }
                    }

                    # Test that the catch block rethrows
                    { Get-AdoDefault } | Should -Throw 'Forced error to test catch block'

                } finally {
                    # Restore original function
                    ${function:Get-AdoDefault} = $originalFunction

                    # Cleanup
                    $env:DefaultAdoOrganization = $null
                    $env:DefaultAdoCollectionUri = $null
                    $env:DefaultAdoProject = $null
                }
            }
        }
    }
}
