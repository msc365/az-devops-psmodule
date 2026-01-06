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

Describe 'New-AdoServiceEndpoint' {
    BeforeAll {
        $collectionUri = 'https://dev.azure.com/test-org'
        $projectName = 'test-project'
        $projectId = '12345678-1234-1234-1234-123456789012'
        $endpointName = 'test-endpoint'
        $endpointId = '87654321-4321-4321-4321-210987654321'

        $validConfiguration = [PSCustomObject]@{
            data                             = [PSCustomObject]@{
                creationMode     = 'Manual'
                environment      = 'AzureCloud'
                scopeLevel       = 'Subscription'
                subscriptionId   = '00000000-0000-0000-0000-000000000000'
                subscriptionName = 'my-subscription-1'
            }
            name                             = $endpointName
            type                             = 'AzureRM'
            url                              = 'https://management.azure.com/'
            authorization                    = [PSCustomObject]@{
                parameters = [PSCustomObject]@{
                    serviceprincipalid = '11111111-1111-1111-1111-111111111111'
                    tenantid           = '22222222-2222-2222-2222-222222222222'
                    scope              = '/subscriptions/00000000-0000-0000-0000-000000000000'
                }
                scheme     = 'WorkloadIdentityFederation'
            }
            isShared                         = $false
            serviceEndpointProjectReferences = [PSCustomObject[]]@(
                [PSCustomObject]@{
                    name             = $endpointName
                    projectReference = [PSCustomObject]@{
                        id   = $projectId
                        name = $projectName
                    }
                }
            )
        }

        Mock Confirm-Default -ModuleName $moduleName -MockWith { }
    }

    Context 'Parameter Validation' {
        It 'Should have CollectionUri parameter' {
            Get-Command New-AdoServiceEndpoint | Should -HaveParameter CollectionUri -Type string
        }

        It 'Should have Configuration parameter as mandatory' {
            $cmd = Get-Command New-AdoServiceEndpoint
            $cmd | Should -HaveParameter Configuration -Type PSCustomObject -Mandatory
        }

        It 'Should support ShouldProcess with High impact' {
            $cmd = Get-Command New-AdoServiceEndpoint
            $cmd.Parameters.ContainsKey('WhatIf') -and $cmd.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'When creating a service endpoint' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id                               = $endpointId
                    name                             = $endpointName
                    type                             = 'AzureRM'
                    description                      = 'Test endpoint'
                    authorization                    = @{ scheme = 'WorkloadIdentityFederation' }
                    url                              = 'https://management.azure.com/'
                    isShared                         = $false
                    isReady                          = $true
                    owner                            = 'library'
                    data                             = @{ subscriptionId = '00000000-0000-0000-0000-000000000000' }
                    serviceEndpointProjectReferences = @(@{ projectReference = @{ name = $projectName; id = $projectId } })
                }
            }
        }

        It 'Should call API with correct URI (without project in path)' {
            New-AdoServiceEndpoint -CollectionUri $collectionUri -Configuration $validConfiguration -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/serviceendpoint/endpoints" -and
                $Method -eq 'POST'
            }
        }

        It 'Should return endpoint with expected properties' {
            $result = New-AdoServiceEndpoint -CollectionUri $collectionUri -Configuration $validConfiguration -Confirm:$false

            $result.id | Should -Be $endpointId
            $result.name | Should -Be $endpointName
            $result.projectName | Should -Be $projectName
            $result.collectionUri | Should -Be $collectionUri
        }

        It 'Should extract project name from Configuration' {
            $result = New-AdoServiceEndpoint -CollectionUri $collectionUri -Configuration $validConfiguration -Confirm:$false

            $result.projectName | Should -Be $projectName
        }
    }

    Context 'When handling duplicate endpoint' {
        It 'Should handle DuplicateServiceConnectionException and fall back to GET' {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                if ($Method -eq 'POST') {
                    $errorMessage = @{ message = 'DuplicateServiceConnectionException' } | ConvertTo-Json
                    $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                    $exception = [System.Exception]::new('Duplicate')
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                        $exception,
                        'DuplicateException',
                        [System.Management.Automation.ErrorCategory]::ResourceExists,
                        $null
                    )
                    $errorRecord.ErrorDetails = $errorDetails
                    throw $errorRecord
                } else {
                    return @{
                        value = @(
                            @{
                                id                               = $endpointId
                                name                             = $endpointName
                                type                             = 'AzureRM'
                                description                      = 'Existing endpoint'
                                authorization                    = @{ scheme = 'WorkloadIdentityFederation' }
                                isShared                         = $false
                                url                              = 'https://management.azure.com/'
                                isReady                          = $true
                                owner                            = 'library'
                                data                             = @{}
                                serviceEndpointProjectReferences = @()
                            }
                        )
                    }
                }
            }

            $result = New-AdoServiceEndpoint -CollectionUri $collectionUri -Configuration $validConfiguration -Confirm:$false -WarningAction SilentlyContinue

            $result.id | Should -Be $endpointId
            $result.name | Should -Be $endpointName
        }

        It 'Should call GET API with correct parameters on duplicate' {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                if ($Method -eq 'POST') {
                    $errorMessage = @{ message = 'DuplicateServiceConnectionException' } | ConvertTo-Json
                    $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                    $exception = [System.Exception]::new('Duplicate')
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                        $exception,
                        'DuplicateException',
                        [System.Management.Automation.ErrorCategory]::ResourceExists,
                        $null
                    )
                    $errorRecord.ErrorDetails = $errorDetails
                    throw $errorRecord
                } else {
                    return @{ value = @(@{ id = $endpointId; name = $endpointName; type = 'AzureRM'; description = ''; authorization = @{}; isShared = $false; url = ''; isReady = $true; owner = 'library'; data = @{}; serviceEndpointProjectReferences = @() }) }
                }
            }

            New-AdoServiceEndpoint -CollectionUri $collectionUri -Configuration $validConfiguration -Confirm:$false -WarningAction SilentlyContinue

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Times 1 -ParameterFilter {
                $Method -eq 'GET' -and
                $Uri -eq "$collectionUri/$projectName/_apis/serviceendpoint/endpoints" -and
                $QueryParameters -eq "endpointNames=$endpointName"
            }
        }
    }

    Context 'Error Handling' {
        It 'Should rethrow non-duplicate errors' {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Some other error'
            }

            { New-AdoServiceEndpoint -CollectionUri $collectionUri -Configuration $validConfiguration -Confirm:$false } | Should -Throw
        }
    }

    Context 'WhatIf Support' {
        BeforeAll {
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{ id = $endpointId; name = $endpointName; type = 'AzureRM'; description = ''; authorization = @{}; url = ''; isShared = $false; isReady = $true; owner = 'library'; data = @{}; serviceEndpointProjectReferences = @() }
            }
        }

        It 'Should not call API when WhatIf is specified' {
            New-AdoServiceEndpoint -CollectionUri $collectionUri -Configuration $validConfiguration -WhatIf

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }
}
