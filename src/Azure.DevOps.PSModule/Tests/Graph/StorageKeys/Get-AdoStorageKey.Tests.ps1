BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoStorageKey' {
    BeforeAll {
        # Sample storage key response data for mocking
        $mockStorageKeyValue = '00000000-0000-0000-0000-000000000001'

        $mockStorageKeyResponse = @{
            value = $mockStorageKeyValue
        }

        $mockSubjectDescriptor = 'aad.NDUzOGJhZjItN2M2OS03YzhjLWJiY2QtOGEzZTg3NzEzZjY0'
        $mockCollectionUri = 'https://dev.azure.com/my-org'
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockStorageKeyResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should resolve a descriptor to its storage key' {
            # Act
            $result = Get-AdoStorageKey -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.value | Should -Be $mockStorageKeyValue
            $result.subjectDescriptor | Should -Be $mockSubjectDescriptor
            $result.collectionUri | Should -Be 'https://vssps.dev.azure.com/my-org'
        }

        It 'Should return PSCustomObject with expected properties' {
            # Act
            $result = Get-AdoStorageKey -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'subjectDescriptor'
            $result.PSObject.Properties.Name | Should -Contain 'value'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should construct API URI correctly' {
            # Act
            Get-AdoStorageKey -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq "https://vssps.dev.azure.com/my-org/_apis/graph/storagekeys/$mockSubjectDescriptor"
            }
        }

        It 'Should use GET method for API call' {
            # Act
            Get-AdoStorageKey -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'GET'
            }
        }

        It 'Should use default API version 7.2-preview.1' {
            # Act
            Get-AdoStorageKey -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should use specified API version when provided' {
            # Act
            Get-AdoStorageKey -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -Version '7.1-preview.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.1-preview.1'
            }
        }

        It 'Should use ApiVersion alias for Version parameter' {
            # Act
            Get-AdoStorageKey -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -ApiVersion '7.1-preview.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.1-preview.1'
            }
        }
    }

    Context 'Pipeline Support Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockStorageKeyResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should accept descriptor with collectionUri from pipeline' {
            # Arrange
            $objects = @(
                [PSCustomObject]@{ SubjectDescriptor = 'aad.00000000-0000-0000-0000-000000000001'; CollectionUri = $mockCollectionUri }
                [PSCustomObject]@{ SubjectDescriptor = 'aad.00000000-0000-0000-0000-000000000002'; CollectionUri = $mockCollectionUri }
                [PSCustomObject]@{ SubjectDescriptor = 'aad.00000000-0000-0000-0000-000000000003'; CollectionUri = $mockCollectionUri }
            )

            # Act
            $result = $objects | Get-AdoStorageKey

            # Assert
            $result | Should -HaveCount 3
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 3
        }

        It 'Should accept objects with SubjectDescriptor property from pipeline' {
            # Arrange
            $objects = @(
                [PSCustomObject]@{ SubjectDescriptor = 'aad.00000000-0000-0000-0000-000000000001' }
                [PSCustomObject]@{ SubjectDescriptor = 'aad.00000000-0000-0000-0000-000000000002' }
            )

            # Act
            $result = $objects | Get-AdoStorageKey -CollectionUri $mockCollectionUri

            # Assert
            $result | Should -HaveCount 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should handle StorageKeyNotFoundException gracefully with warning' {
            # Arrange
            $storageKeyNotFoundError = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Not found'),
                'StorageKeyNotFoundException',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )
            $storageKeyNotFoundError.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"StorageKeyNotFoundException: Storage key not found"}')

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $storageKeyNotFoundError }
            Mock -ModuleName Azure.DevOps.PSModule Write-Warning { }

            # Act
            $result = Get-AdoStorageKey -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Warning -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should propagate non-StorageKeyNotFoundException errors' {
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
            { Get-AdoStorageKey -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor } | Should -Throw
        }

        It 'Should return null when API returns null result' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return @{ value = $null } }

            # Act
            $result = Get-AdoStorageKey -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor

            # Assert
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'CollectionUri Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockStorageKeyResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should use environment default CollectionUri when not specified' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            Get-AdoStorageKey -SubjectDescriptor $mockSubjectDescriptor

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -match 'https://vssps.dev.azure.com/default-org'
            }
        }

        It 'Should accept vssps.dev.azure.com CollectionUri without modification' {
            # Arrange
            $vsspsUri = 'https://vssps.dev.azure.com/my-org'

            # Act
            Get-AdoStorageKey -CollectionUri $vsspsUri -SubjectDescriptor $mockSubjectDescriptor

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq "$vsspsUri/_apis/graph/storagekeys/$mockSubjectDescriptor"
            }
        }

        It 'Should transform dev.azure.com to vssps.dev.azure.com' {
            # Arrange
            $devAzureUri = 'https://dev.azure.com/my-org'
            $expectedUri = "https://vssps.dev.azure.com/my-org/_apis/graph/storagekeys/$mockSubjectDescriptor"

            # Act
            Get-AdoStorageKey -CollectionUri $devAzureUri -SubjectDescriptor $mockSubjectDescriptor

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq $expectedUri
            }
        }
    }
}
