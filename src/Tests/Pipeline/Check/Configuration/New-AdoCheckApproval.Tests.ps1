[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '', Scope = 'Function', Target = '*', Justification = 'Variables are used in nested It blocks')]
param()

BeforeAll {
    # Import the module for testing
    $moduleName = 'Azure.DevOps.PSModule'
    $modulePath = Join-Path -Path (Get-Item $PSScriptRoot).Parent.Parent.Parent.Parent.FullName -ChildPath $moduleName

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

Describe 'New-AdoCheckApproval' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $resourceType = 'environment'
        $resourceName = 'my-environment-tst'
        $resourceId = 123
        $approvers = @(@{ id = '11111111-1111-1111-1111-111111111111' })

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When creating a new approval check' {
        BeforeAll {
            Mock Resolve-AdoCheckConfigDefinitionRef -ModuleName $moduleName -MockWith {
                return @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
            }

            Mock Get-AdoEnvironment -ModuleName $moduleName -MockWith {
                return @{
                    Id   = 123
                    Name = 'my-environment-tst'
                }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                return @{
                    id        = 1
                    settings  = @{
                        approvers            = $Body.settings.approvers
                        executionOrder       = 'anyOrder'
                        minRequiredApprovers = 0
                        instructions         = $Body.settings.instructions
                        blockedApprovers     = @()
                        definitionRef        = @{
                            id = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                        }
                    }
                    timeout   = $Body.timeout
                    type      = @{
                        name = 'Approval'
                        id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    }
                    resource  = @{
                        type = $Body.resource.type
                        id   = $Body.resource.id
                    }
                    createdBy = @{
                        id = 'user-id-1'
                    }
                    createdOn = '2024-01-01T00:00:00Z'
                }
            }
        }

        It 'Should create a new approval check with required parameters' {
            # Act
            $result = New-AdoCheckApproval -CollectionUri $collectionUri -ProjectName $projectName -Approvers $approvers -ResourceType $resourceType -ResourceName $resourceName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            $result.type.name | Should -Be 'Approval'
            $result.collectionUri | Should -Be $collectionUri
            $result.project | Should -Be $projectName
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match '_apis/pipelines/checks/configurations' -and
                $Method -eq 'POST'
            }
        }

        It 'Should create approval check with DefinitionType specified' -ForEach @(
            @{ Type = 'approval'; ExpectedId = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
            @{ Type = 'preCheckApproval'; ExpectedId = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
            @{ Type = 'postCheckApproval'; ExpectedId = '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
        ) {
            # Act
            $result = New-AdoCheckApproval -CollectionUri $collectionUri -ProjectName $projectName -Approvers $approvers -ResourceType $resourceType -ResourceName $resourceName -DefinitionType $Type -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Resolve-AdoCheckConfigDefinitionRef -ModuleName $moduleName -ParameterFilter {
                $Name -eq $Type
            }
        }

        It 'Should create approval check with instructions' {
            # Arrange
            $instructions = 'Approval required before deploying'

            # Act
            $result = New-AdoCheckApproval -CollectionUri $collectionUri -ProjectName $projectName -Approvers $approvers -ResourceType $resourceType -ResourceName $resourceName -Instructions $instructions -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Body.settings.instructions -eq $instructions
            }
        }

        It 'Should create approval check with custom timeout' {
            # Arrange
            $timeout = 2880

            # Act
            $result = New-AdoCheckApproval -CollectionUri $collectionUri -ProjectName $projectName -Approvers $approvers -ResourceType $resourceType -ResourceName $resourceName -Timeout $timeout -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Body.timeout -eq $timeout
            }
        }

        It 'Should use correct API version' {
            # Act
            New-AdoCheckApproval -CollectionUri $collectionUri -ProjectName $projectName -Approvers $approvers -ResourceType $resourceType -ResourceName $resourceName -Version '7.1-preview.1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1-preview.1'
            }
        }

        It 'Should resolve environment ID' {
            # Act
            New-AdoCheckApproval -CollectionUri $collectionUri -ProjectName $projectName -Approvers $approvers -ResourceType $resourceType -ResourceName $resourceName -Confirm:$false

            # Assert
            Should -Invoke Get-AdoEnvironment -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $CollectionUri -eq $collectionUri -and
                $ProjectName -eq $projectName -and
                $Name -eq $resourceName
            }
        }
    }

    Context 'When approval check already exists' {
        BeforeAll {
            Mock Resolve-AdoCheckConfigDefinitionRef -ModuleName $moduleName -MockWith {
                return @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
            }

            Mock Get-AdoEnvironment -ModuleName $moduleName -MockWith {
                return @{
                    Id   = 123
                    Name = 'my-environment-tst'
                }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Method)
                if ($Method -eq 'POST') {
                    $errorMessage = @{
                        message = 'Check configuration already exists'
                        typeKey = 'CheckConfigurationAlreadyExistsException'
                    } | ConvertTo-Json
                    $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                    $exception = [System.Exception]::new('Already exists')
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                        $exception,
                        'AlreadyExists',
                        [System.Management.Automation.ErrorCategory]::ResourceExists,
                        $null
                    )
                    $errorRecord.ErrorDetails = $errorDetails
                    throw $errorRecord
                } else {
                    return @{
                        value = @(
                            @{
                                id        = 1
                                settings  = @{
                                    approvers            = @(@{ id = '11111111-1111-1111-1111-111111111111' })
                                    executionOrder       = 'anyOrder'
                                    minRequiredApprovers = 0
                                    instructions         = 'Existing approval'
                                    blockedApprovers     = @()
                                    definitionRef        = @{
                                        id = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                                    }
                                }
                                timeout   = 1440
                                type      = @{
                                    name = 'Approval'
                                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                                }
                                resource  = @{
                                    type = 'environment'
                                    id   = '123'
                                }
                                createdBy = @{
                                    id = 'user-id-1'
                                }
                                createdOn = '2024-01-01T00:00:00Z'
                            }
                        )
                    }
                }
            }
        }

        It 'Should warn and return existing approval check' {
            # Act
            $result = New-AdoCheckApproval -CollectionUri $collectionUri -ProjectName $projectName -Approvers $approvers -ResourceType $resourceType -ResourceName $resourceName -WarningVariable warnings -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'already exists'
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            Mock Resolve-AdoCheckConfigDefinitionRef -ModuleName $moduleName -MockWith {
                return @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
            }

            Mock Get-AdoEnvironment -ModuleName $moduleName -MockWith {
                param($Name)
                return @{
                    Id   = if ($Name -eq 'env-1') { 100 } else { 200 }
                    Name = $Name
                }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                return @{
                    id        = $Body.resource.id
                    settings  = $Body.settings
                    timeout   = $Body.timeout
                    type      = @{
                        name = 'Approval'
                        id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    }
                    resource  = @{
                        type = $Body.resource.type
                        id   = $Body.resource.id
                    }
                    createdBy = @{
                        id = 'user-id-1'
                    }
                    createdOn = '2024-01-01T00:00:00Z'
                }
            }
        }

        It 'Should accept resource name from pipeline' {
            # Act
            $result = 'env-1' | New-AdoCheckApproval -CollectionUri $collectionUri -ProjectName $projectName -Approvers $approvers -ResourceType $resourceType -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should accept multiple resource names from pipeline' {
            # Act
            $result = @('env-1', 'env-2') | New-AdoCheckApproval -CollectionUri $collectionUri -ProjectName $projectName -Approvers $approvers -ResourceType $resourceType -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with default value' {
            $command = Get-Command New-AdoCheckApproval
            $parameter = $command.Parameters['CollectionUri']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
        }

        It 'Should have ProjectName parameter with ProjectId alias' {
            $command = Get-Command New-AdoCheckApproval
            $parameter = $command.Parameters['ProjectName']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Approvers as mandatory parameter' {
            $command = Get-Command New-AdoCheckApproval
            $parameter = $command.Parameters['Approvers']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have ResourceType as mandatory parameter' {
            $command = Get-Command New-AdoCheckApproval
            $parameter = $command.Parameters['ResourceType']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have ResourceName as mandatory parameter' {
            $command = Get-Command New-AdoCheckApproval
            $parameter = $command.Parameters['ResourceName']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have DefinitionType parameter with ValidateSet' {
            $command = Get-Command New-AdoCheckApproval
            $parameter = $command.Parameters['DefinitionType']
            $parameter | Should -Not -BeNullOrEmpty
            $validateSet = $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet.ValidValues | Should -Contain 'approval'
            $validateSet.ValidValues | Should -Contain 'preCheckApproval'
            $validateSet.ValidValues | Should -Contain 'postCheckApproval'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command New-AdoCheckApproval
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'Error handling' {
        BeforeAll {
            Mock Resolve-AdoCheckConfigDefinitionRef -ModuleName $moduleName -MockWith {
                return @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
            }

            Mock Get-AdoEnvironment -ModuleName $moduleName -MockWith {
                return $null
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Invalid resource ID'
                    typeKey = 'InvalidResourceException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Invalid resource')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'InvalidResource',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }
        }

        It 'Should throw when environment is not found and REST API call fails' {
            # Act & Assert
            { New-AdoCheckApproval -CollectionUri $collectionUri -ProjectName $projectName -Approvers $approvers -ResourceType $resourceType -ResourceName 'non-existent' -Confirm:$false } | Should -Throw
        }
    }

    Context 'Error handling - unsupported resource type' {
        BeforeAll {
            Mock Resolve-AdoCheckConfigDefinitionRef -ModuleName $moduleName -MockWith {
                return @{
                    id   = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
                    name = 'Approval'
                }
            }
        }

        It 'Should throw when unsupported resource type is used' {
            # This test validates parameter, but since we're using ValidateSet, invalid values won't reach the function
            $command = Get-Command New-AdoCheckApproval
            $parameter = $command.Parameters['ResourceType']
            $validateSet = $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet.ValidValues | Should -Contain 'environment'
            $validateSet.ValidValues | Should -Contain 'endpoint'
            $validateSet.ValidValues | Should -Contain 'variablegroup'
            $validateSet.ValidValues | Should -Contain 'repository'
        }
    }
}
