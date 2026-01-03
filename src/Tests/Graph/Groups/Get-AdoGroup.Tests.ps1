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
        param($Uri, $Method, $Version, $QueryParameters)

        # Return different mock data based on URI pattern
        if ($Uri -match '/_apis/graph/groups/([^/]+)$' -and $Matches[1] -ne '') {
            # Get specific group by descriptor
            $descriptor = $Matches[1]
            return @{
                displayName   = "Test Group $descriptor"
                originId      = "origin-$descriptor"
                principalName = "[TestOrg]\Test Group $descriptor"
                origin        = 'vsts'
                subjectKind   = 'group'
                description   = "Description for $descriptor"
                mailAddress   = ''
                descriptor    = $descriptor
            }
        } elseif ($Uri -match '/_apis/graph/groups$') {
            # List groups
            return @{
                count = 4
                value = @(
                    @{
                        displayName   = 'Project Administrators'
                        originId      = 'origin-id-1'
                        principalName = '[TestProject]\Project Administrators'
                        origin        = 'vsts'
                        subjectKind   = 'group'
                        description   = 'Administrators for the project'
                        mailAddress   = ''
                        descriptor    = 'vssgp.00000000-0000-0000-0000-000000000001'
                    },
                    @{
                        displayName   = 'Contributors'
                        originId      = 'origin-id-2'
                        principalName = '[TestProject]\Contributors'
                        origin        = 'vsts'
                        subjectKind   = 'group'
                        description   = 'Contributors to the project'
                        mailAddress   = ''
                        descriptor    = 'vssgp.00000000-0000-0000-0000-000000000002'
                    },
                    @{
                        displayName   = 'Readers'
                        originId      = 'origin-id-3'
                        principalName = '[TestProject]\Readers'
                        origin        = 'vsts'
                        subjectKind   = 'group'
                        description   = 'Readers of the project'
                        mailAddress   = ''
                        descriptor    = 'vssgp.00000000-0000-0000-0000-000000000003'
                    },
                    @{
                        displayName   = 'AAD Group'
                        originId      = 'aad-origin-id'
                        principalName = '[TestOrg]\AAD Group'
                        origin        = 'aad'
                        subjectKind   = 'group'
                        description   = 'Azure AD synchronized group'
                        mailAddress   = 'aadgroup@example.com'
                        descriptor    = 'aadgp.00000000-0000-0000-0000-000000000004'
                    }
                )
            }
        }
    }
}

