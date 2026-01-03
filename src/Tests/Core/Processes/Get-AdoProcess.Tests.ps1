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

    # Mock Invoke-AdoRestMethod for successful responses
    Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
        param($Uri, $Method, $Version)

        # Suppress unused parameter warnings
        $null = $Uri, $Method, $Version

        # Return mock process data
        return @{
            count = 4
            value = @(
                @{
                    id          = 'adcc42ab-9882-485e-a3ed-7678f01f66bc'
                    name        = 'Agile'
                    description = 'This template is flexible and will work great for most teams using Agile planning methods, including those practicing Scrum.'
                    url         = 'https://dev.azure.com/testorg/_apis/process/processes/adcc42ab-9882-485e-a3ed-7678f01f66bc'
                    type        = 'system'
                    isDefault   = $true
                },
                @{
                    id          = '6b724908-ef14-45cf-84f8-768b5384da45'
                    name        = 'Scrum'
                    description = 'This template is for teams who follow the Scrum framework.'
                    url         = 'https://dev.azure.com/testorg/_apis/process/processes/6b724908-ef14-45cf-84f8-768b5384da45'
                    type        = 'system'
                    isDefault   = $false
                },
                @{
                    id          = '27450541-8e31-4150-9947-dc59f998fc01'
                    name        = 'CMMI'
                    description = 'This template is for more formal projects requiring a framework for process improvement and an auditable record of decisions.'
                    url         = 'https://dev.azure.com/testorg/_apis/process/processes/27450541-8e31-4150-9947-dc59f998fc01'
                    type        = 'system'
                    isDefault   = $false
                },
                @{
                    id          = 'b8a3a935-7e91-48b8-a94c-606d37c3e9f2'
                    name        = 'Basic'
                    description = 'This template is the simplest model that tracks issues, tasks, and epics.'
                    url         = 'https://dev.azure.com/testorg/_apis/process/processes/b8a3a935-7e91-48b8-a94c-606d37c3e9f2'
                    type        = 'system'
                    isDefault   = $false
                }
            )
        }
    }
}

