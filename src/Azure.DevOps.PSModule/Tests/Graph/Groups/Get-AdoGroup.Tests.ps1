BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoGroup' {
    BeforeAll {
        # Sample response data for mocking
        $mockCollectionUri = 'https://vssps.dev.azure.com/my-org'
        $mockGroupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
        $mockScopeDescriptor = 'scp.00000000-0000-0000-0000-000000000002'

        $mockGroup1 = [PSCustomObject]@{
            subjectKind   = 'group'
            description   = 'Admin group'
            domain        = 'vstfs://Classification/TeamProject/00000000-0000-0000-0000-000000000001'
            principalName = '[TestProject]\Project Administrators'
            mailAddress   = $null
            origin        = 'vsts'
            originId      = '00000000-0000-0000-0000-000000000001'
            displayName   = 'Project Administrators'
            descriptor    = 'vssgp.00000000-0000-0000-0000-000000000001'
        }

        $mockGroup2 = [PSCustomObject]@{
            subjectKind   = 'group'
            description   = 'Contributor group'
            domain        = 'vstfs://Classification/TeamProject/00000000-0000-0000-0000-000000000002'
            principalName = '[TestProject]\Contributors'
            mailAddress   = $null
            origin        = 'vsts'
            originId      = '00000000-0000-0000-0000-000000000002'
            displayName   = 'Contributors'
            descriptor    = 'vssgp.00000000-0000-0000-0000-000000000002'
        }

        $mockListResponse = [PSCustomObject]@{
            value = @($mockGroup1, $mockGroup2)
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockListResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should retrieve all groups in organization' {
            # Act
            $result = Get-AdoGroup -CollectionUri $mockCollectionUri

            # Assert
            $result | Should -HaveCount 2
            $result[0].displayName | Should -Be 'Project Administrators'
            $result[1].displayName | Should -Be 'Contributors'
        }

        It 'Should return PSCustomObject with expected properties' {
            # Act
            $result = Get-AdoGroup -CollectionUri $mockCollectionUri

            # Assert
            $result[0].PSObject.Properties.Name | Should -Contain 'subjectKind'
            $result[0].PSObject.Properties.Name | Should -Contain 'description'
            $result[0].PSObject.Properties.Name | Should -Contain 'domain'
            $result[0].PSObject.Properties.Name | Should -Contain 'principalName'
            $result[0].PSObject.Properties.Name | Should -Contain 'mailAddress'
            $result[0].PSObject.Properties.Name | Should -Contain 'origin'
            $result[0].PSObject.Properties.Name | Should -Contain 'originId'
            $result[0].PSObject.Properties.Name | Should -Contain 'displayName'
            $result[0].PSObject.Properties.Name | Should -Contain 'descriptor'
            $result[0].PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should construct API URI correctly for listing groups' {
            # Act
            Get-AdoGroup -CollectionUri $mockCollectionUri

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq "$mockCollectionUri/_apis/graph/groups"
            }
        }

        It 'Should use GET method for API call' {
            # Act
            Get-AdoGroup -CollectionUri $mockCollectionUri

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'GET'
            }
        }

        It 'Should use default API version 7.2-preview.1' {
            # Act
            Get-AdoGroup -CollectionUri $mockCollectionUri

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should filter groups by Name parameter' {
            # Act
            $result = Get-AdoGroup -CollectionUri $mockCollectionUri -Name 'Project Administrators'

            # Assert
            $result | Should -HaveCount 1
            $result.displayName | Should -Be 'Project Administrators'
        }

        It 'Should support wildcard filtering by name' {
            # Act
            $result = Get-AdoGroup -CollectionUri $mockCollectionUri -Name '*Admin*'

            # Assert
            $result | Should -HaveCount 1
            $result.displayName | Should -Be 'Project Administrators'
        }

        It 'Should automatically iterate continuation tokens when listing groups' {
            # Arrange
            $firstPage = [PSCustomObject]@{
                value             = @($mockGroup1)
                continuationToken = 'token123'
            }
            $secondPage = [PSCustomObject]@{
                value             = @($mockGroup2)
                continuationToken = $null
            }
            $script:groupCallCount = 0

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                $script:groupCallCount++
                if ($script:groupCallCount -eq 1) {
                    return $firstPage
                }
                return $secondPage
            }

            # Act
            $result = Get-AdoGroup -CollectionUri $mockCollectionUri -SubjectTypes @('vssgp')

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
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockGroup1 }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should retrieve group by descriptor using ByDescriptor parameter set' {
            # Act
            $result = Get-AdoGroup -CollectionUri $mockCollectionUri -GroupDescriptor $mockGroupDescriptor

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.descriptor | Should -Be $mockGroupDescriptor
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq "$mockCollectionUri/_apis/graph/groups/$mockGroupDescriptor"
            }
        }

        It 'Should include scopeDescriptor query parameter when specified' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockListResponse }

            # Act
            Get-AdoGroup -CollectionUri $mockCollectionUri -ScopeDescriptor $mockScopeDescriptor

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -match "scopeDescriptor=$mockScopeDescriptor"
            }
        }

        It 'Should include subjectTypes query parameter' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockListResponse }

            # Act
            Get-AdoGroup -CollectionUri $mockCollectionUri -SubjectTypes @('vssgp', 'aadgp')

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -match 'subjectTypes=vssgp,aadgp'
            }
        }

    }

    Context 'Pipeline Support Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockGroup1 }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should accept GroupDescriptor from pipeline' {
            # Arrange
            $descriptors = @(
                'vssgp.00000000-0000-0000-0000-000000000001',
                'vssgp.00000000-0000-0000-0000-000000000002'
            )

            # Act
            $result = $descriptors | Get-AdoGroup -CollectionUri $mockCollectionUri

            # Assert
            $result | Should -HaveCount 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
        }

        It 'Should accept objects with GroupDescriptor property from pipeline' {
            # Arrange
            $objects = @(
                [PSCustomObject]@{ GroupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001' }
                [PSCustomObject]@{ GroupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000002' }
            )

            # Act
            $result = $objects | Get-AdoGroup -CollectionUri $mockCollectionUri

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
            $result = Get-AdoGroup -CollectionUri $mockCollectionUri -ScopeDescriptor 'invalid-scope' -WarningAction SilentlyContinue

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
            $result = Get-AdoGroup -CollectionUri $mockCollectionUri -GroupDescriptor 'invalid-descriptor' -WarningAction SilentlyContinue

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
            { Get-AdoGroup -CollectionUri $mockCollectionUri } | Should -Throw
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
            Get-AdoGroup

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -match 'https://vssps.dev.azure.com/default-org'
            }
        }

        It 'Should work with vssps.dev.azure.com CollectionUri' {
            # Arrange
            $vsspsUri = 'https://vssps.dev.azure.com/test-org'

            # Act
            Get-AdoGroup -CollectionUri $vsspsUri

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq "$vsspsUri/_apis/graph/groups"
            }
        }
    }
}
