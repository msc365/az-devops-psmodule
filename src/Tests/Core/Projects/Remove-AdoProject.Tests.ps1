[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '', Scope = 'Function', Target = '*', Justification = 'Variables are used in nested It blocks')]
param()

BeforeAll {
    # Module import logic
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

    # Common test variables
    $script:testCollectionUri = 'https://dev.azure.com/testorg'
    $script:testProjectId = '00000000-0000-0000-0000-000000000001'
    $script:testProjectName = 'TestProject'
    $script:testOperationUrl = "$script:testCollectionUri/_apis/operations/00000000-0000-0000-0000-000000000001"
}

Describe 'Remove-AdoProject' {

    Context 'Primary functionality - Delete by ID' {
        BeforeAll {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id     = '00000000-0000-0000-0000-000000000001'
                    status = 'succeeded'
                    url    = $script:testOperationUrl
                }
            }
        }

        It 'Should delete a project when valid GUID is provided' {
            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectId -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$($script:testCollectionUri)/_apis/projects/$($script:testProjectId)" -and
                $Method -eq 'DELETE' -and
                $Version -eq '7.1'
            }
        }

        It 'Should use default API version 7.1' {
            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectId -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1'
            }
        }

        It 'Should use custom API version when specified' {
            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectId -Version '7.2-preview.4' -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.4'
            }
        }
    }

    Context 'Primary functionality - Delete by name' {
        BeforeAll {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return @{ id = $script:testProjectId }
            }
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id     = '00000000-0000-0000-0000-000000000001'
                    status = 'succeeded'
                    url    = $script:testOperationUrl
                }
            }
        }

        It 'Should resolve project name to ID before deletion' {
            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectName -Confirm:$false

            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Name -eq $script:testProjectName
            }
        }

        It 'Should delete project using resolved ID' {
            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectName -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$($script:testCollectionUri)/_apis/projects/$($script:testProjectId)" -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should skip deletion if project name cannot be resolved' {
            Mock Get-AdoProject -ModuleName $moduleName -MockWith { return $null }

            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id 'NonExistentProject' -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }

    Context 'Status polling - Successful deletion' {
        BeforeAll {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Start-Sleep -ModuleName $moduleName -MockWith { }

            $script:pollCount = 0
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                if ($Method -eq 'DELETE') {
                    return @{
                        id     = '00000000-0000-0000-0000-000000000001'
                        status = 'inProgress'
                        url    = $script:testOperationUrl
                    }
                } else {
                    # GET request for polling
                    $script:pollCount++
                    if ($script:pollCount -ge 2) {
                        return @{
                            id     = '00000000-0000-0000-0000-000000000001'
                            status = 'succeeded'
                            url    = $script:testOperationUrl
                        }
                    } else {
                        return @{
                            id     = '00000000-0000-0000-0000-000000000001'
                            status = 'inProgress'
                            url    = $script:testOperationUrl
                        }
                    }
                }
            }
        }

        It 'Should poll for completion status when deletion is in progress' {
            $script:pollCount = 0
            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectId -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Method -eq 'DELETE'
            }
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2 -ParameterFilter {
                $Method -eq 'GET' -and $Uri -eq $script:testOperationUrl
            }
        }

        It 'Should call Start-Sleep between polling attempts' {
            $script:pollCount = 0
            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectId -Confirm:$false

            Should -Invoke Start-Sleep -ModuleName $moduleName -Exactly 2 -ParameterFilter {
                $Seconds -eq 3
            }
        }
    }

    Context 'Status polling - Failed deletion' {
        BeforeAll {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Start-Sleep -ModuleName $moduleName -MockWith { }
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                if ($Method -eq 'DELETE') {
                    return @{
                        id     = '00000000-0000-0000-0000-000000000001'
                        status = 'inProgress'
                        url    = $script:testOperationUrl
                    }
                } else {
                    return @{
                        id     = '00000000-0000-0000-0000-000000000001'
                        status = 'failed'
                        url    = $script:testOperationUrl
                    }
                }
            }
        }

        It 'Should throw exception when deletion status is failed' {
            { Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectId -Confirm:$false -ErrorAction Stop } |
                Should -Throw -ExpectedMessage 'Project deletion failed.'
        }
    }

    Context 'Pipeline input' {
        BeforeAll {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id     = '00000000-0000-0000-0000-000000000001'
                    status = 'succeeded'
                    url    = $script:testOperationUrl
                }
            }
        }

        It 'Should accept project IDs from pipeline' {
            $projectIds = @('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002')
            $projectIds | Remove-AdoProject -CollectionUri $script:testCollectionUri -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2 -ParameterFilter {
                $Method -eq 'DELETE'
            }
        }

        It 'Should accept project names from pipeline' {
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return @{ id = '00000000-0000-0000-0000-000000000002' }
            }

            @('Project1', 'Project2') | Remove-AdoProject -CollectionUri $script:testCollectionUri -Confirm:$false

            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2 -ParameterFilter {
                $Method -eq 'DELETE'
            }
        }
    }

    Context 'Error handling - NotFound scenarios' {
        BeforeAll {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $exception = [System.Net.WebException]::new('Project does not exist')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'NotFoundException',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $script:testProjectId
                )
                $errorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"ProjectDoesNotExistWithNameException: The project does not exist."}')
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }
        }

        It 'Should write warning when project is not found' {
            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectId -Confirm:$false -WarningVariable warnings -WarningAction SilentlyContinue

            $warnings.Count | Should -BeGreaterThan 0
        }
    }

    Context 'Error handling - Message-based NotFound' {
        BeforeAll {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $exception = [System.Net.WebException]::new('Project does not exist')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'ProjectDoesNotExist',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $script:testProjectId
                )
                $errorDetails = [System.Management.Automation.ErrorDetails]::new('{"message":"ProjectDoesNotExistWithNameException: The project with ID ' + $script:testProjectId + ' does not exist."}')
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }
        }

        It 'Should write warning when error message indicates project does not exist' {
            { Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectId -Confirm:$false -WarningAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'Error handling - Other exceptions' {
        BeforeAll {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Unauthorized access'
            }
        }

        It 'Should throw exception for non-NotFound errors' {
            { Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectId -Confirm:$false -ErrorAction Stop } |
                Should -Throw -ExpectedMessage 'Unauthorized access'
        }
    }

    Context 'Name to ID resolution' {
        It 'Should resolve project name to ID before deletion' {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return @{ id = 'resolved-id-456' }
            }
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id     = '00000000-0000-0000-0000-000000000001'
                    status = 'succeeded'
                    url    = $script:testOperationUrl
                }
            }

            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id 'my-project-name' -Confirm:$false

            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Name -eq 'my-project-name'
            }

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$($script:testCollectionUri)/_apis/projects/resolved-id-456" -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should use ID directly when valid GUID is provided' {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                throw 'Get-AdoProject should not be called for GUID'
            }
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id     = '00000000-0000-0000-0000-000000000001'
                    status = 'succeeded'
                    url    = $script:testOperationUrl
                }
            }

            $guidId = '12345678-1234-1234-1234-123456789012'

            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $guidId -Confirm:$false

            # Should NOT call Get-AdoProject for GUID
            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 0

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$($script:testCollectionUri)/_apis/projects/$guidId" -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should skip deletion when name cannot be resolved' {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return $null
            }
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Invoke-AdoRestMethod should not be called when name is not resolved'
            }

            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id 'non-existent-name' -Confirm:$false

            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 1
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }

    Context 'Parameter validation' {
        It 'Should have Id as a mandatory parameter' {
            $command = Get-Command Remove-AdoProject
            $nameParam = $command.Parameters['Name']
            $paramAttributes = $nameParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            $paramAttributes.Mandatory | Should -Contain $true
        }

        It 'Should accept ProjectId as an alias for Id parameter' {
            $command = Get-Command Remove-AdoProject
            $nameParam = $command.Parameters['Name']
            $aliasAttribute = $nameParam.Attributes | Where-Object { $_ -is [System.Management.Automation.AliasAttribute] }
            $aliasAttribute.AliasNames | Should -Contain 'ProjectId'
        }

        It 'Should accept ApiVersion as an alias for Version parameter' {
            $command = Get-Command Remove-AdoProject
            $versionParam = $command.Parameters['Version']
            $versionParam.Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should accept only valid API versions' {
            $command = Get-Command Remove-AdoProject
            $versionParam = $command.Parameters['Version']
            $validateSet = $versionParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet.ValidValues | Should -Contain '7.1'
            $validateSet.ValidValues | Should -Contain '7.2-preview.4'
        }

        It 'Should have CollectionUri with default value' {
            $command = Get-Command Remove-AdoProject
            $collectionParam = $command.Parameters['CollectionUri']
            $collectionParam.Attributes.Mandatory | Should -Not -Contain $true
        }

        It 'Should support pipeline input for Id parameter' {
            $command = Get-Command Remove-AdoProject
            $nameParam = $command.Parameters['Name']
            $paramAttributes = $nameParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            $paramAttributes.ValueFromPipeline | Should -Contain $true
        }
    }

    Context 'ShouldProcess support' {
        BeforeAll {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id     = '00000000-0000-0000-0000-000000000001'
                    status = 'succeeded'
                    url    = $script:testOperationUrl
                }
            }
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Remove-AdoProject
            $command.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $command.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }

        It 'Should not call Invoke-AdoRestMethod when WhatIf is specified' {
            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectId -WhatIf

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should call Invoke-AdoRestMethod when Confirm is false' {
            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectId -Confirm:$false

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Method -eq 'DELETE'
            }
        }
    }

    Context 'Validation helpers' {
        BeforeAll {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id     = '00000000-0000-0000-0000-000000000001'
                    status = 'succeeded'
                    url    = $script:testOperationUrl
                }
            }
        }

        It 'Should call Confirm-CollectionUri to validate collection URI' {
            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectId -Confirm:$false

            Should -Invoke Confirm-CollectionUri -ModuleName $moduleName -Exactly 1
        }

        It 'Should call Confirm-Default with CollectionUri' {
            Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectId -Confirm:$false

            Should -Invoke Confirm-Default -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id     = '00000000-0000-0000-0000-000000000001'
                    status = 'succeeded'
                    url    = $script:testOperationUrl
                }
            }
        }

        It 'Should not return output on successful deletion' {
            $result = Remove-AdoProject -CollectionUri $script:testCollectionUri -Id $script:testProjectId -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Integration scenarios' {
        BeforeAll {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }
            Mock Confirm-Default -ModuleName $moduleName -MockWith { }
            Mock Start-Sleep -ModuleName $moduleName -MockWith { }

            $script:projectCallCount = 0
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                $script:projectCallCount++
                return @{ id = "project-id-$script:projectCallCount" }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                return @{
                    id     = '00000000-0000-0000-0000-000000000001'
                    status = 'succeeded'
                    url    = $script:testOperationUrl
                }
            }
        }

        It 'Should handle mixed GUID and name inputs from pipeline' {
            $script:projectCallCount = 0
            $mixedInput = @(
                '00000000-0000-0000-0000-000000000002',
                'ProjectName1',
                '00000000-0000-0000-0000-000000000001',
                'ProjectName2'
            )

            $mixedInput | Remove-AdoProject -CollectionUri $script:testCollectionUri -Confirm:$false

            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 4 -ParameterFilter {
                $Method -eq 'DELETE'
            }
        }

        It 'Should use environment variable for CollectionUri when not specified' {
            Mock Confirm-CollectionUri -ModuleName $moduleName -MockWith { $true }

            $env:DefaultAdoCollectionUri = $script:testCollectionUri
            Remove-AdoProject -Id $script:testProjectId -Confirm:$false
            $env:DefaultAdoCollectionUri = $null

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -match $script:testCollectionUri
            }
        }
    }
}