Describe 'Get-AdoProcess' {

    Context 'When retrieving all processes' {
        It 'Should retrieve all processes when no name is specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = Get-AdoProcess -CollectionUri $collectionUri

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 4
            $result[0].name | Should -Be 'Agile'
            $result[1].name | Should -Be 'Scrum'
            $result[2].name | Should -Be 'CMMI'
            $result[3].name | Should -Be 'Basic'

            # Verify Invoke-AdoRestMethod was called correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/process/processes" -and
                $Method -eq 'GET' -and
                $Version -eq '7.1'
            }
        }

        It 'Should use default version when Version parameter is not specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            Get-AdoProcess -CollectionUri $collectionUri

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should use environment variable when CollectionUri is not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/envorg'

            # Act
            Get-AdoProcess

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/envorg/_apis/process/processes'
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
        }
    }

    Context 'When retrieving a specific process by name' {
        It 'Should retrieve process by name' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $processName = 'Agile'

            # Act
            $result = Get-AdoProcess -CollectionUri $collectionUri -Name $processName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $processName
            $result.id | Should -Be 'adcc42ab-9882-485e-a3ed-7678f01f66bc'
            $result.collectionUri | Should -Be $collectionUri
            $result.isDefault | Should -Be $true

            # Verify Invoke-AdoRestMethod was called correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/process/processes" -and
                $Method -eq 'GET' -and
                $Version -eq '7.1'
            }
        }

        It 'Should retrieve Scrum process by name' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $processName = 'Scrum'

            # Act
            $result = Get-AdoProcess -CollectionUri $collectionUri -Name $processName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $processName
            $result.id | Should -Be '6b724908-ef14-45cf-84f8-768b5384da45'
            $result.isDefault | Should -Be $false
        }

        It 'Should retrieve CMMI process by name' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $processName = 'CMMI'

            # Act
            $result = Get-AdoProcess -CollectionUri $collectionUri -Name $processName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $processName
            $result.id | Should -Be '27450541-8e31-4150-9947-dc59f998fc01'
        }

        It 'Should retrieve Basic process by name' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $processName = 'Basic'

            # Act
            $result = Get-AdoProcess -CollectionUri $collectionUri -Name $processName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be $processName
            $result.id | Should -Be 'b8a3a935-7e91-48b8-a94c-606d37c3e9f2'
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept process names from pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $processNames = @('Agile', 'Scrum')

            # Act
            $result = $processNames | Get-AdoProcess -CollectionUri $collectionUri

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].name | Should -Be 'Agile'
            $result[1].name | Should -Be 'Scrum'

            # Verify Invoke-AdoRestMethod was called once for each piped process name
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }

        It 'Should accept process objects with name property from pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $processObjects = @(
                [PSCustomObject]@{ Name = 'Agile' },
                [PSCustomObject]@{ Name = 'Scrum' }
            )

            # Act
            $result = $processObjects | Get-AdoProcess -CollectionUri $collectionUri

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }

        It 'Should accept process names using Process alias' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $processObject = [PSCustomObject]@{ Process = 'Agile' }

            # Act
            $result = $processObject | Get-AdoProcess -CollectionUri $collectionUri

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'Agile'
        }

        It 'Should accept process names using ProcessName alias' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $processObject = [PSCustomObject]@{ ProcessName = 'Scrum' }

            # Act
            $result = $processObject | Get-AdoProcess -CollectionUri $collectionUri

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'Scrum'
        }
    }

    Context 'When using Version parameter' {
        It 'Should use version 7.1 when specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            Get-AdoProcess -CollectionUri $collectionUri -Version '7.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should use version 7.2-preview.1 when specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            Get-AdoProcess -CollectionUri $collectionUri -Version '7.2-preview.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should use ApiVersion alias for Version parameter' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            Get-AdoProcess -CollectionUri $collectionUri -ApiVersion '7.2-preview.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri parameter that accepts string' {
            # Arrange & Act
            $command = Get-Command Get-AdoProcess
            $param = $command.Parameters['CollectionUri']

            # Assert
            $param | Should -Not -BeNullOrEmpty
            $param.ParameterType.Name | Should -Be 'String'
            $param.Attributes.ValueFromPipelineByPropertyName | Should -Contain $true
        }

        It 'Should have Name parameter that accepts string' {
            # Arrange & Act
            $command = Get-Command Get-AdoProcess
            $param = $command.Parameters['Name']

            # Assert
            $param | Should -Not -BeNullOrEmpty
            $param.ParameterType.Name | Should -Be 'String'
            $param.Attributes.ValueFromPipeline | Should -Contain $true
            $param.Attributes.ValueFromPipelineByPropertyName | Should -Contain $true
        }

        It 'Should have Name parameter with ValidateSet for Agile, Scrum, CMMI, Basic' {
            # Arrange & Act
            $command = Get-Command Get-AdoProcess
            $param = $command.Parameters['Name']
            $validateSet = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'Agile'
            $validateSet.ValidValues | Should -Contain 'Scrum'
            $validateSet.ValidValues | Should -Contain 'CMMI'
            $validateSet.ValidValues | Should -Contain 'Basic'
            $validateSet.ValidValues.Count | Should -Be 4
        }

        It 'Should have Version parameter with ValidateSet for 7.1 and 7.2-preview.1' {
            # Arrange & Act
            $command = Get-Command Get-AdoProcess
            $param = $command.Parameters['Version']
            $validateSet = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain '7.1'
            $validateSet.ValidValues | Should -Contain '7.2-preview.1'
            $validateSet.ValidValues.Count | Should -Be 2
        }

        It 'Should have Name parameter with Process alias' {
            # Arrange & Act
            $command = Get-Command Get-AdoProcess
            $param = $command.Parameters['Name']

            # Assert
            $param.Aliases | Should -Contain 'Process'
        }

        It 'Should have Name parameter with ProcessName alias' {
            # Arrange & Act
            $command = Get-Command Get-AdoProcess
            $param = $command.Parameters['Name']

            # Assert
            $param.Aliases | Should -Contain 'ProcessName'
        }

        It 'Should have Version parameter with ApiVersion alias' {
            # Arrange & Act
            $command = Get-Command Get-AdoProcess
            $param = $command.Parameters['Version']

            # Assert
            $param.Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should have CollectionUri parameter that is not mandatory' {
            # Arrange & Act
            $command = Get-Command Get-AdoProcess
            $param = $command.Parameters['CollectionUri']
            $mandatory = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | Select-Object -First 1

            # Assert
            $mandatory.Mandatory | Should -Be $false
        }

        It 'Should have Name parameter that is not mandatory' {
            # Arrange & Act
            $command = Get-Command Get-AdoProcess
            $param = $command.Parameters['Name']
            $mandatory = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | Select-Object -First 1

            # Assert
            $mandatory.Mandatory | Should -Be $false
        }
    }

    Context 'Output validation' {
        It 'Should return PSCustomObject with expected properties' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = Get-AdoProcess -CollectionUri $collectionUri -Name 'Agile'

            # Assert
            $result | Should -BeOfType [PSCustomObject]
            $result.PSObject.Properties.Name | Should -Contain 'id'
            $result.PSObject.Properties.Name | Should -Contain 'name'
            $result.PSObject.Properties.Name | Should -Contain 'description'
            $result.PSObject.Properties.Name | Should -Contain 'url'
            $result.PSObject.Properties.Name | Should -Contain 'type'
            $result.PSObject.Properties.Name | Should -Contain 'isDefault'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should return multiple PSCustomObjects when retrieving all processes' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = Get-AdoProcess -CollectionUri $collectionUri

            # Assert
            $result | Should -HaveCount 4
            $result | ForEach-Object {
                $_ | Should -BeOfType [PSCustomObject]
            }
        }

        It 'Should include collectionUri in output' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = Get-AdoProcess -CollectionUri $collectionUri -Name 'Agile'

            # Assert
            $result.collectionUri | Should -Be $collectionUri
        }

        It 'Should return process with all properties populated' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $result = Get-AdoProcess -CollectionUri $collectionUri -Name 'Agile'

            # Assert
            $result.id | Should -Not -BeNullOrEmpty
            $result.name | Should -Not -BeNullOrEmpty
            $result.description | Should -Not -BeNullOrEmpty
            $result.url | Should -Not -BeNullOrEmpty
            $result.type | Should -Not -BeNullOrEmpty
            $result.isDefault | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Error handling' {
        It 'Should throw when Invoke-AdoRestMethod fails' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'REST API call failed'
            }

            # Act & Assert
            { Get-AdoProcess -CollectionUri $collectionUri } | Should -Throw
        }

        It 'Should handle network errors gracefully' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $exception = [System.Net.WebException]::new('Network error')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'NetworkError',
                    [System.Management.Automation.ErrorCategory]::ConnectionError,
                    $null
                )
                throw $errorRecord
            }

            # Act & Assert
            { Get-AdoProcess -CollectionUri $collectionUri } | Should -Throw
        }

        It 'Should handle unauthorized access errors' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $exception = [System.Net.WebException]::new('Unauthorized')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'UnauthorizedAccess',
                    [System.Management.Automation.ErrorCategory]::PermissionDenied,
                    $null
                )
                throw $errorRecord
            }

            # Act & Assert
            { Get-AdoProcess -CollectionUri $collectionUri } | Should -Throw
        }
    }

    Context 'ShouldProcess support' {
        It 'Should support WhatIf parameter' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            Get-AdoProcess -CollectionUri $collectionUri -WhatIf

            # Assert
            # When WhatIf is used, Invoke-AdoRestMethod should not be called
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should process when Confirm is bypassed' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            Get-AdoProcess -CollectionUri $collectionUri -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should display correct ShouldProcess message for all processes' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            Get-AdoProcess -CollectionUri $collectionUri -WhatIf

            # Assert - WhatIf should show "Get Processes" message
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should display correct ShouldProcess message for specific process' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            Get-AdoProcess -CollectionUri $collectionUri -Name 'Agile' -WhatIf

            # Assert - WhatIf should show "Get Process: Agile" message
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }

    Context 'Integration scenarios' {
        It 'Should work in a typical workflow retrieving all processes then filtering to one' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act - First get all processes
            $allProcesses = Get-AdoProcess -CollectionUri $collectionUri

            # Then get specific process
            $agileProcess = Get-AdoProcess -CollectionUri $collectionUri -Name 'Agile'

            # Assert
            $allProcesses | Should -HaveCount 4
            $agileProcess | Should -Not -BeNullOrEmpty
            $agileProcess.name | Should -Be 'Agile'
            $allProcesses.name | Should -Contain $agileProcess.name
        }

        It 'Should work with pipeline to retrieve multiple specific processes' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $processNames = @('Agile', 'Scrum')

            # Act
            $result = $processNames | Get-AdoProcess -CollectionUri $collectionUri

            # Assert
            $result | Should -HaveCount 2
            $result[0].name | Should -Be 'Agile'
            $result[1].name | Should -Be 'Scrum'
        }

        It 'Should work when chained with other cmdlets using pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'

            # Act
            $defaultProcess = Get-AdoProcess -CollectionUri $collectionUri | Where-Object { $_.isDefault -eq $true }

            # Assert
            $defaultProcess | Should -Not -BeNullOrEmpty
            $defaultProcess.name | Should -Be 'Agile'
            $defaultProcess.isDefault | Should -Be $true
        }
    }
}
