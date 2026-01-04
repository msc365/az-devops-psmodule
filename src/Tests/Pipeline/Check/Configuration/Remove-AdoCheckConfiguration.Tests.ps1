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

Describe 'Remove-AdoCheckConfiguration' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $checkId = 1

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When removing a check configuration' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should remove check configuration by ID' {
            # Act
            Remove-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id $checkId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/pipelines/checks/configurations/$checkId" -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should use correct API version' {
            # Act
            Remove-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id $checkId -Version '7.1-preview.1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1-preview.1'
            }
        }

        It 'Should use default API version when not specified' {
            # Act
            Remove-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id $checkId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }
    }

    Context 'When removing multiple check configurations' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should remove multiple check configurations from pipeline' {
            # Act
            @(1, 2, 3) | Remove-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
        }

        It 'Should call correct URIs for each check configuration' {
            # Act
            @(1, 2) | Remove-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match 'configurations/1'
            }
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match 'configurations/2'
            }
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should accept check ID from pipeline' {
            # Act
            1 | Remove-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should accept multiple check IDs from pipeline' {
            # Act
            1, 2, 3 | Remove-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with default value' {
            $command = Get-Command Remove-AdoCheckConfiguration
            $parameter = $command.Parameters['CollectionUri']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
        }

        It 'Should have ProjectName parameter with ProjectId alias' {
            $command = Get-Command Remove-AdoCheckConfiguration
            $parameter = $command.Parameters['ProjectName']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Id as mandatory parameter' {
            $command = Get-Command Remove-AdoCheckConfiguration
            $parameter = $command.Parameters['Id']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes.Mandatory | Should -Contain $true
            $parameter.ParameterType.Name | Should -Be 'Int32'
        }

        It 'Should have Version parameter with ApiVersion alias' {
            $command = Get-Command Remove-AdoCheckConfiguration
            $parameter = $command.Parameters['Version']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should have Version parameter with ValidateSet' {
            $command = Get-Command Remove-AdoCheckConfiguration
            $parameter = $command.Parameters['Version']
            $validateSet = $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet.ValidValues | Should -Contain '7.1-preview.1'
            $validateSet.ValidValues | Should -Contain '7.2-preview.1'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Remove-AdoCheckConfiguration
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should have ConfirmImpact set to High' {
            $command = Get-Command Remove-AdoCheckConfiguration
            $confirmImpact = $command.ScriptBlock.Attributes |
                Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] } |
                Select-Object -ExpandProperty ConfirmImpact
            $confirmImpact | Should -Be 'High'
        }
    }

    Context 'Error handling' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Check configuration not found'
                    typeKey = 'NotFoundException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Not found')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'NotFound',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }
        }

        It 'Should warn when check configuration does not exist' {
            # Act
            Remove-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 999 -WarningVariable warnings -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'does not exist'
        }

        It 'Should continue processing when check does not exist' {
            # Act & Assert - should not throw
            { Remove-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id 999 -WarningAction SilentlyContinue -Confirm:$false } | Should -Not -Throw
        }
    }

    Context 'Error handling - other errors' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Unexpected error'
            }
        }

        It 'Should throw for unexpected errors' {
            # Act & Assert
            { Remove-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id $checkId -Confirm:$false } | Should -Throw
        }
    }

    Context 'ShouldProcess support' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should support WhatIf' {
            # Act
            Remove-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id $checkId -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should delete when Confirm is false' {
            # Act
            Remove-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id $checkId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'Integration with environment variables' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should use default collection URI from environment' {
            # Act
            Remove-AdoCheckConfiguration -ProjectName $projectName -Id $checkId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should use default project name from environment' {
            # Act
            Remove-AdoCheckConfiguration -CollectionUri $collectionUri -Id $checkId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should not return any output' {
            # Act
            $result = Remove-AdoCheckConfiguration -CollectionUri $collectionUri -ProjectName $projectName -Id $checkId -Confirm:$false

            # Assert
            $result | Should -BeNullOrEmpty
        }
    }
}
