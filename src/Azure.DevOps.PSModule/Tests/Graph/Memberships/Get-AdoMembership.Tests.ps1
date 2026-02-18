BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoMembership' {
    BeforeAll {
        # Sample response data for mocking
        $mockCollectionUri = 'https://vssps.dev.azure.com/my-org'
        $mockSubjectDescriptor = 'aadgp.00000000-0000-0000-0000-000000000001'
        $mockContainerDescriptor = 'vssgp.00000000-0000-0000-0000-000000000002'

        $mockMembership = [PSCustomObject]@{
            memberDescriptor    = 'aadgp.00000000-0000-0000-0000-000000000001'
            containerDescriptor = 'vssgp.00000000-0000-0000-0000-000000000002'
        }

        $mockMembershipsList = [PSCustomObject]@{
            value = @(
                [PSCustomObject]@{
                    memberDescriptor    = 'aadgp.00000000-0000-0000-0000-000000000001'
                    containerDescriptor = 'vssgp.00000000-0000-0000-0000-000000000003'
                }
                [PSCustomObject]@{
                    memberDescriptor    = 'aadgp.00000000-0000-0000-0000-000000000001'
                    containerDescriptor = 'vssgp.00000000-0000-0000-0000-000000000004'
                }
            )
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockMembership }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should retrieve membership relationship between subject and container' {
            # Act
            $result = Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -ContainerDescriptor $mockContainerDescriptor

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.memberDescriptor | Should -Be $mockSubjectDescriptor
            $result.containerDescriptor | Should -Be $mockContainerDescriptor
        }

        It 'Should return PSCustomObject with expected properties' {
            # Act
            $result = Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -ContainerDescriptor $mockContainerDescriptor

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'memberDescriptor'
            $result.PSObject.Properties.Name | Should -Contain 'containerDescriptor'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should construct API URI correctly' {
            # Act
            Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -ContainerDescriptor $mockContainerDescriptor

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq "$mockCollectionUri/_apis/graph/memberships/$mockSubjectDescriptor/$mockContainerDescriptor"
            }
        }

        It 'Should use GET method for API call' {
            # Act
            Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -ContainerDescriptor $mockContainerDescriptor

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'GET'
            }
        }

        It 'Should use default API version 7.1-preview.1' {
            # Act
            Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -ContainerDescriptor $mockContainerDescriptor

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.1-preview.1'
            }
        }

        It 'Should support custom API version' {
            # Act
            Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -ContainerDescriptor $mockContainerDescriptor -Version '7.2-preview.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should include CollectionUri in output' {
            # Act
            $result = Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -ContainerDescriptor $mockContainerDescriptor

            # Assert
            $result.collectionUri | Should -Be $mockCollectionUri
        }
    }

    Context 'Pipeline Support Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockMembership }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should accept SubjectDescriptor from pipeline' {
            # Arrange
            $subjects = @(
                'aadgp.00000000-0000-0000-0000-000000000003',
                'aadgp.00000000-0000-0000-0000-000000000004'
            )

            # Act
            $result = $subjects | Get-AdoMembership -CollectionUri $mockCollectionUri -ContainerDescriptor $mockContainerDescriptor

            # Assert
            $result | Should -HaveCount 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
        }

        It 'Should accept objects with SubjectDescriptor property from pipeline' {
            # Arrange
            $objects = @(
                [PSCustomObject]@{ SubjectDescriptor = 'aadgp.00000000-0000-0000-0000-000000000005' }
                [PSCustomObject]@{ SubjectDescriptor = 'aadgp.00000000-0000-0000-0000-000000000006' }
            )

            # Act
            $result = $objects | Get-AdoMembership -CollectionUri $mockCollectionUri -ContainerDescriptor $mockContainerDescriptor

            # Assert
            $result | Should -HaveCount 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
        }
    }

    Context 'ListMemberships Parameter Set Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockMembershipsList }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should retrieve memberships without ContainerDescriptor' {
            # Act
            $result = Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -Direction 'up'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 2
        }

        It 'Should construct API URI correctly without ContainerDescriptor' {
            # Act
            Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -Direction 'up'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq "$mockCollectionUri/_apis/graph/memberships/$mockSubjectDescriptor"
            }
        }

        It 'Should include Depth query parameter when specified' {
            # Act
            Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -Depth 2

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -eq 'depth=2'
            }
        }

        It 'Should include Direction query parameter when specified' {
            # Act
            Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -Direction 'up'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -eq 'direction=up'
            }
        }

        It 'Should include both Depth and Direction query parameters when specified' {
            # Act
            Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -Depth 2 -Direction 'down'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -eq 'depth=2&direction=down'
            }
        }

        It 'Should accept Direction value "up"' {
            # Act & Assert
            { Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -Direction 'up' } | Should -Not -Throw
        }

        It 'Should accept Direction value "down"' {
            # Act & Assert
            { Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -Direction 'down' } | Should -Not -Throw
        }

        It 'Should return multiple memberships from value array' {
            # Act
            $result = Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor $mockSubjectDescriptor -Depth 2

            # Assert
            $result | Should -HaveCount 2
            $result[0].memberDescriptor | Should -Be $mockSubjectDescriptor
            $result[1].memberDescriptor | Should -Be $mockSubjectDescriptor
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should propagate API errors' {
            # Arrange
            $apiError = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Membership not found'),
                'MembershipNotFound',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )
            $apiError.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"VS403289: The membership does not exist."}')

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $apiError }

            # Act & Assert
            { Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor 'invalid-subject' -ContainerDescriptor $mockContainerDescriptor } | Should -Throw
        }

        It 'Should handle invalid descriptor format errors' {
            # Arrange
            $invalidError = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Invalid descriptor'),
                'InvalidDescriptor',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $null
            )
            $invalidError.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"Invalid descriptor format"}')

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $invalidError }

            # Act & Assert
            { Get-AdoMembership -CollectionUri $mockCollectionUri -SubjectDescriptor 'malformed' -ContainerDescriptor $mockContainerDescriptor } | Should -Throw
        }
    }

    Context 'CollectionUri Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockMembership }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should use environment default CollectionUri when not specified' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            Get-AdoMembership -SubjectDescriptor $mockSubjectDescriptor -ContainerDescriptor $mockContainerDescriptor

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -match 'https://vssps.dev.azure.com/default-org'
            }
        }

        It 'Should work with vssps.dev.azure.com CollectionUri' {
            # Arrange
            $vsspsUri = 'https://vssps.dev.azure.com/test-org'

            # Act
            Get-AdoMembership -CollectionUri $vsspsUri -SubjectDescriptor $mockSubjectDescriptor -ContainerDescriptor $mockContainerDescriptor

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -match $vsspsUri
            }
        }
    }

    Context 'Required Parameter Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockMembership }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should have SubjectDescriptor as mandatory parameter' {
            # Arrange
            $param = (Get-Command Get-AdoMembership).Parameters['SubjectDescriptor']

            # Assert
            $param.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have ContainerDescriptor as optional parameter' {
            # Arrange
            $param = (Get-Command Get-AdoMembership).Parameters['ContainerDescriptor']

            # Assert
            $param.Attributes.Where({ $_.GetType().Name -eq 'ParameterAttribute' }).Mandatory | Should -Contain $false
        }

        It 'Should have Depth as optional parameter' {
            # Arrange
            $param = (Get-Command Get-AdoMembership).Parameters['Depth']

            # Assert
            $param.Attributes.Where({ $_.GetType().Name -eq 'ParameterAttribute' }).Mandatory | Should -Contain $false
        }

        It 'Should have Direction as optional parameter' {
            # Arrange
            $param = (Get-Command Get-AdoMembership).Parameters['Direction']

            # Assert
            $param.Attributes.Where({ $_.GetType().Name -eq 'ParameterAttribute' }).Mandatory | Should -Contain $false
        }
    }

    Context 'Parameter Set Tests' {
        It 'Should have GetMembership parameter set' {
            # Arrange
            $paramSets = (Get-Command Get-AdoMembership).ParameterSets

            # Assert
            $paramSets.Name | Should -Contain 'GetMembership'
        }

        It 'Should have ListMemberships parameter set' {
            # Arrange
            $paramSets = (Get-Command Get-AdoMembership).ParameterSets

            # Assert
            $paramSets.Name | Should -Contain 'ListMemberships'
        }

        It 'Should have ContainerDescriptor in GetMembership parameter set' {
            # Arrange
            $paramSet = (Get-Command Get-AdoMembership).ParameterSets | Where-Object { $_.Name -eq 'GetMembership' }
            $param = $paramSet.Parameters | Where-Object { $_.Name -eq 'ContainerDescriptor' }

            # Assert
            $param | Should -Not -BeNullOrEmpty
        }

        It 'Should have Depth in ListMemberships parameter set' {
            # Arrange
            $paramSet = (Get-Command Get-AdoMembership).ParameterSets | Where-Object { $_.Name -eq 'ListMemberships' }
            $param = $paramSet.Parameters | Where-Object { $_.Name -eq 'Depth' }

            # Assert
            $param | Should -Not -BeNullOrEmpty
        }

        It 'Should have Direction in ListMemberships parameter set' {
            # Arrange
            $paramSet = (Get-Command Get-AdoMembership).ParameterSets | Where-Object { $_.Name -eq 'ListMemberships' }
            $param = $paramSet.Parameters | Where-Object { $_.Name -eq 'Direction' }

            # Assert
            $param | Should -Not -BeNullOrEmpty
        }
    }
}
