BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoDescriptor' {
    BeforeAll {
        # Sample descriptor response data for mocking
        $mockDescriptorValue = 'aad.NDUzOGJhZjItN2M2OS03YzhjLWJiY2QtOGEzZTg3NzEzZjY0'

        $mockDescriptor = @{
            value = $mockDescriptorValue
        }

        $mockStorageKey = '00000000-0000-0000-0000-000000000001'
        $mockCollectionUri = 'https://vssps.dev.azure.com/my-org'
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockDescriptor }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should resolve a storage key to its descriptor' {
            # Act
            $result = Get-AdoDescriptor -CollectionUri $mockCollectionUri -StorageKey $mockStorageKey

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.value | Should -Be $mockDescriptorValue
            $result.storageKey | Should -Be $mockStorageKey
            $result.collectionUri | Should -Be $mockCollectionUri
        }

        It 'Should return PSCustomObject with expected properties' {
            # Act
            $result = Get-AdoDescriptor -CollectionUri $mockCollectionUri -StorageKey $mockStorageKey

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'storageKey'
            $result.PSObject.Properties.Name | Should -Contain 'value'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should construct API URI correctly' {
            # Act
            Get-AdoDescriptor -CollectionUri $mockCollectionUri -StorageKey $mockStorageKey

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq "$mockCollectionUri/_apis/graph/descriptors/$mockStorageKey"
            }
        }

        It 'Should use GET method for API call' {
            # Act
            Get-AdoDescriptor -CollectionUri $mockCollectionUri -StorageKey $mockStorageKey

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'GET'
            }
        }

        It 'Should use default API version 7.1' {
            # Act
            Get-AdoDescriptor -CollectionUri $mockCollectionUri -StorageKey $mockStorageKey

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should use specified API version when provided' {
            # Act
            Get-AdoDescriptor -CollectionUri $mockCollectionUri -StorageKey $mockStorageKey -Version '7.2-preview.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }
    }

    Context 'Pipeline Support Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockDescriptor }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should accept storage key from pipeline' {
            # Arrange
            $storageKeys = @(
                '00000000-0000-0000-0000-000000000001',
                '00000000-0000-0000-0000-000000000002',
                '00000000-0000-0000-0000-000000000003'
            )

            # Act
            $result = $storageKeys | Get-AdoDescriptor -CollectionUri $mockCollectionUri

            # Assert
            $result | Should -HaveCount 3
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 3
        }

        It 'Should accept objects with StorageKey property from pipeline' {
            # Arrange
            $objects = @(
                [PSCustomObject]@{ StorageKey = '00000000-0000-0000-0000-000000000001' }
                [PSCustomObject]@{ StorageKey = '00000000-0000-0000-0000-000000000002' }
            )

            # Act
            $result = $objects | Get-AdoDescriptor -CollectionUri $mockCollectionUri

            # Assert
            $result | Should -HaveCount 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should handle NotFoundExceptions gracefully with warning' {
            # Arrange
            $notFoundError = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Not found'),
                'NotFoundException',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )
            $notFoundError.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"NotFoundException: Storage key not found"}')

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $notFoundError }
            Mock -ModuleName Azure.DevOps.PSModule Write-Warning { }

            # Act
            $result = Get-AdoDescriptor -CollectionUri $mockCollectionUri -StorageKey 'nonexistent-key' -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Warning -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should propagate non-NotFoundException errors' {
            # Arrange
            $genericError = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Server error'),
                'ServerError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
            $genericError.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"Internal server error"}')

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $genericError }

            # Act & Assert
            { Get-AdoDescriptor -CollectionUri $mockCollectionUri -StorageKey $mockStorageKey } | Should -Throw
        }

        It 'Should return null when API returns null result' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return @{ value = $null } }

            # Act
            $result = Get-AdoDescriptor -CollectionUri $mockCollectionUri -StorageKey $mockStorageKey

            # Assert
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'CollectionUri Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockDescriptor }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should use environment default CollectionUri when not specified' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            Get-AdoDescriptor -StorageKey $mockStorageKey

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -match 'https://vssps.dev.azure.com/default-org'
            }
        }

        It 'Should accept vssps.dev.azure.com CollectionUri' {
            # Arrange
            $vsspsUri = 'https://vssps.dev.azure.com/my-org'

            # Act
            Get-AdoDescriptor -CollectionUri $vsspsUri -StorageKey $mockStorageKey

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq "$vsspsUri/_apis/graph/descriptors/$mockStorageKey"
            }
        }
    }
}
