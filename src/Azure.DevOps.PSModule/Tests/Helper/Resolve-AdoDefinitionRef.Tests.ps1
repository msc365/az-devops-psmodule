BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Resolve-AdoDefinitionRef' {
    BeforeAll {
        # Known definition IDs and names from Azure DevOps
        $approvalId = '26014962-64a0-49f4-885b-4b874119a5cc'
        $preCheckApprovalId = '0f52a19b-c67e-468f-b8eb-0ae83b532c99'
        $postCheckApprovalId = '06441319-13fb-4756-b198-c2da116894a4'
        $branchControlId = '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'
        $businessHoursId = '445fde2f-6c39-441c-807f-8a59ff2e075f'
    }

    Context 'Core Functionality - By Name' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should resolve approval definition by name' {
            # Act
            $result = Resolve-AdoDefinitionRef -Name 'approval'

            # Assert
            $result.name | Should -Be 'approval'
            $result.id | Should -Be $approvalId
            $result.displayName | Should -Be 'Approval'
        }

        It 'Should resolve preCheckApproval definition by name' {
            # Act
            $result = Resolve-AdoDefinitionRef -Name 'preCheckApproval'

            # Assert
            $result.name | Should -Be 'preCheckApproval'
            $result.id | Should -Be $preCheckApprovalId
            $result.displayName | Should -Be 'Pre-check approval'
        }

        It 'Should resolve postCheckApproval definition by name' {
            # Act
            $result = Resolve-AdoDefinitionRef -Name 'postCheckApproval'

            # Assert
            $result.name | Should -Be 'postCheckApproval'
            $result.id | Should -Be $postCheckApprovalId
            $result.displayName | Should -Be 'Post-check approval'
        }

        It 'Should resolve branchControl definition by name' {
            # Act
            $result = Resolve-AdoDefinitionRef -Name 'branchControl'

            # Assert
            $result.name | Should -Be 'branchControl'
            $result.id | Should -Be $branchControlId
            $result.displayName | Should -Be 'Branch control'
        }

        It 'Should resolve businessHours definition by name' {
            # Act
            $result = Resolve-AdoDefinitionRef -Name 'businessHours'

            # Assert
            $result.name | Should -Be 'businessHours'
            $result.id | Should -Be $businessHoursId
            $result.displayName | Should -Be 'Business hours'
        }

        It 'Should return PSCustomObject with expected properties' {
            # Act
            $result = Resolve-AdoDefinitionRef -Name 'approval'

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'name'
            $result.PSObject.Properties.Name | Should -Contain 'id'
            $result.PSObject.Properties.Name | Should -Contain 'displayName'
        }
    }

    Context 'Core Functionality - By ID' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should resolve approval definition by ID' {
            # Act
            $result = Resolve-AdoDefinitionRef -Id $approvalId

            # Assert
            $result.name | Should -Be 'approval'
            $result.id | Should -Be $approvalId
            $result.displayName | Should -Be 'Approval'
        }

        It 'Should resolve preCheckApproval definition by ID' {
            # Act
            $result = Resolve-AdoDefinitionRef -Id $preCheckApprovalId

            # Assert
            $result.name | Should -Be 'preCheckApproval'
            $result.id | Should -Be $preCheckApprovalId
        }

        It 'Should resolve postCheckApproval definition by ID' {
            # Act
            $result = Resolve-AdoDefinitionRef -Id $postCheckApprovalId

            # Assert
            $result.name | Should -Be 'postCheckApproval'
            $result.id | Should -Be $postCheckApprovalId
        }

        It 'Should resolve branchControl definition by ID' {
            # Act
            $result = Resolve-AdoDefinitionRef -Id $branchControlId

            # Assert
            $result.name | Should -Be 'branchControl'
            $result.id | Should -Be $branchControlId
        }

        It 'Should resolve businessHours definition by ID' {
            # Act
            $result = Resolve-AdoDefinitionRef -Id $businessHoursId

            # Assert
            $result.name | Should -Be 'businessHours'
            $result.id | Should -Be $businessHoursId
        }
    }

    Context 'Core Functionality - ListAll' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should return all definition references' {
            # Act
            $result = Resolve-AdoDefinitionRef -ListAll

            # Assert
            $result | Should -HaveCount 5
        }

        It 'Should include all expected definition names' {
            # Act
            $result = Resolve-AdoDefinitionRef -ListAll

            # Assert
            $result.name | Should -Contain 'approval'
            $result.name | Should -Contain 'preCheckApproval'
            $result.name | Should -Contain 'postCheckApproval'
            $result.name | Should -Contain 'branchControl'
            $result.name | Should -Contain 'businessHours'
        }

        It 'Should return unique definitions only' {
            # Act
            $result = Resolve-AdoDefinitionRef -ListAll

            # Assert - no duplicates
            $uniqueIds = $result.id | Select-Object -Unique
            $uniqueIds.Count | Should -Be $result.Count
        }

        It 'Should return definitions sorted by name' {
            # Act
            $result = Resolve-AdoDefinitionRef -ListAll

            # Assert
            $sortedNames = $result.name | Sort-Object
            $result.name | Should -Be $sortedNames
        }
    }

    Context 'Parameter Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Start-Sleep { }
        }

        It 'Should use ByName parameter set as default' {
            # Act
            $result = Resolve-AdoDefinitionRef -Name 'approval'

            # Assert
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should handle Name parameter case-insensitively' {
            # Act - using different casing
            $result1 = Resolve-AdoDefinitionRef -Name 'APPROVAL'
            $result2 = Resolve-AdoDefinitionRef -Name 'Approval'
            $result3 = Resolve-AdoDefinitionRef -Name 'approval'

            # Assert - all should resolve to the same definition
            $result1.id | Should -Be $result2.id
            $result2.id | Should -Be $result3.id
        }
    }
}
