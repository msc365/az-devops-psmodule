[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '', Scope = 'Function', Target = '*', Justification = 'Variables are used in nested It blocks')]
param()

BeforeAll {
    # Module import logic
    $moduleName = 'Azure.DevOps.PSModule'
    # For tests in src/Tests/<Category>/ use Parent.Parent
    $modulePath = Join-Path -Path (Get-Item $PSScriptRoot).Parent.Parent.FullName -ChildPath $moduleName

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

Describe 'Resolve-AdoCheckConfigDefinitionRef' {
    Context 'Resolve by Name' {
        It 'Should resolve approval check definition by name' {
            # Arrange & Act
            $result = Resolve-AdoCheckConfigDefinitionRef -Name 'approval'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'approval'
            $result.id | Should -Be '26014962-64a0-49f4-885b-4b874119a5cc'
            $result.displayName | Should -Be 'Approval'
        }

        It 'Should resolve preCheckApproval check definition by name' {
            # Arrange & Act
            $result = Resolve-AdoCheckConfigDefinitionRef -Name 'preCheckApproval'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'preCheckApproval'
            $result.id | Should -Be '0f52a19b-c67e-468f-b8eb-0ae83b532c99'
            $result.displayName | Should -Be 'Pre-check approval'
        }

        It 'Should resolve postCheckApproval check definition by name' {
            # Arrange & Act
            $result = Resolve-AdoCheckConfigDefinitionRef -Name 'postCheckApproval'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'postCheckApproval'
            $result.id | Should -Be '06441319-13fb-4756-b198-c2da116894a4'
            $result.displayName | Should -Be 'Post-check approval'
        }

        It 'Should resolve branchControl check definition by name' {
            # Arrange & Act
            $result = Resolve-AdoCheckConfigDefinitionRef -Name 'branchControl'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'branchControl'
            $result.id | Should -Be '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'
            $result.displayName | Should -Be 'Branch control'
        }

        It 'Should resolve businessHours check definition by name' {
            # Arrange & Act
            $result = Resolve-AdoCheckConfigDefinitionRef -Name 'businessHours'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'businessHours'
            $result.id | Should -Be '445fde2f-6c39-441c-807f-8a59ff2e075f'
            $result.displayName | Should -Be 'Business hours'
        }

        It 'Should be case-insensitive when resolving by name' {
            # Arrange & Act
            $result = Resolve-AdoCheckConfigDefinitionRef -Name 'APPROVAL'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'approval'
            $result.id | Should -Be '26014962-64a0-49f4-885b-4b874119a5cc'
        }
    }

    Context 'Resolve by ID' {
        It 'Should resolve approval check definition by ID' {
            # Arrange & Act
            $result = Resolve-AdoCheckConfigDefinitionRef -Id '26014962-64a0-49f4-885b-4b874119a5cc'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'approval'
            $result.id | Should -Be '26014962-64a0-49f4-885b-4b874119a5cc'
            $result.displayName | Should -Be 'Approval'
        }

        It 'Should resolve preCheckApproval check definition by ID' {
            # Arrange & Act
            $result = Resolve-AdoCheckConfigDefinitionRef -Id '0f52a19b-c67e-468f-b8eb-0ae83b532c99'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'preCheckApproval'
            $result.id | Should -Be '0f52a19b-c67e-468f-b8eb-0ae83b532c99'
            $result.displayName | Should -Be 'Pre-check approval'
        }

        It 'Should resolve postCheckApproval check definition by ID' {
            # Arrange & Act
            $result = Resolve-AdoCheckConfigDefinitionRef -Id '06441319-13fb-4756-b198-c2da116894a4'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'postCheckApproval'
            $result.id | Should -Be '06441319-13fb-4756-b198-c2da116894a4'
            $result.displayName | Should -Be 'Post-check approval'
        }

        It 'Should resolve branchControl check definition by ID' {
            # Arrange & Act
            $result = Resolve-AdoCheckConfigDefinitionRef -Id '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'branchControl'
            $result.id | Should -Be '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'
            $result.displayName | Should -Be 'Branch control'
        }

        It 'Should resolve businessHours check definition by ID' {
            # Arrange & Act
            $result = Resolve-AdoCheckConfigDefinitionRef -Id '445fde2f-6c39-441c-807f-8a59ff2e075f'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'businessHours'
            $result.id | Should -Be '445fde2f-6c39-441c-807f-8a59ff2e075f'
            $result.displayName | Should -Be 'Business hours'
        }
    }

    Context 'Parameter validation' {
        It 'Should have Id as a mandatory parameter in ById parameter set' {
            # Arrange
            $command = Get-Command Resolve-AdoCheckConfigDefinitionRef

            # Act
            $idParam = $command.Parameters['Id']
            $mandatoryAttr = $idParam.Attributes | Where-Object {
                $_ -is [Parameter] -and $_.Mandatory -and $_.ParameterSetName -eq 'ById'
            }

            # Assert
            $mandatoryAttr | Should -Not -BeNullOrEmpty
        }

        It 'Should have Name as a mandatory parameter in ByName parameter set' {
            # Arrange
            $command = Get-Command Resolve-AdoCheckConfigDefinitionRef

            # Act
            $nameParam = $command.Parameters['Name']
            $mandatoryAttr = $nameParam.Attributes | Where-Object {
                $_ -is [Parameter] -and $_.Mandatory -and $_.ParameterSetName -eq 'ByName'
            }

            # Assert
            $mandatoryAttr | Should -Not -BeNullOrEmpty
        }

        It 'Should have ValidateSet for Id parameter' {
            # Arrange
            $command = Get-Command Resolve-AdoCheckConfigDefinitionRef

            # Act
            $idParam = $command.Parameters['Id']
            $validateSet = $idParam.Attributes | Where-Object { $_ -is [ValidateSet] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain '26014962-64a0-49f4-885b-4b874119a5cc'
            $validateSet.ValidValues | Should -Contain '0f52a19b-c67e-468f-b8eb-0ae83b532c99'
            $validateSet.ValidValues | Should -Contain '06441319-13fb-4756-b198-c2da116894a4'
            $validateSet.ValidValues | Should -Contain '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'
            $validateSet.ValidValues | Should -Contain '445fde2f-6c39-441c-807f-8a59ff2e075f'
        }

        It 'Should have ValidateSet for Name parameter' {
            # Arrange
            $command = Get-Command Resolve-AdoCheckConfigDefinitionRef

            # Act
            $nameParam = $command.Parameters['Name']
            $validateSet = $nameParam.Attributes | Where-Object { $_ -is [ValidateSet] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'approval'
            $validateSet.ValidValues | Should -Contain 'preCheckApproval'
            $validateSet.ValidValues | Should -Contain 'postCheckApproval'
            $validateSet.ValidValues | Should -Contain 'branchControl'
            $validateSet.ValidValues | Should -Contain 'businessHours'
        }

        It 'Should have two parameter sets' {
            # Arrange
            $command = Get-Command Resolve-AdoCheckConfigDefinitionRef

            # Act & Assert
            $command.ParameterSets.Count | Should -Be 3
            $command.ParameterSets.Name | Should -Contain 'ById'
            $command.ParameterSets.Name | Should -Contain 'ByName'
            $command.ParameterSets.Name | Should -Contain 'ListAll'
        }

        It 'Should have Id parameter only in ById parameter set' {
            # Arrange
            $command = Get-Command Resolve-AdoCheckConfigDefinitionRef
            $idParam = $command.Parameters['Id']

            # Act
            $parameterSets = $idParam.Attributes | Where-Object { $_ -is [Parameter] } | Select-Object -ExpandProperty ParameterSetName

            # Assert
            $parameterSets | Should -Contain 'ById'
            $parameterSets | Should -Not -Contain 'ByName'
        }

        It 'Should have Name parameter only in ByName parameter set' {
            # Arrange
            $command = Get-Command Resolve-AdoCheckConfigDefinitionRef
            $nameParam = $command.Parameters['Name']

            # Act
            $parameterSets = $nameParam.Attributes | Where-Object { $_ -is [Parameter] } | Select-Object -ExpandProperty ParameterSetName

            # Assert
            $parameterSets | Should -Contain 'ByName'
            $parameterSets | Should -Not -Contain 'ById'
        }

        It 'Should have ListAll as a mandatory parameter in ListAll parameter set' {
            # Arrange
            $command = Get-Command Resolve-AdoCheckConfigDefinitionRef

            # Act
            $listAllParam = $command.Parameters['ListAll']
            $mandatoryAttr = $listAllParam.Attributes | Where-Object {
                $_ -is [Parameter] -and $_.Mandatory -and $_.ParameterSetName -eq 'ListAll'
            }

            # Assert
            $mandatoryAttr | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Output validation' {
        It 'Should return PSCustomObject type' {
            # Arrange & Act
            $result = Resolve-AdoCheckConfigDefinitionRef -Name 'approval'

            # Assert
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Should return object with name property' {
            # Arrange & Act
            $result = Resolve-AdoCheckConfigDefinitionRef -Name 'approval'

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'name'
        }

        It 'Should return object with id property' {
            # Arrange & Act
            $result = Resolve-AdoCheckConfigDefinitionRef -Name 'approval'

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'id'
        }

        It 'Should return object with displayName property' {
            # Arrange & Act
            $result = Resolve-AdoCheckConfigDefinitionRef -Name 'approval'

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'displayName'
        }

        It 'Should have OutputType attribute set to PSCustomObject' {
            # Arrange
            $command = Get-Command Resolve-AdoCheckConfigDefinitionRef

            # Act
            $outputType = $command.OutputType

            # Assert
            $outputType | Should -Not -BeNullOrEmpty
            $outputType.Name | Should -Contain 'System.Management.Automation.PSObject'
        }
    }

    Context 'Integration scenarios' {
        It 'Should resolve the same definition whether using name or id' {
            # Arrange & Act
            $resultByName = Resolve-AdoCheckConfigDefinitionRef -Name 'approval'
            $resultById = Resolve-AdoCheckConfigDefinitionRef -Id '26014962-64a0-49f4-885b-4b874119a5cc'

            # Assert
            $resultByName.name | Should -Be $resultById.name
            $resultByName.id | Should -Be $resultById.id
            $resultByName.displayName | Should -Be $resultById.displayName
        }

        It 'Should consistently return same result for multiple calls' {
            # Arrange & Act
            $result1 = Resolve-AdoCheckConfigDefinitionRef -Name 'branchControl'
            $result2 = Resolve-AdoCheckConfigDefinitionRef -Name 'branchControl'

            # Assert
            $result1.name | Should -Be $result2.name
            $result1.id | Should -Be $result2.id
            $result1.displayName | Should -Be $result2.displayName
        }

        It 'Should work in pipeline scenario' {
            # Arrange
            $names = @('approval', 'branchControl', 'businessHours')

            # Act
            $results = $names | ForEach-Object { Resolve-AdoCheckConfigDefinitionRef -Name $_ }

            # Assert
            $results.Count | Should -Be 3
            $results[0].name | Should -Be 'approval'
            $results[1].name | Should -Be 'branchControl'
            $results[2].name | Should -Be 'businessHours'
        }

        It 'Should return all expected properties for all check types' {
            # Arrange
            $allNames = @('approval', 'preCheckApproval', 'postCheckApproval', 'branchControl', 'businessHours')

            # Act
            $results = $allNames | ForEach-Object { Resolve-AdoCheckConfigDefinitionRef -Name $_ }

            # Assert
            foreach ($result in $results) {
                $result.PSObject.Properties.Name | Should -Contain 'name'
                $result.PSObject.Properties.Name | Should -Contain 'id'
                $result.PSObject.Properties.Name | Should -Contain 'displayName'
                $result.name | Should -Not -BeNullOrEmpty
                $result.id | Should -Not -BeNullOrEmpty
                $result.displayName | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'ListAll functionality' {
        It 'Should return all definition references when using ListAll' {
            # Arrange & Act
            $results = Resolve-AdoCheckConfigDefinitionRef -ListAll

            # Assert
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 5
        }

        It 'Should return unique definitions sorted by name' {
            # Arrange & Act
            $results = Resolve-AdoCheckConfigDefinitionRef -ListAll

            # Assert
            $results[0].name | Should -Be 'approval'
            $results[1].name | Should -Be 'branchControl'
            $results[2].name | Should -Be 'businessHours'
            $results[3].name | Should -Be 'postCheckApproval'
            $results[4].name | Should -Be 'preCheckApproval'
        }

        It 'Should return objects with all expected properties' {
            # Arrange & Act
            $results = Resolve-AdoCheckConfigDefinitionRef -ListAll

            # Assert
            foreach ($result in $results) {
                $result.PSObject.Properties.Name | Should -Contain 'name'
                $result.PSObject.Properties.Name | Should -Contain 'id'
                $result.PSObject.Properties.Name | Should -Contain 'displayName'
                $result.name | Should -Not -BeNullOrEmpty
                $result.id | Should -Not -BeNullOrEmpty
                $result.displayName | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should return same definitions as individually resolved' {
            # Arrange & Act
            $allResults = Resolve-AdoCheckConfigDefinitionRef -ListAll
            $approvalIndividual = Resolve-AdoCheckConfigDefinitionRef -Name 'approval'
            $approvalFromList = $allResults | Where-Object { $_.name -eq 'approval' }

            # Assert
            $approvalFromList.name | Should -Be $approvalIndividual.name
            $approvalFromList.id | Should -Be $approvalIndividual.id
            $approvalFromList.displayName | Should -Be $approvalIndividual.displayName
        }
    }
}
