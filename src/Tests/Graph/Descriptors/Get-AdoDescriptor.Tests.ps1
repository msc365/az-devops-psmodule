[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '', Scope = 'Function', Target = '*', Justification = 'Variables are used in nested It blocks')]
param()

BeforeAll {
    # Import the module for testing
    $moduleName = 'Azure.DevOps.PSModule'
    $modulePath = Join-Path -Path (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName -ChildPath $moduleName

    # Only remove and re-import if module is not loaded or loaded from different path
    $loadedModule = Get-Module -Name $moduleName -ErrorAction SilentlyContinue
    if ($loadedModule -and $loadedModule.Path -ne (Join-Path $modulePath "$moduleName.psm1")) {
        Remove-Module -Name $moduleName -Force
        $loadedModule = $null
    }

    # Import the module if not already loaded
    if (-not $loadedModule) {
        Import-Module $modulePath -Force -ErrorAction Stop
    }
}

Describe 'Get-AdoDescriptor' {

    Context 'When resolving a storage key to descriptor' {
        BeforeAll {
            # Mock Invoke-AdoRestMethod for successful responses
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri, $Method, $Version)

                return @{
                    value = 'aad.NTYzNDU2NzgtOTAxMi0zNDU2LTc4OTAtMTIzNDU2Nzg5MDEy'
                }
            }

            # Mock Confirm-Default
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
        }

        It 'Should resolve storage key to descriptor successfully' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $storageKey = '00000000-0000-0000-0000-000000000001'

            # Act
            $result = Get-AdoDescriptor -CollectionUri $collectionUri -StorageKey $storageKey

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.storageKey | Should -Be $storageKey
            $result.value | Should -Be 'aad.NTYzNDU2NzgtOTAxMi0zNDU2LTc4OTAtMTIzNDU2Nzg5MDEy'
            $result.collectionUri | Should -Be $collectionUri

            # Verify Invoke-AdoRestMethod was called correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/graph/descriptors/$storageKey" -and
                $Method -eq 'GET' -and
                $Version -eq '7.1'
            }
        }

        It 'Should use default API version 7.1 when not specified' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $storageKey = '00000000-0000-0000-0000-000000000001'

            # Act
            $result = Get-AdoDescriptor -CollectionUri $collectionUri -StorageKey $storageKey

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should use custom API version when specified' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $storageKey = '00000000-0000-0000-0000-000000000001'
            $version = '7.2-preview.1'

            # Act
            $result = Get-AdoDescriptor -CollectionUri $collectionUri -StorageKey $storageKey -Version $version

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should use default CollectionUri from environment variable when not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/envorg'
            $storageKey = '00000000-0000-0000-0000-000000000001'
            $expectedUri = 'https://vssps.dev.azure.com/envorg'

            # Act
            $result = Get-AdoDescriptor -StorageKey $storageKey

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$expectedUri/_apis/graph/descriptors/$storageKey"
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
        }

        It 'Should accept vssps CollectionUri directly' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $storageKey = '00000000-0000-0000-0000-000000000001'

            # Act
            $result = Get-AdoDescriptor -CollectionUri $collectionUri -StorageKey $storageKey

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/graph/descriptors/$storageKey"
            }
        }
    }

    Context 'When processing pipeline input' {
        BeforeAll {
            # Mock Invoke-AdoRestMethod for successful responses
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri, $Method, $Version)

                # Extract storage key from URI
                if ($Uri -match '/_apis/graph/descriptors/(.+)$') {
                    $key = $Matches[1]
                    return @{
                        value = "descriptor-for-$key"
                    }
                }
            }

            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
        }

        It 'Should process multiple storage keys from pipeline' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $storageKeys = @(
                '00000000-0000-0000-0000-000000000001',
                '00000000-0000-0000-0000-000000000002',
                '00000000-0000-0000-0000-000000000003'
            )

            # Act
            $result = $storageKeys | Get-AdoDescriptor -CollectionUri $collectionUri

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].storageKey | Should -Be $storageKeys[0]
            $result[1].storageKey | Should -Be $storageKeys[1]
            $result[2].storageKey | Should -Be $storageKeys[2]

            # Verify Invoke-AdoRestMethod was called for each storage key
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
        }

        It 'Should process storage keys from property pipeline' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $inputObjects = @(
                [PSCustomObject]@{ StorageKey = '00000000-0000-0000-0000-000000000001' },
                [PSCustomObject]@{ StorageKey = '00000000-0000-0000-0000-000000000002' }
            )

            # Act
            $result = $inputObjects | Get-AdoDescriptor -CollectionUri $collectionUri

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }

    Context 'Parameter validation' {
        It 'Should have StorageKey as a mandatory parameter' {
            # Arrange
            $command = Get-Command Get-AdoDescriptor

            # Act
            $storageKeyParam = $command.Parameters['StorageKey']

            # Assert
            $storageKeyParam.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should accept StorageKey from pipeline' {
            # Arrange
            $command = Get-Command Get-AdoDescriptor

            # Act
            $storageKeyParam = $command.Parameters['StorageKey']

            # Assert
            $storageKeyParam.Attributes.ValueFromPipeline | Should -Contain $true
        }

        It 'Should accept StorageKey from pipeline by property name' {
            # Arrange
            $command = Get-Command Get-AdoDescriptor

            # Act
            $storageKeyParam = $command.Parameters['StorageKey']

            # Assert
            $storageKeyParam.Attributes.ValueFromPipelineByPropertyName | Should -Contain $true
        }

        It 'Should have CollectionUri parameter with default value' {
            # Arrange
            $command = Get-Command Get-AdoDescriptor

            # Act
            $collectionUriParam = $command.Parameters['CollectionUri']

            # Assert
            $collectionUriParam | Should -Not -BeNullOrEmpty
            $collectionUriParam.Attributes.Mandatory | Should -Not -Contain $true
        }

        It 'Should accept CollectionUri from pipeline by property name' {
            # Arrange
            $command = Get-Command Get-AdoDescriptor

            # Act
            $collectionUriParam = $command.Parameters['CollectionUri']

            # Assert
            $collectionUriParam.Attributes.ValueFromPipelineByPropertyName | Should -Contain $true
        }

        It 'Should have Version parameter with ValidateSet' {
            # Arrange
            $command = Get-Command Get-AdoDescriptor

            # Act
            $versionParam = $command.Parameters['Version']
            $validateSet = $versionParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain '7.1'
            $validateSet.ValidValues | Should -Contain '7.2-preview.1'
        }

        It 'Should have ApiVersion as an alias for Version parameter' {
            # Arrange
            $command = Get-Command Get-AdoDescriptor

            # Act
            $versionParam = $command.Parameters['Version']
            $aliasAttribute = $versionParam.Attributes | Where-Object { $_ -is [System.Management.Automation.AliasAttribute] }

            # Assert
            $aliasAttribute | Should -Not -BeNullOrEmpty
            $aliasAttribute.AliasNames | Should -Contain 'ApiVersion'
        }

        It 'Should support ShouldProcess' {
            # Arrange
            $command = Get-Command Get-AdoDescriptor

            # Act & Assert
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'Error handling' {
        BeforeAll {
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
        }

        It 'Should handle NotFoundException error gracefully' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $storageKey = 'non-existent-key'

            # Mock error response that matches the function's catch block
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Subject descriptor not found'
                    typeKey = 'NotFoundException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Descriptor not found')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'NotFoundException',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert
            { Get-AdoDescriptor -CollectionUri $collectionUri -StorageKey $storageKey -WarningAction SilentlyContinue 3>&1 } | Should -Not -Throw

            # Verify warning was written
            $warning = Get-AdoDescriptor -CollectionUri $collectionUri -StorageKey $storageKey -WarningVariable capturedWarning -WarningAction SilentlyContinue
            $capturedWarning | Should -Match "StorageKey with ID $storageKey does not exist"
        }

        It 'Should throw exception for other error types' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $storageKey = '00000000-0000-0000-0000-000000000001'

            # Mock error response for a different error
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Unauthorized access'
                    typeKey = 'UnauthorizedAccessException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Unauthorized')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'Unauthorized',
                    [System.Management.Automation.ErrorCategory]::SecurityError,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert
            { Get-AdoDescriptor -CollectionUri $collectionUri -StorageKey $storageKey } | Should -Throw
        }

        It 'Should rethrow exception from process block' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $storageKey = '00000000-0000-0000-0000-000000000001'

            # Mock a generic exception
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Generic error'
            }

            # Act & Assert
            { Get-AdoDescriptor -CollectionUri $collectionUri -StorageKey $storageKey } | Should -Throw
        }

        It 'Should not return result when descriptor value is null' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $storageKey = '00000000-0000-0000-0000-000000000001'

            # Mock null response
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = $null
                }
            }

            # Act
            $result = Get-AdoDescriptor -CollectionUri $collectionUri -StorageKey $storageKey

            # Assert
            $result | Should -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'Output validation' {
        BeforeAll {
            # Mock Invoke-AdoRestMethod for successful responses
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = 'aad.NTYzNDU2NzgtOTAxMi0zNDU2LTc4OTAtMTIzNDU2Nzg5MDEy'
                }
            }

            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
        }

        It 'Should return PSCustomObject with expected properties' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $storageKey = '00000000-0000-0000-0000-000000000001'

            # Act
            $result = Get-AdoDescriptor -CollectionUri $collectionUri -StorageKey $storageKey

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.PSObject.Properties.Name | Should -Contain 'storageKey'
            $result.PSObject.Properties.Name | Should -Contain 'value'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should return correct property values' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $storageKey = '00000000-0000-0000-0000-000000000001'

            # Act
            $result = Get-AdoDescriptor -CollectionUri $collectionUri -StorageKey $storageKey

            # Assert
            $result.storageKey | Should -Be $storageKey
            $result.value | Should -Be 'aad.NTYzNDU2NzgtOTAxMi0zNDU2LTc4OTAtMTIzNDU2Nzg5MDEy'
            $result.collectionUri | Should -Be $collectionUri
        }

        It 'Should return string type for value property' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $storageKey = '00000000-0000-0000-0000-000000000001'

            # Act
            $result = Get-AdoDescriptor -CollectionUri $collectionUri -StorageKey $storageKey

            # Assert
            $result.value | Should -BeOfType [string]
        }
    }

    Context 'WhatIf support' {
        BeforeAll {
            # Mock Invoke-AdoRestMethod - should not be called with WhatIf
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = 'aad.NTYzNDU2NzgtOTAxMi0zNDU2LTc4OTAtMTIzNDU2Nzg5MDEy'
                }
            }

            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
        }

        It 'Should not call Invoke-AdoRestMethod when WhatIf is specified' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $storageKey = '00000000-0000-0000-0000-000000000001'

            # Act
            Get-AdoDescriptor -CollectionUri $collectionUri -StorageKey $storageKey -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }

    Context 'Integration scenarios' {
        BeforeAll {
            # Mock Invoke-AdoRestMethod for successful responses
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri)

                if ($Uri -match '/_apis/graph/descriptors/(.+)$') {
                    $key = $Matches[1]
                    return @{
                        value = "descriptor-$key"
                    }
                }
            }

            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
        }

        It 'Should handle multiple consecutive calls' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $storageKey1 = '00000000-0000-0000-0000-000000000001'
            $storageKey2 = '00000000-0000-0000-0000-000000000002'

            # Act
            $result1 = Get-AdoDescriptor -CollectionUri $collectionUri -StorageKey $storageKey1
            $result2 = Get-AdoDescriptor -CollectionUri $collectionUri -StorageKey $storageKey2

            # Assert
            $result1.storageKey | Should -Be $storageKey1
            $result2.storageKey | Should -Be $storageKey2
            $result1.value | Should -Be "descriptor-$storageKey1"
            $result2.value | Should -Be "descriptor-$storageKey2"
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }

        It 'Should work with splatted parameters' {
            # Arrange
            $params = @{
                CollectionUri = 'https://vssps.dev.azure.com/testorg'
                StorageKey    = '00000000-0000-0000-0000-000000000001'
                Version       = '7.2-preview.1'
            }

            # Act
            $result = Get-AdoDescriptor @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.storageKey | Should -Be $params.StorageKey
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }
    }
}
