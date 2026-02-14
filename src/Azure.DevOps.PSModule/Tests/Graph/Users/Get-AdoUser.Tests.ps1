BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoUser' {
    BeforeAll {
        # Sample response data for mocking
        $mockCollectionUri = 'https://vssps.dev.azure.com/my-org'
        $mockUserDescriptor = 'aad.00000000-0000-0000-0000-000000000001'
        $mockScopeDescriptor = 'scp.00000000-0000-0000-0000-000000000002'

        $mockUser1 = [PSCustomObject]@{
            subjectKind       = 'user'
            directoryAlias    = 'testuser1'
            domain            = '00000000-0000-0000-0000-000000000001'
            principalName     = 'testuser1@domain.com'
            mailAddress       = 'test.user1@domain.com'
            origin            = 'aad'
            originId          = '00000000-0000-0000-0000-000000000001'
            displayName       = 'User1, Test'
            descriptor        = 'aad.00000000-0000-0000-0000-000000000001'
            isDeletedInOrigin = $null
            metaType          = 'member'
        }

        $mockUser2 = [PSCustomObject]@{
            subjectKind       = 'user'
            directoryAlias    = 'testuser2'
            domain            = '00000000-0000-0000-0000-000000000002'
            principalName     = 'testuser2@domain.com'
            mailAddress       = 'test.user2@domain.com'
            origin            = 'aad'
            originId          = '00000000-0000-0000-0000-000000000002'
            displayName       = 'User2, Test'
            descriptor        = 'aad.00000000-0000-0000-0000-000000000002'
            isDeletedInOrigin = $null
            metaType          = 'guest'
        }

        $mockListResponse = [PSCustomObject]@{
            value = @($mockUser1, $mockUser2)
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockListResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should retrieve all users in organization' {
            # Act
            $result = Get-AdoUser -CollectionUri $mockCollectionUri

            # Assert
            $result | Should -HaveCount 2
            $result[0].displayName | Should -Be 'User1, Test'
            $result[1].displayName | Should -Be 'User2, Test'
        }

        It 'Should return PSCustomObject with expected properties' {
            # Act
            $result = Get-AdoUser -CollectionUri $mockCollectionUri

            # Assert
            $result[0].PSObject.Properties.Name | Should -Contain 'subjectKind'
            $result[0].PSObject.Properties.Name | Should -Contain 'directoryAlias'
            $result[0].PSObject.Properties.Name | Should -Contain 'domain'
            $result[0].PSObject.Properties.Name | Should -Contain 'principalName'
            $result[0].PSObject.Properties.Name | Should -Contain 'mailAddress'
            $result[0].PSObject.Properties.Name | Should -Contain 'origin'
            $result[0].PSObject.Properties.Name | Should -Contain 'originId'
            $result[0].PSObject.Properties.Name | Should -Contain 'displayName'
            $result[0].PSObject.Properties.Name | Should -Contain 'isDeletedInOrigin'
            $result[0].PSObject.Properties.Name | Should -Contain 'metaType'
            $result[0].PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should construct API URI correctly for listing users' {
            # Act
            Get-AdoUser -CollectionUri $mockCollectionUri

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq "$mockCollectionUri/_apis/graph/users"
            }
        }

        It 'Should use GET method for API call' {
            # Act
            Get-AdoUser -CollectionUri $mockCollectionUri

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'GET'
            }
        }

        It 'Should use default API version 7.2-preview.1' {
            # Act
            Get-AdoUser -CollectionUri $mockCollectionUri

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should filter users by Name parameter' {
            # Act
            $result = Get-AdoUser -CollectionUri $mockCollectionUri -Name 'User1, Test'

            # Assert
            $result | Should -HaveCount 1
            $result.displayName | Should -Be 'User1, Test'
        }

        It 'Should support wildcard filtering by name' {
            # Act
            $result = Get-AdoUser -CollectionUri $mockCollectionUri -Name '*User1*'

            # Assert
            $result | Should -HaveCount 1
            $result.displayName | Should -Be 'User1, Test'
        }

        It 'Should automatically iterate continuation tokens when listing users' {
            # Arrange
            $firstPage = [PSCustomObject]@{
                value             = @($mockUser1)
                continuationToken = 'token123'
            }
            $secondPage = [PSCustomObject]@{
                value             = @($mockUser2)
                continuationToken = $null
            }
            $script:userCallCount = 0

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                $script:userCallCount++
                if ($script:userCallCount -eq 1) {
                    return $firstPage
                }
                return $secondPage
            }

            # Act
            $result = Get-AdoUser -CollectionUri $mockCollectionUri -SubjectTypes @('aad')

            # Assert
            $result | Should -HaveCount 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -ParameterFilter {
                $QueryParameters -match 'continuationToken=token123'
            }
        }
    }

    Context 'Parameter Set Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockUser1 }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should retrieve group by descriptor using ByDescriptor parameter set' {
            # Act
            $result = Get-AdoUser -CollectionUri $mockCollectionUri -UserDescriptor $mockUserDescriptor

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.descriptor | Should -Be $mockUserDescriptor
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq "$mockCollectionUri/_apis/graph/users/$mockUserDescriptor"
            }
        }

        It 'Should include scopeDescriptor query parameter when specified' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockListResponse }

            # Act
            Get-AdoUser -CollectionUri $mockCollectionUri -ScopeDescriptor $mockScopeDescriptor

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -match "scopeDescriptor=$mockScopeDescriptor"
            }
        }

        It 'Should include subjectTypes query parameter' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockListResponse }

            # Act
            Get-AdoUser -CollectionUri $mockCollectionUri -SubjectTypes @('aad', 'svc')

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -match 'subjectTypes=aad,svc'
            }
        }

    }

    Context 'Pipeline Support Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockUser1 }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should accept UserDescriptor from pipeline' {
            # Arrange
            $descriptors = @(
                'aad.00000000-0000-0000-0000-000000000001',
                'aad.00000000-0000-0000-0000-000000000002'
            )

            # Act
            $result = $descriptors | Get-AdoUser -CollectionUri $mockCollectionUri

            # Assert
            $result | Should -HaveCount 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
        }

        It 'Should accept objects with UserDescriptor property from pipeline' {
            # Arrange
            $objects = @(
                [PSCustomObject]@{ UserDescriptor = 'aad.00000000-0000-0000-0000-000000000001' }
                [PSCustomObject]@{ UserDescriptor = 'aad.00000000-0000-0000-0000-000000000002' }
            )

            # Act
            $result = $objects | Get-AdoUser -CollectionUri $mockCollectionUri

            # Assert
            $result | Should -HaveCount 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should handle InvalidSubjectTypeException gracefully with warning' {
            # Arrange
            $invalidSubjectError = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Invalid subject type'),
                'InvalidSubjectTypeException',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $null
            )
            $invalidSubjectError.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"InvalidSubjectTypeException: Subject does not exist"}')

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $invalidSubjectError }
            Mock -ModuleName Azure.DevOps.PSModule Write-Warning { }

            # Act
            $result = Get-AdoUser -CollectionUri $mockCollectionUri -ScopeDescriptor 'invalid-scope' -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Warning -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should handle GraphSubjectNotFoundException gracefully with warning' {
            # Arrange
            $notFoundError = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Subject not found'),
                'GraphSubjectNotFoundException',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )
            $notFoundError.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"GraphSubjectNotFoundException: Group descriptor not found"}')

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $notFoundError }
            Mock -ModuleName Azure.DevOps.PSModule Write-Warning { }

            # Act
            $result = Get-AdoUser -CollectionUri $mockCollectionUri -UserDescriptor 'invalid-descriptor' -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Warning -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should propagate unexpected errors' {
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
            { Get-AdoUser -CollectionUri $mockCollectionUri } | Should -Throw
        }
    }

    Context 'CollectionUri Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockListResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should use environment default CollectionUri when not specified' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            Get-AdoUser

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -match 'https://vssps.dev.azure.com/default-org'
            }
        }

        It 'Should work with vssps.dev.azure.com CollectionUri' {
            # Arrange
            $vsspsUri = 'https://vssps.dev.azure.com/test-org'

            # Act
            Get-AdoUser -CollectionUri $vsspsUri

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq "$vsspsUri/_apis/graph/users"
            }
        }
    }
}
