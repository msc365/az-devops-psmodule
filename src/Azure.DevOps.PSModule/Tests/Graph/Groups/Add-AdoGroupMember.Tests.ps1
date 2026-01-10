BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Add-AdoGroupMember' {
    BeforeAll {
        # Sample response data for mocking
        $mockOriginId = '00000000-0000-0000-0000-000000000001'
        $mockGroupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000002'
        $mockCollectionUri = 'https://vssps.dev.azure.com/my-org'

        $mockGroupMemberResponse = [PSCustomObject]@{
            displayName   = 'Test Group'
            originId      = $mockOriginId
            principalName = '[TestOrg]\Test Group'
            origin        = 'aad'
            subjectKind   = 'group'
            descriptor    = 'aadgp.00000000-0000-0000-0000-000000000003'
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockGroupMemberResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should add an Entra ID group as member successfully' {
            # Act
            $result = Add-AdoGroupMember -CollectionUri $mockCollectionUri -GroupDescriptor $mockGroupDescriptor -OriginId $mockOriginId -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.displayName | Should -Be 'Test Group'
            $result.originId | Should -Be $mockOriginId
            $result.descriptor | Should -Be 'aadgp.00000000-0000-0000-0000-000000000003'
            $result.collectionUri | Should -Be $mockCollectionUri
        }

        It 'Should return PSCustomObject with expected properties' {
            # Act
            $result = Add-AdoGroupMember -CollectionUri $mockCollectionUri -GroupDescriptor $mockGroupDescriptor -OriginId $mockOriginId -Confirm:$false

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'displayName'
            $result.PSObject.Properties.Name | Should -Contain 'originId'
            $result.PSObject.Properties.Name | Should -Contain 'principalName'
            $result.PSObject.Properties.Name | Should -Contain 'origin'
            $result.PSObject.Properties.Name | Should -Contain 'subjectKind'
            $result.PSObject.Properties.Name | Should -Contain 'descriptor'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should construct API URI correctly' {
            # Act
            Add-AdoGroupMember -CollectionUri $mockCollectionUri -GroupDescriptor $mockGroupDescriptor -OriginId $mockOriginId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq "$mockCollectionUri/_apis/graph/groups"
            }
        }

        It 'Should use POST method for API call' {
            # Act
            Add-AdoGroupMember -CollectionUri $mockCollectionUri -GroupDescriptor $mockGroupDescriptor -OriginId $mockOriginId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Method -eq 'POST'
            }
        }

        It 'Should include groupDescriptors query parameter' {
            # Act
            Add-AdoGroupMember -CollectionUri $mockCollectionUri -GroupDescriptor $mockGroupDescriptor -OriginId $mockOriginId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -eq "groupDescriptors=$mockGroupDescriptor"
            }
        }

        It 'Should use default API version 7.2-preview.1' {
            # Act
            Add-AdoGroupMember -CollectionUri $mockCollectionUri -GroupDescriptor $mockGroupDescriptor -OriginId $mockOriginId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should use specified API version when provided' {
            # Act
            Add-AdoGroupMember -CollectionUri $mockCollectionUri -GroupDescriptor $mockGroupDescriptor -OriginId $mockOriginId -Version '7.1-preview.1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Version -eq '7.1-preview.1'
            }
        }
    }

    Context 'Pipeline Support Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockGroupMemberResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should accept OriginId from pipeline' {
            # Arrange
            $originIds = @(
                '00000000-0000-0000-0000-000000000001',
                '00000000-0000-0000-0000-000000000002',
                '00000000-0000-0000-0000-000000000003'
            )

            # Act
            $result = $originIds | Add-AdoGroupMember -CollectionUri $mockCollectionUri -GroupDescriptor $mockGroupDescriptor -Confirm:$false

            # Assert
            $result | Should -HaveCount 3
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 3
        }

        It 'Should accept objects with OriginId property from pipeline' {
            # Arrange
            $objects = @(
                [PSCustomObject]@{ OriginId = '00000000-0000-0000-0000-000000000001' }
                [PSCustomObject]@{ OriginId = '00000000-0000-0000-0000-000000000002' }
            )

            # Act
            $result = $objects | Add-AdoGroupMember -CollectionUri $mockCollectionUri -GroupDescriptor $mockGroupDescriptor -Confirm:$false

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

        It 'Should handle VS860016 error gracefully with warning' {
            # Arrange
            $notFoundError = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('OriginId not found'),
                'VS860016',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )
            $notFoundError.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"VS860016: Could not find originId in the backing domain"}')

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $notFoundError }
            Mock -ModuleName Azure.DevOps.PSModule Write-Warning { }

            # Act
            $result = Add-AdoGroupMember -CollectionUri $mockCollectionUri -GroupDescriptor $mockGroupDescriptor -OriginId 'invalid-id' -Confirm:$false -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Warning -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should handle TF50258 error gracefully with warning' {
            # Arrange
            $invalidGroupError = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Invalid group descriptor'),
                'TF50258',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $null
            )
            $invalidGroupError.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"TF50258: There is no group with the security identifier"}')

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $invalidGroupError }
            Mock -ModuleName Azure.DevOps.PSModule Write-Warning { }

            # Act
            $result = Add-AdoGroupMember -CollectionUri $mockCollectionUri -GroupDescriptor 'invalid-descriptor' -OriginId $mockOriginId -Confirm:$false -WarningAction SilentlyContinue

            # Assert
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Warning -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should handle FindGroupSidDoesNotExist error gracefully with warning' {
            # Arrange
            $sidError = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Group SID not found'),
                'FindGroupSidDoesNotExist',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )
            $sidError.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"FindGroupSidDoesNotExist: Security identifier not found"}')

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $sidError }
            Mock -ModuleName Azure.DevOps.PSModule Write-Warning { }

            # Act
            $result = Add-AdoGroupMember -CollectionUri $mockCollectionUri -GroupDescriptor $mockGroupDescriptor -OriginId $mockOriginId -Confirm:$false -WarningAction SilentlyContinue

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
            { Add-AdoGroupMember -CollectionUri $mockCollectionUri -GroupDescriptor $mockGroupDescriptor -OriginId $mockOriginId -Confirm:$false } | Should -Throw
        }
    }

    Context 'CollectionUri Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockGroupMemberResponse }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should use environment default CollectionUri when not specified' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            # Act
            Add-AdoGroupMember -GroupDescriptor $mockGroupDescriptor -OriginId $mockOriginId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -match 'https://vssps.dev.azure.com/default-org'
            }
        }

        It 'Should work with vssps.dev.azure.com CollectionUri' {
            # Arrange
            $vsspsUri = 'https://vssps.dev.azure.com/test-org'

            # Act
            Add-AdoGroupMember -CollectionUri $vsspsUri -GroupDescriptor $mockGroupDescriptor -OriginId $mockOriginId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq "$vsspsUri/_apis/graph/groups"
            }
        }
    }
}
