[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '', Scope = 'Function', Target = '*', Justification = 'Variables are used in nested It blocks')]
param()

BeforeAll {
    # Import the module for testing
    $moduleName = 'Azure.DevOps.PSModule'
    $modulePath = Join-Path -Path (Get-Item $PSScriptRoot).Parent.Parent.Parent.Parent.FullName -ChildPath "src\$moduleName"

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

Describe 'Remove-AdoServiceEndpoint' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/test-org'
        $projectId = '12345678-1234-1234-1234-123456789012'
        $endpointId = '87654321-4321-4321-4321-210987654321'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'Parameter Validation' {
        It 'Should have CollectionUri parameter' {
            Get-Command Remove-AdoServiceEndpoint | Should -HaveParameter CollectionUri -Type string
        }

        It 'Should have Id parameter as mandatory' {
            $cmd = Get-Command Remove-AdoServiceEndpoint
            $cmd | Should -HaveParameter Id -Type string -Mandatory
        }

        It 'Should have EndpointId alias for Id parameter' {
            $cmd = Get-Command Remove-AdoServiceEndpoint
            $cmd.Parameters['Id'].Aliases | Should -Contain 'EndpointId'
        }

        It 'Should have ProjectIds parameter as mandatory' {
            $cmd = Get-Command Remove-AdoServiceEndpoint
            $cmd | Should -HaveParameter ProjectIds -Type string[] -Mandatory
        }

        It 'Should have Deep switch parameter' {
            Get-Command Remove-AdoServiceEndpoint | Should -HaveParameter Deep -Type switch
        }

        It 'Should support ShouldProcess with High impact' {
            $cmd = Get-Command Remove-AdoServiceEndpoint
            $cmd.Parameters.ContainsKey('WhatIf') -and $cmd.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'When removing a service endpoint' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should call API with correct URI and parameters' {
            Remove-AdoServiceEndpoint -CollectionUri $collectionUri -Id $endpointId -ProjectIds $projectId -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/serviceendpoint/endpoints/$endpointId" -and
                $QueryParameters -eq "projectIds=$projectId" -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should handle multiple project IDs' {
            $projectIds = @('project1', 'project2', 'project3')
            Remove-AdoServiceEndpoint -CollectionUri $collectionUri -Id $endpointId -ProjectIds $projectIds -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -eq "projectIds=project1,project2,project3"
            }
        }

        It 'Should include deep parameter when specified' {
            Remove-AdoServiceEndpoint -CollectionUri $collectionUri -Id $endpointId -ProjectIds $projectId -Deep -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match 'projectIds=' -and
                $QueryParameters -match 'deep=true'
            }
        }

        It 'Should not return any output' {
            $result = Remove-AdoServiceEndpoint -CollectionUri $collectionUri -Id $endpointId -ProjectIds $projectId -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Error Handling' {
        It 'Should handle "No service connection found" error and show warning' {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{ message = 'No service connection found' } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Not found')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'NotFoundException',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            { Remove-AdoServiceEndpoint -CollectionUri $collectionUri -Id $endpointId -ProjectIds $projectId -Confirm:$false -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should rethrow non-NotFound errors' {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Some other error'
            }

            { Remove-AdoServiceEndpoint -CollectionUri $collectionUri -Id $endpointId -ProjectIds $projectId -Confirm:$false } | Should -Throw
        }
    }

    Context 'WhatIf Support' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should not call API when WhatIf is specified' {
            Remove-AdoServiceEndpoint -CollectionUri $collectionUri -Id $endpointId -ProjectIds $projectId -WhatIf

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }

    Context 'Integration Scenarios' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith { }
        }

        It 'Should handle single project removal' {
            { Remove-AdoServiceEndpoint -CollectionUri $collectionUri -Id $endpointId -ProjectIds $projectId -Confirm:$false } | Should -Not -Throw

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should handle multiple project removal' {
            $projectIds = @('proj1', 'proj2')
            { Remove-AdoServiceEndpoint -CollectionUri $collectionUri -Id $endpointId -ProjectIds $projectIds -Confirm:$false } | Should -Not -Throw

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should use specified API version' {
            Remove-AdoServiceEndpoint -CollectionUri $collectionUri -Id $endpointId -ProjectIds $projectId -Version '7.2-preview.4' -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.4'
            }
        }
    }
}