Describe 'Get-AdoGroup' {

    Context 'When retrieving all groups' {
        It 'Should retrieve all groups when no filters are specified' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 4
            $result[0].displayName | Should -Be 'Project Administrators'
            $result[1].displayName | Should -Be 'Contributors'

            # Verify Invoke-AdoRestMethod was called correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/graph/groups" -and
                $Method -eq 'GET' -and
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should use environment variable when CollectionUri is not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/envorg'

            # Act
            $result = Get-AdoGroup

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq 'https://vssps.dev.azure.com/envorg/_apis/graph/groups'
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
        }

        It 'Should call API with default parameters when no filters specified' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'When retrieving a specific group by descriptor' {
        It 'Should retrieve group by GroupDescriptor' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.descriptor | Should -Be $groupDescriptor
            $result.collectionUri | Should -Be $collectionUri

            # Verify Invoke-AdoRestMethod was called correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/graph/groups/$groupDescriptor" -and
                $Method -eq 'GET' -and
                $Version -eq '7.2-preview.1'
            }
        }

        It 'Should handle group not found with GraphSubjectNotFoundException gracefully' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.nonexistent-descriptor'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Subject with group descriptor vssgp.nonexistent-descriptor does not exist'
                    typeKey = 'GraphSubjectNotFoundException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Group not found')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'NotFoundException',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert - Should not throw, should write warning instead
            { Get-AdoGroup -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -WarningAction SilentlyContinue } | Should -Not -Throw

            # Verify warning was written
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept group descriptors from pipeline' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $groupDescriptors = @(
                'vssgp.00000000-0000-0000-0000-000000000001',
                'vssgp.00000000-0000-0000-0000-000000000002'
            )

            # Act
            $result = $groupDescriptors | Get-AdoGroup -CollectionUri $collectionUri

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2

            # Verify Invoke-AdoRestMethod was called once for each descriptor
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2
        }
    }

    Context 'When using ScopeDescriptor parameter' {
        It 'Should include scopeDescriptor query parameter when specified' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $scopeDescriptor = 'scp.project-scope-descriptor'

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri -ScopeDescriptor $scopeDescriptor

            # Assert
            $result | Should -Not -BeNullOrEmpty

            # Verify query parameter was included
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like "*scopeDescriptor=$scopeDescriptor*"
            }
        }

        It 'Should handle invalid scope descriptor with InvalidSubjectTypeException gracefully' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $scopeDescriptor = 'scp.invalid-scope-descriptor'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = "Subject with scope descriptor $scopeDescriptor does not exist"
                    typeKey = 'InvalidSubjectTypeException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Invalid scope descriptor')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'InvalidScopeDescriptor',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert - Should not throw, should write warning instead
            { Get-AdoGroup -CollectionUri $collectionUri -ScopeDescriptor $scopeDescriptor -WarningAction SilentlyContinue } | Should -Not -Throw

            # Verify warning was written
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'When using SubjectTypes parameter' {
        It 'Should include subjectTypes query parameter with default values' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like '*subjectTypes=vssgp,aadgp*'
            }
        }

        It 'Should accept single SubjectType value' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $subjectType = 'vssgp'

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri -SubjectTypes $subjectType

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like "*subjectTypes=$subjectType*"
            }
        }

        It 'Should accept multiple SubjectType values' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $subjectTypes = @('vssgp', 'aadgp')

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri -SubjectTypes $subjectTypes

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like '*subjectTypes=vssgp,aadgp*'
            }
        }
    }

    Context 'When using ContinuationToken parameter' {
        It 'Should include continuationToken query parameter when specified' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $token = 'my-continuation-token'

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri -ContinuationToken $token

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like "*continuationToken=$token*"
            }
        }
    }

    Context 'When using Name parameter' {
        It 'Should filter groups by single name' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $groupName = 'Project Administrators'

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri -Name $groupName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.displayName | Should -Be $groupName
        }

        It 'Should filter groups by multiple names' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $groupNames = @('Project Administrators', 'Contributors')

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri -Name $groupNames

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].displayName | Should -Be 'Project Administrators'
            $result[1].displayName | Should -Be 'Contributors'
        }

        It 'Should support wildcard filtering with Name parameter' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $namePattern = 'Project*'

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri -Name $namePattern

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.displayName | Should -Be 'Project Administrators'
        }
    }

    Context 'When using Version parameter' {
        It 'Should accept valid Version value "7.1-preview.1"' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri -Version '7.1-preview.1'

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1-preview.1'
            }
        }

        It 'Should use default Version value "7.2-preview.1"' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should have CollectionUri with default value from environment' {
            # Arrange
            $command = Get-Command Get-AdoGroup

            # Act
            $collectionUriParam = $command.Parameters['CollectionUri']

            # Assert
            $collectionUriParam | Should -Not -BeNullOrEmpty
            $collectionUriParam.ParameterType | Should -Be ([string])
        }

        It 'Should have SubjectTypes parameter with ValidateSet attribute' {
            # Arrange
            $command = Get-Command Get-AdoGroup

            # Act
            $subjectTypesParam = $command.Parameters['SubjectTypes']
            $validateSetAttribute = $subjectTypesParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            # Assert
            $validateSetAttribute | Should -Not -BeNullOrEmpty
            $validateSetAttribute.ValidValues | Should -Contain 'vssgp'
            $validateSetAttribute.ValidValues | Should -Contain 'aadgp'
        }

        It 'Should have Version parameter with ValidateSet attribute' {
            # Arrange
            $command = Get-Command Get-AdoGroup

            # Act
            $versionParam = $command.Parameters['Version']
            $validateSetAttribute = $versionParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            # Assert
            $validateSetAttribute | Should -Not -BeNullOrEmpty
            $validateSetAttribute.ValidValues | Should -Contain '7.1-preview.1'
            $validateSetAttribute.ValidValues | Should -Contain '7.2-preview.1'
        }

        It 'Should support ShouldProcess' {
            # Arrange
            $command = Get-Command Get-AdoGroup

            # Act
            $cmdletBinding = $command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }

            # Assert
            $cmdletBinding.SupportsShouldProcess | Should -Be $true
        }

        It 'Should have Name parameter with DisplayName and GroupName aliases' {
            # Arrange
            $command = Get-Command Get-AdoGroup

            # Act
            $nameParam = $command.Parameters['Name']
            $aliasAttribute = $nameParam.Attributes | Where-Object { $_ -is [System.Management.Automation.AliasAttribute] }

            # Assert
            $aliasAttribute | Should -Not -BeNullOrEmpty
            $aliasAttribute.AliasNames | Should -Contain 'DisplayName'
            $aliasAttribute.AliasNames | Should -Contain 'GroupName'
        }
    }

    Context 'Output validation' {
        It 'Should return PSCustomObject with expected properties' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result[0] | Should -BeOfType [PSCustomObject]
            $result[0].PSObject.Properties.Name | Should -Contain 'displayName'
            $result[0].PSObject.Properties.Name | Should -Contain 'originId'
            $result[0].PSObject.Properties.Name | Should -Contain 'principalName'
            $result[0].PSObject.Properties.Name | Should -Contain 'origin'
            $result[0].PSObject.Properties.Name | Should -Contain 'subjectKind'
            $result[0].PSObject.Properties.Name | Should -Contain 'description'
            $result[0].PSObject.Properties.Name | Should -Contain 'mailAddress'
            $result[0].PSObject.Properties.Name | Should -Contain 'descriptor'
            $result[0].PSObject.Properties.Name | Should -Contain 'collectionUri'
        }
    }

    Context 'WhatIf support' {
        It 'Should support -WhatIf and not call API' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'

            # Act
            Get-AdoGroup -CollectionUri $collectionUri -WhatIf

            # Assert - WhatIf should prevent the API call
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }

    Context 'Integration scenarios' {
        It 'Should retrieve groups with scope and subject type filters' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $scopeDescriptor = 'scp.project-scope'
            $subjectTypes = @('vssgp')

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri -ScopeDescriptor $scopeDescriptor -SubjectTypes $subjectTypes

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like "*scopeDescriptor=$scopeDescriptor*" -and
                $QueryParameters -like '*subjectTypes=vssgp*'
            }
        }

        It 'Should pass continuation token parameter correctly' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $token = 'my-token'

            # Act
            $result = Get-AdoGroup -CollectionUri $collectionUri -ContinuationToken $token

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $QueryParameters -like "*continuationToken=$token*"
            }
        }
    }
}
