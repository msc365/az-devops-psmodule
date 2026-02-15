BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule\Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Get-AdoUserEntitlement' {

    BeforeAll {
        # Mock data
        $mockEntitlements = @{
            items             = @(
                @{
                    id          = '11111111-1111-1111-1111-111111111111'
                    accessLevel = @{ accountLicenseType = 'express' }
                    user        = @{ principalName = 'user1@contoso.com' }
                }
                @{
                    id          = '22222222-2222-2222-2222-222222222222'
                    accessLevel = @{ accountLicenseType = 'stakeholder' }
                    user        = @{ principalName = 'user2@contoso.com' }
                }
            )
            continuationToken = $null
        }

        $mockSingleEntitlement = @{
            id          = '11111111-1111-1111-1111-111111111111'
            accessLevel = @{ accountLicenseType = 'express' }
            user        = @{ principalName = 'user1@contoso.com' }
        }
    }

    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockEntitlements }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should retrieve all user entitlements when no UserId is provided' {
            $result = Get-AdoUserEntitlement -CollectionUri 'https://dev.azure.com/my-org'

            $result | Should -HaveCount 2
            $result[0].id | Should -Be '11111111-1111-1111-1111-111111111111'
            $result[1].id | Should -Be '22222222-2222-2222-2222-222222222222'
        }

        It 'Should retrieve a single user entitlement when UserId is provided' {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleEntitlement }

            $result = Get-AdoUserEntitlement -CollectionUri 'https://dev.azure.com/my-org' -UserId '11111111-1111-1111-1111-111111111111'

            $result | Should -HaveCount 1
            $result.id | Should -Be '11111111-1111-1111-1111-111111111111'
        }

        It 'Should output expected properties' {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleEntitlement }

            $result = Get-AdoUserEntitlement -CollectionUri 'https://dev.azure.com/my-org' -UserId '11111111-1111-1111-1111-111111111111'

            $result.accessLevel | Should -Not -BeNullOrEmpty
            $result.user.principalName | Should -Be 'user1@contoso.com'
        }

        It 'Should support pipeline input for UserId' {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleEntitlement }

            $result = '11111111-1111-1111-1111-111111111111' | Get-AdoUserEntitlement -CollectionUri 'https://dev.azure.com/my-org'

            $result.id | Should -Be '11111111-1111-1111-1111-111111111111'
        }
    }

    Context 'Query Parameter Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockEntitlements }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should include $top parameter when provided' {
            Get-AdoUserEntitlement -CollectionUri 'https://dev.azure.com/my-org' -Top 50

            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*$top=50*'
            }
        }

        It 'Should include $skip parameter when provided' {
            Get-AdoUserEntitlement -CollectionUri 'https://dev.azure.com/my-org' -Skip 10

            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*$skip=10*'
            }
        }

        It 'Should include filter parameter when provided' {
            Get-AdoUserEntitlement -CollectionUri 'https://dev.azure.com/my-org' -Filter 'extensionId eq search'

            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*$filter=extensionId eq search*'
            }
        }

        It 'Should include select parameter when provided' {
            Get-AdoUserEntitlement -CollectionUri 'https://dev.azure.com/my-org' -Select 'Projects,Extensions'

            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*$select=Projects,Extensions*'
            }
        }

    }

    Context 'Pagination Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should iterate over continuationToken returned by the API' {
            $firstPage = [PSCustomObject]@{
                items             = @(@{ id = '1' })
                continuationToken = 'next123'
            }
            $secondPage = [PSCustomObject]@{
                items             = @(@{ id = '2' })
                continuationToken = $null
            }
            $script:invokeCount = 0

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod {
                $script:invokeCount++
                if ($script:invokeCount -eq 1) {
                    return $firstPage
                }
                return $secondPage
            }

            $result = Get-AdoUserEntitlement -CollectionUri 'https://dev.azure.com/my-org'

            $result | Should -HaveCount 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 2
            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $QueryParameters -like '*continuationToken=next123*'
            }
        }
    }

    Context 'Input Validation Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockEntitlements }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should validate CollectionUri format' {
            { Get-AdoUserEntitlement -CollectionUri 'invalid-uri' } | Should -Throw
        }

        It 'Should use default CollectionUri when not provided' {
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/default-org'

            Get-AdoUserEntitlement

            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -like '*dev.azure.com/default-org*'
            }

            Remove-Item env:DefaultAdoCollectionUri -ErrorAction SilentlyContinue
        }

        It 'Should validate UserId format' {
            { Get-AdoUserEntitlement -UserId 'not-a-guid' } | Should -Throw
        }
    }

    Context 'API Interaction Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockEntitlements }
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should construct correct URI for listing entitlements' {
            Get-AdoUserEntitlement -CollectionUri 'https://dev.azure.com/my-org'

            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://vsaex.dev.azure.com/my-org/_apis/userentitlements'
            }
        }

        It 'Should construct correct URI for specific user entitlement' {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { return $mockSingleEntitlement }

            Get-AdoUserEntitlement -CollectionUri 'https://dev.azure.com/my-org' -UserId '11111111-1111-1111-1111-111111111111'

            Should -Invoke Invoke-AdoRestMethod -ModuleName Azure.DevOps.PSModule -Times 1 -ParameterFilter {
                $Uri -eq 'https://vsaex.dev.azure.com/my-org/_apis/userentitlements/11111111-1111-1111-1111-111111111111'
            }
        }

        It 'Should call Confirm-Default' {
            Get-AdoUserEntitlement -CollectionUri 'https://dev.azure.com/my-org'

            Should -Invoke Confirm-Default -ModuleName Azure.DevOps.PSModule -Times 1
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            Mock -ModuleName Azure.DevOps.PSModule Confirm-Default { }
        }

        It 'Should warn when user entitlement does not exist (UserEntitlementNotFoundException)' {
            $exception = New-Object System.Management.Automation.RuntimeException('UserEntitlementNotFoundException: User entitlement not found')
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, 'UserEntitlementNotFoundException', 'ObjectNotFound', $null)
            $errorRecord.ErrorDetails = New-Object System.Management.Automation.ErrorDetails('UserEntitlementNotFoundException: User entitlement not found')

            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw $errorRecord }

            { Get-AdoUserEntitlement -CollectionUri 'https://dev.azure.com/my-org' -UserId '11111111-1111-1111-1111-111111111111' -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should propagate non-MemberNotFound errors' {
            Mock -ModuleName Azure.DevOps.PSModule Invoke-AdoRestMethod { throw 'API Error: Unauthorized' }

            { Get-AdoUserEntitlement -CollectionUri 'https://dev.azure.com/my-org' } | Should -Throw '*API Error: Unauthorized*'
        }
    }
}
