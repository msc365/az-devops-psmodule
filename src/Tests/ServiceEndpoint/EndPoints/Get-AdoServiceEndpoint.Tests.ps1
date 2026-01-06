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

Describe 'Get-AdoServiceEndpoint' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/test-org'
        $projectName = 'test-project'
        $endpointId = '12345678-1234-1234-1234-123456789012'
        $endpointName = 'test-endpoint'

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'Parameter Validation' {
        It 'Should have CollectionUri parameter' {
            Get-Command Get-AdoServiceEndpoint | Should -HaveParameter CollectionUri -Type string
        }

        It 'Should have ProjectName parameter with ProjectId alias' {
            $cmd = Get-Command Get-AdoServiceEndpoint
            $cmd | Should -HaveParameter ProjectName -Type string
            $cmd.Parameters['ProjectName'].Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Names parameter in ByNames parameter set' {
            $cmd = Get-Command Get-AdoServiceEndpoint
            $cmd | Should -HaveParameter Names -Type string[]
            $cmd.Parameters['Names'].ParameterSets['ByNames'] | Should -Not -BeNullOrEmpty
        }

        It 'Should have Ids parameter in ByIds parameter set' {
            $cmd = Get-Command Get-AdoServiceEndpoint
            $cmd | Should -HaveParameter Ids -Type string[]
            $cmd.Parameters['Ids'].ParameterSets['ByIds'] | Should -Not -BeNullOrEmpty
        }

        It 'Should have ActionFilter parameter with valid values' {
            $cmd = Get-Command Get-AdoServiceEndpoint
            $cmd | Should -HaveParameter ActionFilter -Type string
            $cmd.Parameters['ActionFilter'].Attributes.ValidValues | Should -Contain 'none'
            $cmd.Parameters['ActionFilter'].Attributes.ValidValues | Should -Contain 'manage'
        }

        It 'Should have Owner parameter with valid values' {
            $cmd = Get-Command Get-AdoServiceEndpoint
            $cmd | Should -HaveParameter Owner -Type string
            $cmd.Parameters['Owner'].Attributes.ValidValues | Should -Contain 'library'
            $cmd.Parameters['Owner'].Attributes.ValidValues | Should -Contain 'agentcloud'
        }

        It 'Should support ShouldProcess' {
            $cmd = Get-Command Get-AdoServiceEndpoint
            $cmd.Parameters.ContainsKey('WhatIf') -and $cmd.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should have default parameter set as ByNames' {
            $cmd = Get-Command Get-AdoServiceEndpoint
            $cmd.DefaultParameterSet | Should -Be 'ByNames'
        }
    }

    Context 'When retrieving endpoints by names' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{
                            id                               = $endpointId
                            name                             = $endpointName
                            type                             = 'AzureRM'
                            description                      = 'Test endpoint'
                            authorization                    = @{ scheme = 'ServicePrincipal' }
                            isShared                         = $false
                            isReady                          = $true
                            owner                            = 'library'
                            data                             = @{ subscriptionId = 'sub-123' }
                            serviceEndpointProjectReferences = @(@{ projectReference = @{ name = $projectName } })
                        }
                    )
                }
            }
        }

        It 'Should call API with single endpoint name' {
            Get-AdoServiceEndpoint -CollectionUri $collectionUri -ProjectName $projectName -Names $endpointName

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/$projectName/_apis/serviceendpoint/endpoints" -and
                $QueryParameters -eq "endpointNames=$endpointName" -and
                $Method -eq 'GET'
            }
        }

        It 'Should call API with multiple endpoint names' {
            $names = @('endpoint1', 'endpoint2')
            Get-AdoServiceEndpoint -CollectionUri $collectionUri -ProjectName $projectName -Names $names

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -eq "endpointNames=endpoint1,endpoint2"
            }
        }

        It 'Should return endpoint with expected properties' {
            $result = Get-AdoServiceEndpoint -CollectionUri $collectionUri -ProjectName $projectName -Names $endpointName

            $result.id | Should -Be $endpointId
            $result.name | Should -Be $endpointName
            $result.type | Should -Be 'AzureRM'
            $result.projectName | Should -Be $projectName
            $result.collectionUri | Should -Be $collectionUri
        }
    }

    Context 'When retrieving endpoints by IDs' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{
                            id                               = $endpointId
                            name                             = $endpointName
                            type                             = 'AzureRM'
                            description                      = ''
                            authorization                    = @{}
                            isShared                         = $false
                            isReady                          = $true
                            owner                            = 'library'
                            data                             = @{}
                            serviceEndpointProjectReferences = @()
                        }
                    )
                }
            }
        }

        It 'Should call API with single endpoint id' {
            Get-AdoServiceEndpoint -CollectionUri $collectionUri -ProjectName $projectName -Ids $endpointId

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -eq "endpointIds=$endpointId"
            }
        }

        It 'Should call API with multiple endpoint ids and ActionFilter' {
            Get-AdoServiceEndpoint -CollectionUri $collectionUri -ProjectName $projectName -Ids @('id1', 'id2') -ActionFilter 'manage'

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match 'endpointIds=id1,id2' -and
                $QueryParameters -match 'actionFilter=manage'
            }
        }
    }

    Context 'When using filter parameters' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{ value = @() }
            }
        }

        It 'Should include Owner filter in query' {
            Get-AdoServiceEndpoint -CollectionUri $collectionUri -ProjectName $projectName -Owner 'library'

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match 'owner=library'
            }
        }

        It 'Should include Type filter in query' {
            Get-AdoServiceEndpoint -CollectionUri $collectionUri -ProjectName $projectName -Type 'AzureRM'

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match 'type=AzureRM'
            }
        }

        It 'Should include IncludeFailed in query when specified' {
            Get-AdoServiceEndpoint -CollectionUri $collectionUri -ProjectName $projectName -IncludeFailed

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match 'includeFailed=true'
            }
        }

        It 'Should combine multiple filters' {
            Get-AdoServiceEndpoint -CollectionUri $collectionUri -ProjectName $projectName -Names $endpointName -Owner 'library' -Type 'AzureRM'

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -match 'endpointNames=' -and
                $QueryParameters -match 'owner=library' -and
                $QueryParameters -match 'type=AzureRM'
            }
        }
    }

    Context 'Error Handling' {
        It 'Should handle NotFoundException and show warning' {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{ message = 'NotFoundException' } | ConvertTo-Json
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

            { Get-AdoServiceEndpoint -CollectionUri $collectionUri -ProjectName $projectName -Names 'nonexistent' -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should rethrow non-NotFoundException errors' {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Some other error'
            }

            { Get-AdoServiceEndpoint -CollectionUri $collectionUri -ProjectName $projectName -Names $endpointName } | Should -Throw
        }
    }

    Context 'WhatIf Support' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{ value = @() }
            }
        }

        It 'Should not call API when WhatIf is specified' {
            Get-AdoServiceEndpoint -CollectionUri $collectionUri -ProjectName $projectName -Names $endpointName -WhatIf

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }

    Context 'Integration Scenarios' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    value = @(
                        @{ id = 'id1'; name = 'endpoint1'; type = 'AzureRM'; description = ''; authorization = @{}; isShared = $false; isReady = $true; owner = 'library'; data = @{}; serviceEndpointProjectReferences = @() }
                        @{ id = 'id2'; name = 'endpoint2'; type = 'GitHub'; description = ''; authorization = @{}; isShared = $false; isReady = $true; owner = 'library'; data = @{}; serviceEndpointProjectReferences = @() }
                    )
                }
            }
        }

        It 'Should return multiple endpoints' {
            $result = Get-AdoServiceEndpoint -CollectionUri $collectionUri -ProjectName $projectName

            $result.Count | Should -Be 2
            $result[0].name | Should -Be 'endpoint1'
            $result[1].name | Should -Be 'endpoint2'
        }

        It 'Should preserve all endpoint properties in output' {
            $result = Get-AdoServiceEndpoint -CollectionUri $collectionUri -ProjectName $projectName

            $result[0].PSObject.Properties.Name | Should -Contain 'id'
            $result[0].PSObject.Properties.Name | Should -Contain 'name'
            $result[0].PSObject.Properties.Name | Should -Contain 'type'
            $result[0].PSObject.Properties.Name | Should -Contain 'projectName'
            $result[0].PSObject.Properties.Name | Should -Contain 'collectionUri'
        }
    }
}
