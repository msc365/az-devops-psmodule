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

    # Mock Confirm-CollectionUri and Confirm-Default
    Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { return $true }
    Mock Confirm-Default -ModuleName $moduleName -MockWith { }
}

Describe 'Get-AdoPolicyType' {

    Context 'When retrieving all policy types' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    count = 3
                    value = @(
                        @{
                            id          = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
                            displayName = 'Minimum number of reviewers'
                            description = 'This policy will ensure that a minimum number of reviewers have approved a pull request before it can be completed.'
                            url         = 'https://dev.azure.com/testorg/testproject/_apis/policy/types/fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
                        },
                        @{
                            id          = '0609b952-1397-4640-95ec-e00a01b2c241'
                            displayName = 'Build'
                            description = 'This policy will ensure that a successful build has been performed before a pull request can be completed.'
                            url         = 'https://dev.azure.com/testorg/testproject/_apis/policy/types/0609b952-1397-4640-95ec-e00a01b2c241'
                        },
                        @{
                            id          = 'fd2167ab-b0be-447a-8ec8-39368250530e'
                            displayName = 'Required reviewers'
                            description = 'This policy will ensure that required reviewers are added to pull requests.'
                            url         = 'https://dev.azure.com/testorg/testproject/_apis/policy/types/fd2167ab-b0be-447a-8ec8-39368250530e'
                        }
                    )
                }
            }
        }

        It 'Should retrieve all policy types when no Id is specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'

            # Act
            $result = Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].id | Should -Be 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
            $result[0].displayName | Should -Be 'Minimum number of reviewers'
            $result[0].projectName | Should -Be $projectName
            $result[0].collectionUri | Should -Be $collectionUri
            $result[1].displayName | Should -Be 'Build'
            $result[2].displayName | Should -Be 'Required reviewers'

            # Verify Invoke-AdoRestMethod was called correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/$projectName/_apis/policy/types" -and
                $Method -eq 'GET' -and
                $Version -eq '7.1'
            }
        }

        It 'Should use default version when Version parameter is not specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'

            # Act
            Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should use environment variables when CollectionUri and ProjectName are not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/envorg'
            $env:DefaultAdoProject = 'envproject'

            # Act
            Get-AdoPolicyType

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/envorg/envproject/_apis/policy/types'
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProject = $null
        }

        It 'Should use custom API version when specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'

            # Act
            Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName -Version '7.2-preview.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }
    }

    Context 'When retrieving a specific policy type by Id' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id          = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
                    displayName = 'Minimum number of reviewers'
                    description = 'This policy will ensure that a minimum number of reviewers have approved a pull request before it can be completed.'
                    url         = 'https://dev.azure.com/testorg/testproject/_apis/policy/types/fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
                }
            }
        }

        It 'Should retrieve policy type by Id' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $policyTypeId = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'

            # Act
            $result = Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName -Id $policyTypeId

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be $policyTypeId
            $result.displayName | Should -Be 'Minimum number of reviewers'
            $result.projectName | Should -Be $projectName
            $result.collectionUri | Should -Be $collectionUri

            # Verify Invoke-AdoRestMethod was called correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/$projectName/_apis/policy/types/$policyTypeId" -and
                $Method -eq 'GET' -and
                $Version -eq '7.1'
            }
        }

        It 'Should retrieve Build policy type by Id' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $policyTypeId = '0609b952-1397-4640-95ec-e00a01b2c241'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id          = '0609b952-1397-4640-95ec-e00a01b2c241'
                    displayName = 'Build'
                    description = 'This policy will ensure that a successful build has been performed before a pull request can be completed.'
                    url         = 'https://dev.azure.com/testorg/testproject/_apis/policy/types/0609b952-1397-4640-95ec-e00a01b2c241'
                }
            }

            # Act
            $result = Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName -Id $policyTypeId

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be $policyTypeId
            $result.displayName | Should -Be 'Build'
        }

        It 'Should accept Id through pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $policyTypeId = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'

            # Act
            $result = $policyTypeId | Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be $policyTypeId

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'Error handling' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Policy type with ID ''fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'' does not exist.'
                    typeKey = 'NotFoundException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Policy type not found')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'NotFoundException',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }
        }

        It 'Should handle not found error gracefully' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $validIdNotInProject = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'

            # Act & Assert
            { Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName -Id $validIdNotInProject -WarningAction SilentlyContinue } | Should -Not -Throw

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should write warning when policy type is not found' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $validIdNotInProject = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'

            # Act & Assert
            $warnings = @()
            Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName -Id $validIdNotInProject -WarningVariable warnings -WarningAction SilentlyContinue

            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'Policy type with ID fa4e907d-c16b-4a4c-9dfa-4906e5d171dd does not exist'
        }

        It 'Should throw error for unexpected exceptions' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Unexpected error'
            }

            # Act & Assert
            { Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName } | Should -Throw 'Unexpected error'
        }
    }

    Context 'Parameter validation' {
        It 'Should have ProjectName parameter with default from environment' {
            # Arrange
            $command = Get-Command Get-AdoPolicyType

            # Act
            $projectNameParam = $command.Parameters['ProjectName']
            $mandatoryAttr = $projectNameParam.Attributes | Where-Object {
                $_ -is [Parameter] -and $_.Mandatory
            }

            # Assert
            # ProjectName has environment variable default, so it's not strictly mandatory
            $mandatoryAttr | Should -BeNullOrEmpty
            $projectNameParam | Should -Not -BeNullOrEmpty
        }

        It 'Should have CollectionUri as optional parameter with default from environment' {
            # Arrange
            $command = Get-Command Get-AdoPolicyType

            # Act
            $collectionUriParam = $command.Parameters['CollectionUri']
            $mandatoryAttr = $collectionUriParam.Attributes | Where-Object {
                $_ -is [Parameter] -and $_.Mandatory
            }

            # Assert
            $mandatoryAttr | Should -BeNullOrEmpty
        }

        It 'Should have Id as optional parameter' {
            # Arrange
            $command = Get-Command Get-AdoPolicyType

            # Act
            $idParam = $command.Parameters['Id']
            $mandatoryAttr = $idParam.Attributes | Where-Object {
                $_ -is [Parameter] -and $_.Mandatory
            }

            # Assert
            $mandatoryAttr | Should -BeNullOrEmpty
        }

        It 'Should have ValidateSet attribute on Id parameter' {
            # Arrange
            $command = Get-Command Get-AdoPolicyType

            # Act
            $idParam = $command.Parameters['Id']
            $validateSetAttr = $idParam.Attributes | Where-Object { $_ -is [ValidateSet] }

            # Assert
            $validateSetAttr | Should -Not -BeNullOrEmpty
            $validateSetAttr.ValidValues | Should -Contain 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
            $validateSetAttr.ValidValues | Should -Contain '0609b952-1397-4640-95ec-e00a01b2c241'
        }

        It 'Should have ValidateSet attribute on Version parameter' {
            # Arrange
            $command = Get-Command Get-AdoPolicyType

            # Act
            $versionParam = $command.Parameters['Version']
            $validateSetAttr = $versionParam.Attributes | Where-Object { $_ -is [ValidateSet] }

            # Assert
            $validateSetAttr | Should -Not -BeNullOrEmpty
            $validateSetAttr.ValidValues | Should -Contain '7.1'
            $validateSetAttr.ValidValues | Should -Contain '7.2-preview.1'
        }

        It 'Should have ProjectId as alias for ProjectName parameter' {
            # Arrange
            $command = Get-Command Get-AdoPolicyType

            # Act
            $projectNameParam = $command.Parameters['ProjectName']

            # Assert
            $projectNameParam.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have TypeId and PolicyTypeId as aliases for Id parameter' {
            # Arrange
            $command = Get-Command Get-AdoPolicyType

            # Act
            $idParam = $command.Parameters['Id']

            # Assert
            $idParam.Aliases | Should -Contain 'TypeId'
            $idParam.Aliases | Should -Contain 'PolicyTypeId'
        }

        It 'Should have ApiVersion as alias for Version parameter' {
            # Arrange
            $command = Get-Command Get-AdoPolicyType

            # Act
            $versionParam = $command.Parameters['Version']

            # Assert
            $versionParam.Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should support WhatIf and Confirm parameters' {
            # Arrange
            $command = Get-Command Get-AdoPolicyType

            # Act & Assert
            $command.Parameters.ContainsKey('WhatIf') -and $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    count = 1
                    value = @(
                        @{
                            id          = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
                            displayName = 'Minimum number of reviewers'
                            description = 'This policy will ensure that a minimum number of reviewers have approved a pull request before it can be completed.'
                            url         = 'https://dev.azure.com/testorg/testproject/_apis/policy/types/fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
                        }
                    )
                }
            }
        }

        It 'Should return PSCustomObject with correct properties' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'

            # Act
            $result = Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.PSObject.Properties.Name | Should -Contain 'id'
            $result.PSObject.Properties.Name | Should -Contain 'displayName'
            $result.PSObject.Properties.Name | Should -Contain 'description'
            $result.PSObject.Properties.Name | Should -Contain 'projectName'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should include collectionUri in output' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'

            # Act
            $result = Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result.collectionUri | Should -Be $collectionUri
        }

        It 'Should include projectName in output' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'

            # Act
            $result = Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $result.projectName | Should -Be $projectName
        }
    }

    Context 'WhatIf and Confirm scenarios' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    count = 1
                    value = @(
                        @{
                            id          = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
                            displayName = 'Minimum number of reviewers'
                            description = 'This policy will ensure that a minimum number of reviewers have approved a pull request before it can be completed.'
                        }
                    )
                }
            }
        }

        It 'Should not call Invoke-AdoRestMethod when WhatIf is specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'

            # Act
            Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should support Confirm parameter' {
            # Arrange
            $command = Get-Command Get-AdoPolicyType

            # Act & Assert
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'Integration scenarios' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri)

                if ($Uri -like '*fa4e907d-c16b-4a4c-9dfa-4906e5d171dd') {
                    return @{
                        id          = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
                        displayName = 'Minimum number of reviewers'
                        description = 'This policy will ensure that a minimum number of reviewers have approved a pull request before it can be completed.'
                    }
                } elseif ($Uri -like '*0609b952-1397-4640-95ec-e00a01b2c241') {
                    return @{
                        id          = '0609b952-1397-4640-95ec-e00a01b2c241'
                        displayName = 'Build'
                        description = 'This policy will ensure that a successful build has been performed before a pull request can be completed.'
                    }
                } else {
                    return @{
                        count = 2
                        value = @(
                            @{
                                id          = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
                                displayName = 'Minimum number of reviewers'
                                description = 'This policy will ensure that a minimum number of reviewers have approved a pull request before it can be completed.'
                            },
                            @{
                                id          = '0609b952-1397-4640-95ec-e00a01b2c241'
                                displayName = 'Build'
                                description = 'This policy will ensure that a successful build has been performed before a pull request can be completed.'
                            }
                        )
                    }
                }
            }
        }

        It 'Should handle multiple sequential calls' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'

            # Act
            $allPolicies = Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName
            $specificPolicy = Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName -Id 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'

            # Assert
            $allPolicies.Count | Should -Be 2
            $specificPolicy.id | Should -Be 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }

        It 'Should handle pipeline input for multiple policy type IDs' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'testproject'
            $policyTypeIds = @('fa4e907d-c16b-4a4c-9dfa-4906e5d171dd', '0609b952-1397-4640-95ec-e00a01b2c241')

            # Act
            $results = $policyTypeIds | Get-AdoPolicyType -CollectionUri $collectionUri -ProjectName $projectName

            # Assert
            $results.Count | Should -Be 2
            $results[0].id | Should -Be 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
            $results[1].id | Should -Be '0609b952-1397-4640-95ec-e00a01b2c241'

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }
}
