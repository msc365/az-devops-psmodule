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

Describe 'New-AdoCheckBranchControl' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $resourceType = 'environment'
        $resourceName = 'my-environment-tst'
        $resourceId = 123

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When creating a new branch control check' {
        BeforeAll {
            Mock Get-AdoEnvironment -ModuleName $moduleName -MockWith {
                return @{
                    Id   = 123
                    Name = 'my-environment-tst'
                }
            }

            Mock Get-AdoCheckConfiguration -ModuleName $moduleName -MockWith {
                return @()
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                return @{
                    id        = 1
                    settings  = @{
                        displayName   = $Body.settings.displayName
                        definitionRef = @{
                            id      = '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'
                            name    = 'evaluatebranchProtection'
                            version = '0.0.1'
                        }
                        inputs        = $Body.settings.inputs
                    }
                    timeout   = $Body.timeout
                    type      = @{
                        name = 'Task Check'
                        id   = 'fe1de3ee-a436-41b4-bb20-f6eb4cb879a7'
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

        It 'Should create a new branch control check with default parameters' {
            # Act
            $result = New-AdoCheckBranchControl -CollectionUri $collectionUri -ProjectName $projectName -ResourceType $resourceType -ResourceName $resourceName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            $result.type.name | Should -Be 'Task Check'
            $result.collectionUri | Should -Be $collectionUri
            $result.project | Should -Be $projectName
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match '_apis/pipelines/checks/configurations' -and
                $Method -eq 'POST'
            }
        }

        It 'Should create branch control with custom display name' {
            # Arrange
            $displayName = 'Custom Branch Control'

            # Act
            $result = New-AdoCheckBranchControl -CollectionUri $collectionUri -ProjectName $projectName -ResourceType $resourceType -ResourceName $resourceName -DisplayName $displayName -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Body.settings.displayName -eq $displayName
            }
        }

        It 'Should create branch control with custom allowed branches' {
            # Arrange
            $allowedBranches = @('refs/heads/main', 'refs/heads/release/*')

            # Act
            $result = New-AdoCheckBranchControl -CollectionUri $collectionUri -ProjectName $projectName -ResourceType $resourceType -ResourceName $resourceName -AllowedBranches $allowedBranches -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Body.settings.inputs.allowedBranches -eq ($allowedBranches -join ', ')
            }
        }

        It 'Should create branch control with EnsureProtectionOfBranch' -ForEach @(
            @{ Value = $true; Expected = 'true' }
            @{ Value = $false; Expected = 'false' }
        ) {
            # Act
            $result = New-AdoCheckBranchControl -CollectionUri $collectionUri -ProjectName $projectName -ResourceType $resourceType -ResourceName $resourceName -EnsureProtectionOfBranch $Value -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -ParameterFilter {
                $Body.settings.inputs.ensureProtectionOfBranch -eq $Expected
            }
        }

        It 'Should create branch control with AllowUnknownStatusBranches' -ForEach @(
            @{ Value = $true; Expected = 'true' }
            @{ Value = $false; Expected = 'false' }
        ) {
            # Act
            $result = New-AdoCheckBranchControl -CollectionUri $collectionUri -ProjectName $projectName -ResourceType $resourceType -ResourceName $resourceName -AllowUnknownStatusBranches $Value -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -ParameterFilter {
                $Body.settings.inputs.allowUnknownStatusBranches -eq $Expected
            }
        }

        It 'Should create branch control with custom timeout' {
            # Arrange
            $timeout = 2880

            # Act
            $result = New-AdoCheckBranchControl -CollectionUri $collectionUri -ProjectName $projectName -ResourceType $resourceType -ResourceName $resourceName -Timeout $timeout -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Body.timeout -eq $timeout
            }
        }

        It 'Should use correct API version' {
            # Act
            New-AdoCheckBranchControl -CollectionUri $collectionUri -ProjectName $projectName -ResourceType $resourceType -ResourceName $resourceName -Version '7.1-preview.1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1-preview.1'
            }
        }

        It 'Should resolve environment ID' {
            # Act
            New-AdoCheckBranchControl -CollectionUri $collectionUri -ProjectName $projectName -ResourceType $resourceType -ResourceName $resourceName -Confirm:$false

            # Assert
            Should -Invoke Get-AdoEnvironment -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $CollectionUri -eq $collectionUri -and
                $ProjectName -eq $projectName -and
                $Name -eq $resourceName
            }
        }

        It 'Should check for existing configuration' {
            # Act
            New-AdoCheckBranchControl -CollectionUri $collectionUri -ProjectName $projectName -ResourceType $resourceType -ResourceName $resourceName -Confirm:$false

            # Assert
            Should -Invoke Get-AdoCheckConfiguration -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'When branch control check already exists' {
        BeforeAll {
            Mock Get-AdoEnvironment -ModuleName $moduleName -MockWith {
                return @{
                    Id   = 123
                    Name = 'my-environment-tst'
                }
            }

            Mock Get-AdoCheckConfiguration -ModuleName $moduleName -MockWith {
                return @(
                    @{
                        id        = 1
                        settings  = @{
                            displayName   = 'Branch Control'
                            definitionRef = @{
                                id = '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'
                            }
                            inputs        = @{
                                allowedBranches            = 'refs/heads/main'
                                ensureProtectionOfBranch   = 'true'
                                allowUnknownStatusBranches = 'false'
                            }
                        }
                        timeout   = 1440
                        type      = @{
                            name = 'Task Check'
                            id   = 'fe1de3ee-a436-41b4-bb20-f6eb4cb879a7'
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

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should warn and return existing branch control check' {
            # Act
            $result = New-AdoCheckBranchControl -CollectionUri $collectionUri -ProjectName $projectName -ResourceType $resourceType -ResourceName $resourceName -WarningVariable warnings -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'already exists'
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            Mock Get-AdoEnvironment -ModuleName $moduleName -MockWith {
                param($Name)
                return @{
                    Id   = if ($Name -eq 'env-1') { 100 } else { 200 }
                    Name = $Name
                }
            }

            Mock Get-AdoCheckConfiguration -ModuleName $moduleName -MockWith {
                return @()
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                return @{
                    id        = $Body.resource.id
                    settings  = $Body.settings
                    timeout   = $Body.timeout
                    type      = @{
                        name = 'Task Check'
                        id   = 'fe1de3ee-a436-41b4-bb20-f6eb4cb879a7'
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
            $result = 'env-1' | New-AdoCheckBranchControl -CollectionUri $collectionUri -ProjectName $projectName -ResourceType $resourceType -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should accept multiple resource names from pipeline' {
            # Act
            $result = @('env-1', 'env-2') | New-AdoCheckBranchControl -CollectionUri $collectionUri -ProjectName $projectName -ResourceType $resourceType -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with default value' {
            $command = Get-Command New-AdoCheckBranchControl
            $parameter = $command.Parameters['CollectionUri']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
        }

        It 'Should have ProjectName parameter with ProjectId alias' {
            $command = Get-Command New-AdoCheckBranchControl
            $parameter = $command.Parameters['ProjectName']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have ResourceType as mandatory parameter' {
            $command = Get-Command New-AdoCheckBranchControl
            $parameter = $command.Parameters['ResourceType']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have ResourceName as mandatory parameter' {
            $command = Get-Command New-AdoCheckBranchControl
            $parameter = $command.Parameters['ResourceName']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have AllowedBranches parameter with default value' {
            $command = Get-Command New-AdoCheckBranchControl
            $parameter = $command.Parameters['AllowedBranches']
            $parameter | Should -Not -BeNullOrEmpty
        }

        It 'Should have EnsureProtectionOfBranch parameter with default value' {
            $command = Get-Command New-AdoCheckBranchControl
            $parameter = $command.Parameters['EnsureProtectionOfBranch']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'Boolean'
        }

        It 'Should have AllowUnknownStatusBranches parameter with default value' {
            $command = Get-Command New-AdoCheckBranchControl
            $parameter = $command.Parameters['AllowUnknownStatusBranches']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'Boolean'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command New-AdoCheckBranchControl
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'Error handling' {
        BeforeAll {
            Mock Get-AdoEnvironment -ModuleName $moduleName -MockWith {
                return $null
            }

            Mock Get-AdoCheckConfiguration -ModuleName $moduleName -MockWith {
                return @()
            }
        }

        It 'Should handle when environment is not found' {
            # Act & Assert
            { New-AdoCheckBranchControl -CollectionUri $collectionUri -ProjectName $projectName -ResourceType $resourceType -ResourceName 'non-existent' -Confirm:$false -ErrorAction SilentlyContinue } | Should -Throw
        }
    }

    Context 'Error handling - unsupported resource type' {
        It 'Should have ValidateSet for ResourceType' {
            $command = Get-Command New-AdoCheckBranchControl
            $parameter = $command.Parameters['ResourceType']
            $validateSet = $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet.ValidValues | Should -Contain 'environment'
            $validateSet.ValidValues | Should -Contain 'endpoint'
            $validateSet.ValidValues | Should -Contain 'variablegroup'
            $validateSet.ValidValues | Should -Contain 'repository'
        }
    }
}
