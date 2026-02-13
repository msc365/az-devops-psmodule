BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'New-AdoCheckApproval' {
    BeforeAll {
        $mockEnvironment = @{ id = 1; name = 'TestEnvironment' }
        $mockCreatedConfiguration = @{
            id        = 1
            timeout   = 1440
            type      = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d'; name = 'Approval' }
            settings  = @{
                approvers            = @(@{ id = 'user1' })
                definitionRef        = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
                minRequiredApprovers = 0
            }
            resource  = @{ type = 'environment'; id = '1' }
            createdBy = @{ id = 'creator1' }
            createdOn = '2024-01-01T00:00:00Z'
        }
        $mockDefinitionRef = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d'; name = 'approval' }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoEnvironment { return $mockEnvironment }
            Mock -ModuleName Azure.DevOps.PSModule Resolve-AdoDefinitionRef { return $mockDefinitionRef }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoCheckConfiguration { return @{ value = @() } }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCreatedConfiguration }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should create approval check with required parameters' {
            # Arrange
            $approvers = @(@{ id = '00000000-0000-0000-0000-000000000001' })

            # Act
            $result = New-AdoCheckApproval -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Approvers $approvers -ResourceType 'environment' -ResourceName 'TestEnvironment' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should create approval check with all optional parameters' {
            # Arrange
            $approvers = @(@{ id = '00000000-0000-0000-0000-000000000001' })

            # Act
            $result = New-AdoCheckApproval -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Approvers $approvers -ResourceType 'environment' -ResourceName 'TestEnvironment' -DefinitionType 'preCheckApproval' -Instructions 'Approve this' -MinRequiredApprovers 1 -ExecutionOrder 'inSequence' -RequesterCannotBeApprover $true -Timeout 2880 -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should accept resource names via pipeline' {
            # Arrange
            $approvers = @(@{ id = '00000000-0000-0000-0000-000000000001' })

            # Act
            $result = [PSCustomObject]@{ ResourceName = 'TestEnvironment' } | New-AdoCheckApproval -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Approvers $approvers -ResourceType 'environment' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should call Get-AdoEnvironment to resolve resource ID' {
            # Arrange
            $approvers = @(@{ id = '00000000-0000-0000-0000-000000000001' })

            # Act
            New-AdoCheckApproval -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Approvers $approvers -ResourceType 'environment' -ResourceName 'TestEnvironment' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoEnvironment -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should call Resolve-AdoDefinitionRef to get definition reference' {
            # Arrange
            $approvers = @(@{ id = '00000000-0000-0000-0000-000000000001' })

            # Act
            New-AdoCheckApproval -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Approvers $approvers -ResourceType 'environment' -ResourceName 'TestEnvironment' -DefinitionType 'approval' -Confirm:$false

            # Assert
            Should -Invoke Resolve-AdoDefinitionRef -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoEnvironment { return $mockEnvironment }
            Mock -ModuleName Azure.DevOps.PSModule Resolve-AdoDefinitionRef { return $mockDefinitionRef }
            Mock -ModuleName Azure.DevOps.PSModule New-AdoCheckConfiguration { return $mockCreatedConfiguration }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoCheckConfiguration { return @{ value = @() } }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCreatedConfiguration }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            # Arrange
            $approvers = @(@{ id = '00000000-0000-0000-0000-000000000001' })

            # Act & Assert
            { New-AdoCheckApproval -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -Approvers $approvers -ResourceType 'environment' -ResourceName 'TestEnv' -Confirm:$false } | Should -Throw
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoCheckConfiguration { return @{ value = @() } }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'Response status code does not indicate success: 401 (Unauthorized).' }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should propagate errors from Invoke-AdoRestMethod' {
            # Arrange
            $approvers = @(@{ id = '00000000-0000-0000-0000-000000000001' })
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoEnvironment { return $mockEnvironment }
            Mock -ModuleName Azure.DevOps.PSModule Resolve-AdoDefinitionRef { return $mockDefinitionRef }

            # Act & Assert
            { New-AdoCheckApproval -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Approvers $approvers -ResourceType 'environment' -ResourceName 'TestEnvironment' -Confirm:$false } | Should -Throw '*Unauthorized*'
        }
    }

    Context 'ParameterSet Tests - ResourceId' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Resolve-AdoDefinitionRef { return $mockDefinitionRef }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoCheckConfiguration { return @{ value = @() } }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCreatedConfiguration }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should create approval check using ResourceId parameter' {
            # Arrange
            $approvers = @(@{ id = '00000000-0000-0000-0000-000000000001' })

            # Act
            $result = New-AdoCheckApproval -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Approvers $approvers -ResourceType 'environment' -ResourceId '12345' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should NOT call Get-AdoEnvironment when ResourceId is provided' {
            # Arrange
            $approvers = @(@{ id = '00000000-0000-0000-0000-000000000001' })
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoEnvironment { return $mockEnvironment }

            # Act
            New-AdoCheckApproval -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Approvers $approvers -ResourceType 'environment' -ResourceId '12345' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoEnvironment -ModuleName Azure.DevOps.PSModule -Times 0
        }

        It 'Should accept ResourceId via pipeline' {
            # Arrange
            $approvers = @(@{ id = '00000000-0000-0000-0000-000000000001' })

            # Act
            $result = [PSCustomObject]@{ ResourceId = '12345' } | New-AdoCheckApproval -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Approvers $approvers -ResourceType 'environment' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should work with ResourceId and all optional parameters' {
            # Arrange
            $approvers = @(@{ id = '00000000-0000-0000-0000-000000000001' }, @{ id = '00000000-0000-0000-0000-000000000002' })

            # Act
            $result = New-AdoCheckApproval -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Approvers $approvers -ResourceType 'environment' -ResourceId '12345' -DefinitionType 'postCheckApproval' -Instructions 'Post-deployment approval' -MinRequiredApprovers 2 -ExecutionOrder 'inSequence' -RequesterCannotBeApprover $true -Timeout 2880 -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should throw error when both ResourceName and ResourceId are provided' {
            # Arrange
            $approvers = @(@{ id = '00000000-0000-0000-0000-000000000001' })

            # Act & Assert
            { New-AdoCheckApproval -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -Approvers $approvers -ResourceType 'environment' -ResourceName 'TestEnvironment' -ResourceId '12345' -Confirm:$false } | Should -Throw
        }
    }
}
