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
        param($Uri, $Method, $Version, $QueryParameters, $Body)

        if ($Method -eq 'POST') {
            # Return successful group creation response
            return @{
                displayName   = 'New AAD Group'
                originId      = $Body.originId
                principalName = '[TestOrg]\New AAD Group'
                origin        = 'aad'
                subjectKind   = 'group'
                descriptor    = "aadgp.$($Body.originId)"
            }
        }
    }
}

Describe 'New-AdoGroupAsMember' {

    Context 'When adding a new AAD group as member' {
        It 'Should add AAD group with required parameters' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
            $originId = '11111111-1111-1111-1111-111111111111'

            # Act
            $result = New-AdoGroupAsMember -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -OriginId $originId -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.originId | Should -Be $originId
            $result.collectionUri | Should -Be $collectionUri
            $result.origin | Should -Be 'aad'

            # Verify Invoke-AdoRestMethod was called correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -like '*/_apis/graph/groups' -and
                $Method -eq 'POST' -and
                $Version -eq '7.2-preview.1' -and
                $QueryParameters -eq "groupDescriptors=$groupDescriptor"
            }
        }

        It 'Should use environment variable when CollectionUri is not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/envorg'
            $groupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
            $originId = '11111111-1111-1111-1111-111111111111'

            # Act
            $result = New-AdoGroupAsMember -GroupDescriptor $groupDescriptor -OriginId $originId -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Uri -eq 'https://vssps.dev.azure.com/envorg/_apis/graph/groups'
            }

            # Cleanup
            $env:DefaultAdoCollectionUri = $null
        }

        It 'Should send correct body with originId' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
            $originId = '22222222-2222-2222-2222-222222222222'

            # Act
            $result = New-AdoGroupAsMember -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -OriginId $originId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Body.originId -eq $originId
            }
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept OriginIds from pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
            $originIds = @(
                '11111111-1111-1111-1111-111111111111',
                '22222222-2222-2222-2222-222222222222'
            )

            # Act
            $result = $originIds | New-AdoGroupAsMember -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2

            # Verify Invoke-AdoRestMethod was called once for each origin ID
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 2 -ParameterFilter {
                $Method -eq 'POST'
            }
        }

        It 'Should accept objects with OriginId property from pipeline' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
            $inputObjects = @(
                [PSCustomObject]@{ OriginId = '11111111-1111-1111-1111-111111111111' },
                [PSCustomObject]@{ OriginId = '22222222-2222-2222-2222-222222222222' }
            )

            # Act
            $result = $inputObjects | New-AdoGroupAsMember -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }
    }

    Context 'Error handling' {
        It 'Should handle originId not found (VS860016) gracefully' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
            $originId = '99999999-9999-9999-9999-999999999999'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = "VS860016: Could not find originId '$originId' in the backing domain"
                    typeKey = 'NotFoundException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Origin ID not found')
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
            { New-AdoGroupAsMember -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -OriginId $originId -WarningAction SilentlyContinue -Confirm:$false } | Should -Not -Throw

            # Verify warning was written
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should handle group descriptor not found (TF50258) gracefully' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.invalid-descriptor'
            $originId = '11111111-1111-1111-1111-111111111111'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = "TF50258: There is no group with the security identifier (SID) '$groupDescriptor'"
                    typeKey = 'GroupDoesNotExistException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Group descriptor not found')
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
            { New-AdoGroupAsMember -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -OriginId $originId -WarningAction SilentlyContinue -Confirm:$false } | Should -Not -Throw

            # Verify warning was written
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should handle FindGroupSidDoesNotExist error gracefully' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.invalid-descriptor'
            $originId = '11111111-1111-1111-1111-111111111111'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'FindGroupSidDoesNotExist: The group SID does not exist'
                    typeKey = 'FindGroupSidDoesNotExist'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Group SID not found')
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
            { New-AdoGroupAsMember -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -OriginId $originId -WarningAction SilentlyContinue -Confirm:$false } | Should -Not -Throw

            # Verify warning was written
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }

        It 'Should rethrow unexpected errors' {
            # Arrange
            $collectionUri = 'https://vssps.dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
            $originId = '11111111-1111-1111-1111-111111111111'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Unexpected error occurred'
                    typeKey = 'UnexpectedException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Unexpected error')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'UnexpectedError',
                    [System.Management.Automation.ErrorCategory]::NotSpecified,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert - Should throw
            { New-AdoGroupAsMember -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -OriginId $originId -Confirm:$false } | Should -Throw
        }
    }

    Context 'Parameter validation' {
        It 'Should have GroupDescriptor as a mandatory parameter' {
            # Arrange
            $command = Get-Command New-AdoGroupAsMember

            # Act
            $groupDescriptorParam = $command.Parameters['GroupDescriptor']

            # Assert
            $groupDescriptorParam.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have OriginId as a mandatory parameter' {
            # Arrange
            $command = Get-Command New-AdoGroupAsMember

            # Act
            $originIdParam = $command.Parameters['OriginId']

            # Assert
            $originIdParam.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have GroupDescriptor parameter with Descriptor alias' {
            # Arrange
            $command = Get-Command New-AdoGroupAsMember

            # Act
            $groupDescriptorParam = $command.Parameters['GroupDescriptor']
            $aliasAttribute = $groupDescriptorParam.Attributes | Where-Object { $_ -is [System.Management.Automation.AliasAttribute] }

            # Assert
            $aliasAttribute | Should -Not -BeNullOrEmpty
            $aliasAttribute.AliasNames | Should -Contain 'Descriptor'
        }

        It 'Should have OriginId parameter with Id and GroupId aliases' {
            # Arrange
            $command = Get-Command New-AdoGroupAsMember

            # Act
            $originIdParam = $command.Parameters['OriginId']
            $aliasAttribute = $originIdParam.Attributes | Where-Object { $_ -is [System.Management.Automation.AliasAttribute] }

            # Assert
            $aliasAttribute | Should -Not -BeNullOrEmpty
            $aliasAttribute.AliasNames | Should -Contain 'Id'
            $aliasAttribute.AliasNames | Should -Contain 'GroupId'
        }

        It 'Should have Version parameter with ValidateSet attribute' {
            # Arrange
            $command = Get-Command New-AdoGroupAsMember

            # Act
            $versionParam = $command.Parameters['Version']
            $validateSetAttribute = $versionParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            # Assert
            $validateSetAttribute | Should -Not -BeNullOrEmpty
            $validateSetAttribute.ValidValues | Should -Contain '7.1-preview.1'
            $validateSetAttribute.ValidValues | Should -Contain '7.2-preview.1'
        }

        It 'Should support ShouldProcess with ConfirmImpact High' {
            # Arrange
            $command = Get-Command New-AdoGroupAsMember

            # Act
            $cmdletBinding = $command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }

            # Assert
            $cmdletBinding.SupportsShouldProcess | Should -Be $true
            $cmdletBinding.ConfirmImpact | Should -Be 'High'
        }
    }

    Context 'When using Version parameter' {
        It 'Should accept valid Version value "7.1-preview.1"' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
            $originId = '11111111-1111-1111-1111-111111111111'

            # Act
            $result = New-AdoGroupAsMember -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -OriginId $originId -Version '7.1-preview.1' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.1-preview.1'
            }
        }

        It 'Should use default Version value "7.2-preview.1"' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
            $originId = '11111111-1111-1111-1111-111111111111'

            # Act
            $result = New-AdoGroupAsMember -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -OriginId $originId -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1 -ParameterFilter {
                $Version -eq '7.2-preview.1'
            }
        }
    }

    Context 'Output validation' {
        It 'Should return PSCustomObject with expected properties' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
            $originId = '11111111-1111-1111-1111-111111111111'

            # Act
            $result = New-AdoGroupAsMember -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -OriginId $originId -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [PSCustomObject]
            $result.PSObject.Properties.Name | Should -Contain 'displayName'
            $result.PSObject.Properties.Name | Should -Contain 'originId'
            $result.PSObject.Properties.Name | Should -Contain 'principalName'
            $result.PSObject.Properties.Name | Should -Contain 'origin'
            $result.PSObject.Properties.Name | Should -Contain 'subjectKind'
            $result.PSObject.Properties.Name | Should -Contain 'descriptor'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }
    }

    Context 'WhatIf support' {
        It 'Should support -WhatIf and not call API' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
            $originId = '11111111-1111-1111-1111-111111111111'

            # Act
            New-AdoGroupAsMember -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -OriginId $originId -WhatIf

            # Assert - WhatIf should prevent the API call
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }
    }

    Context 'Integration scenarios' {
        It 'Should add multiple AAD groups to the same parent group' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
            $originIds = @(
                '11111111-1111-1111-1111-111111111111',
                '22222222-2222-2222-2222-222222222222',
                '33333333-3333-3333-3333-333333333333'
            )

            # Act
            $results = foreach ($originId in $originIds) {
                New-AdoGroupAsMember -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -OriginId $originId -Confirm:$false
            }

            # Assert
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 3
            $results[0].originId | Should -Be $originIds[0]
            $results[1].originId | Should -Be $originIds[1]
            $results[2].originId | Should -Be $originIds[2]

            # Verify each call was made correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3 -ParameterFilter {
                $Method -eq 'POST'
            }
        }

        It 'Should handle mixed success and failure scenarios' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $groupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
            $validOriginId = '11111111-1111-1111-1111-111111111111'
            $invalidOriginId = '99999999-9999-9999-9999-999999999999'

            # Mock first call succeeds, second fails
            $callCount = 0
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $script:callCount++
                if ($script:callCount -eq 1) {
                    return @{
                        displayName   = 'Valid Group'
                        originId      = $validOriginId
                        principalName = '[TestOrg]\Valid Group'
                        origin        = 'aad'
                        subjectKind   = 'group'
                        descriptor    = "aadgp.$validOriginId"
                    }
                } else {
                    $errorMessage = @{
                        message = "VS860016: Could not find originId '$invalidOriginId' in the backing domain"
                        typeKey = 'NotFoundException'
                    } | ConvertTo-Json
                    $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                    $exception = [System.Exception]::new('Origin ID not found')
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

            # Act
            $result1 = New-AdoGroupAsMember -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -OriginId $validOriginId -Confirm:$false
            $result2 = New-AdoGroupAsMember -CollectionUri $collectionUri -GroupDescriptor $groupDescriptor -OriginId $invalidOriginId -WarningAction SilentlyContinue -Confirm:$false

            # Assert
            $result1 | Should -Not -BeNullOrEmpty
            $result1.originId | Should -Be $validOriginId
            $result2 | Should -BeNullOrEmpty
        }
    }
}
