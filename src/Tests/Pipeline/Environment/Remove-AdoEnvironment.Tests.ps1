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
}

Describe 'Remove-AdoEnvironment' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/my-org'
        $projectName = 'my-project-1'
        $environmentId = 123

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'When removing environment successfully' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                # DELETE typically returns nothing or empty response
                return $null
            }
        }

        It 'Should remove environment by ID' {
            # Act
            Remove-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id $environmentId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match "_apis/pipelines/environments/123`$" -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should support pipeline input of ID' {
            # Act
            $environmentId | Remove-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should support pipeline input of multiple IDs' {
            # Arrange
            $environmentIds = @(123, 124, 125)

            # Act
            $environmentIds | Remove-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
        }

        It 'Should use correct API version' {
            # Act
            Remove-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id $environmentId -Version '7.2-preview.1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }
    }

    Context 'When environment is not found' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Environment with ID 999 does not exist.'
                    typeKey = 'EnvironmentNotFoundException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Environment not found')
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

        It 'Should write warning when environment is not found' {
            # Act
            Remove-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id 999 -Confirm:$false -WarningAction SilentlyContinue -WarningVariable warning

            # Assert
            $warning | Should -Not -BeNullOrEmpty
            $warning | Should -Match 'Environment with ID 999 does not exist'
        }

        It 'Should not throw exception when environment is not found' {
            # Act & Assert
            { Remove-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id 999 -Confirm:$false -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should continue processing remaining IDs when one is not found' {
            # Arrange
            $mockCallCount = 0
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $script:mockCallCount++
                if ($script:mockCallCount -eq 2) {
                    # Second call fails
                    $errorMessage = @{
                        message = 'Environment with ID 998 does not exist.'
                        typeKey = 'EnvironmentNotFoundException'
                    } | ConvertTo-Json
                    $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                    $exception = [System.Exception]::new('Environment not found')
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                        $exception,
                        'NotFoundException',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $null
                    )
                    $errorRecord.ErrorDetails = $errorDetails
                    throw $errorRecord
                }
                return $null
            }

            # Act
            @(123, 998, 125) | Remove-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false -WarningAction SilentlyContinue

            # Assert - all three should be attempted
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
        }
    }

    Context 'When API call fails with unexpected error' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'API connection failed'
            }
        }

        It 'Should throw exception for unexpected errors' {
            # Act & Assert
            { Remove-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id $environmentId -Confirm:$false } | Should -Throw -ExpectedMessage '*API connection failed*'
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter with ValidateScript attribute' {
            # Arrange
            $command = Get-Command Remove-AdoEnvironment
            $param = $command.Parameters['CollectionUri']
            $validateScript = $param.Attributes | Where-Object { $_ -is [ValidateScript] }

            # Assert
            $validateScript | Should -Not -BeNullOrEmpty
        }

        It 'Should have ProjectName parameter with alias ProjectId' {
            # Arrange
            $command = Get-Command Remove-AdoEnvironment
            $param = $command.Parameters['ProjectName']

            # Assert
            $param.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Id as a mandatory parameter' {
            # Arrange
            $command = Get-Command Remove-AdoEnvironment
            $param = $command.Parameters['Id']
            $mandatoryAttr = $param.Attributes | Where-Object {
                $_ -is [Parameter] -and $_.Mandatory
            }

            # Assert
            $mandatoryAttr | Should -Not -BeNullOrEmpty
        }

        It 'Should have Id parameter that accepts pipeline input' {
            # Arrange
            $command = Get-Command Remove-AdoEnvironment
            $param = $command.Parameters['Id']
            $pipelineAttr = $param.Attributes | Where-Object {
                $_ -is [Parameter] -and $_.ValueFromPipeline
            }

            # Assert
            $pipelineAttr | Should -Not -BeNullOrEmpty
        }

        It 'Should have Id parameter that accepts pipeline input by property name' {
            # Arrange
            $command = Get-Command Remove-AdoEnvironment
            $param = $command.Parameters['Id']
            $pipelineAttr = $param.Attributes | Where-Object {
                $_ -is [Parameter] -and $_.ValueFromPipelineByPropertyName
            }

            # Assert
            $pipelineAttr | Should -Not -BeNullOrEmpty
        }

        It 'Should have Version parameter with ValidateSet attribute' {
            # Arrange
            $command = Get-Command Remove-AdoEnvironment
            $param = $command.Parameters['Version']
            $validateSet = $param.Attributes | Where-Object { $_ -is [ValidateSet] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain '7.2-preview.1'
        }

        It 'Should have Version parameter with alias ApiVersion' {
            # Arrange
            $command = Get-Command Remove-AdoEnvironment
            $param = $command.Parameters['Version']

            # Assert
            $param.Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should support ShouldProcess (WhatIf and Confirm parameters)' {
            # Arrange
            $command = Get-Command Remove-AdoEnvironment

            # Assert
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'ShouldProcess support' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return $null
            }
        }

        It 'Should not call API when WhatIf is specified' {
            # Act
            Remove-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id $environmentId -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should call API when Confirm is false' {
            # Act
            Remove-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id $environmentId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should not call API and support WhatIf parameter' {
            # This test verifies WhatIf prevents API calls
            # Act
            Remove-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id $environmentId -WhatIf

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }

    Context 'ConfirmImpact level' {
        It 'Should have ConfirmImpact set to High' {
            # Arrange
            $command = Get-Command Remove-AdoEnvironment
            $cmdletBinding = $command.ScriptBlock.Attributes | Where-Object { $_ -is [CmdletBinding] }

            # Assert
            $cmdletBinding.ConfirmImpact | Should -Be 'High'
        }
    }

    Context 'Integration scenarios' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return $null
            }
        }

        It 'Should handle removing environment with custom API version' {
            # Act
            Remove-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Id $environmentId -Version '7.2-preview.1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should process array of environment IDs correctly' {
            # Arrange
            $ids = 1..5

            # Act
            $ids | Remove-AdoEnvironment -CollectionUri $collectionUri -ProjectName $projectName -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 5
        }
    }
}
