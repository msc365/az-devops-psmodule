BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'New-AdoCheckBranchControl' {
    BeforeAll {
        $mockEnvironment = @{ id = 1; name = 'TestEnvironment' }
        $mockCreatedConfiguration = @{
            id        = 1
            timeout   = 1440
            type      = @{ id = 'fe1de3ee-a436-41b4-bb20-f6eb4cb879a7'; name = 'Task Check' }
            settings  = @{
                displayName  = 'Branch Control'
                definitionRef = @{ id = '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'; name = 'evaluatebranchProtection' }
            }
            resource  = @{ type = 'environment'; id = '1' }
            createdBy = @{ id = 'creator1' }
            createdOn = '2024-01-01T00:00:00Z'
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoEnvironment { return $mockEnvironment }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoCheckConfiguration { return @{ value = @() } }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCreatedConfiguration }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should create branch control check with default parameters' {
            # Act
            $result = New-AdoCheckBranchControl -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'TestEnvironment' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should create branch control check with custom parameters' {
            # Act
            $result = New-AdoCheckBranchControl -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -DisplayName 'Custom Branch Control' -ResourceType 'environment' -ResourceName 'TestEnvironment' -AllowedBranches @('refs/heads/main', 'refs/heads/release/*') -EnsureProtectionOfBranch $true -AllowUnknownStatusBranches $false -Timeout 2880 -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1
        }

        It 'Should accept resource names via pipeline' {
            # Act
            $result = 'TestEnvironment' | New-AdoCheckBranchControl -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should call Get-AdoEnvironment to resolve resource ID' {
            # Act
            New-AdoCheckBranchControl -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'TestEnvironment' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoEnvironment -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoEnvironment { return $mockEnvironment }
            Mock -ModuleName Azure.DevOps.PSModule New-AdoCheckConfiguration { return $mockCreatedConfiguration }
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoCheckConfiguration { return @{ value = @() } }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockCreatedConfiguration }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            # Act & Assert
            { New-AdoCheckBranchControl -CollectionUri 'invalid-uri' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'TestEnv' -Confirm:$false } | Should -Throw
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoCheckConfiguration { return @{ value = @() } }
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'Response status code does not indicate success: 401 (Unauthorized).' }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should throw error for unsupported resource types' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoEnvironment { return $mockEnvironment }

            # Act & Assert
            { New-AdoCheckBranchControl -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'endpoint' -ResourceName 'TestEndpoint' -Confirm:$false } | Should -Throw '*not supported yet*'
        }

        It 'Should propagate errors from Invoke-AdoRestMethod' {
            # Arrange
            Mock -ModuleName Azure.DevOps.PSModule Get-AdoEnvironment { return $mockEnvironment }

            # Act & Assert
            { New-AdoCheckBranchControl -CollectionUri 'https://dev.azure.com/my-org' -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'TestEnvironment' -Confirm:$false } | Should -Throw '*Unauthorized*'
        }
    }
}
