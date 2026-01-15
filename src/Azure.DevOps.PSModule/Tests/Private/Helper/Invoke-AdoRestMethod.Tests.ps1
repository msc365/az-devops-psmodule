BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'Invoke-AdoRestMethod' -Tag 'Private' {
    Context 'Core Functionality Tests' {
        BeforeAll {
            $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
            $mockVersion = '7.0'
            $mockProfileUri = 'https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=6.0'
        }

        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
                Mock New-AdoAuthHeader { }
                Mock Invoke-RestMethod { return @{ value = @() } }

                $script:header = @{ Authorization = 'Basic faketoken' }
            }
        }

        It 'Should invoke REST method with correct URI and version' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'
                $expectedUri = "$mockUri`?api-version=$mockVersion"

                # Act
                Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method GET

                # Assert
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Uri -eq $expectedUri
                }
            }
        }

        It 'Should use correct HTTP method' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'

                # Act
                Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method POST -Body @{}

                # Assert
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Method -eq 'POST'
                }
            }
        }

        It 'Should include query parameters in URI' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'
                $queryParams = '$top=10&$skip=0'
                $expectedUri = "$mockUri`?$queryParams&api-version=$mockVersion"

                # Act
                Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method GET -QueryParameters $queryParams

                # Assert
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Uri -eq $expectedUri
                }
            }
        }

        It 'Should use authentication header from script scope' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'
                $script:header = @{ Authorization = 'Basic testtoken123' }

                # Act
                Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method GET

                # Assert
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Headers.Authorization -eq 'Basic testtoken123'
                }
            }
        }

        It 'Should convert body to JSON for POST requests' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'
                $mockBody = @{ name = 'TestProject'; description = 'Test Description' }

                # Act
                Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method POST -Body $mockBody

                # Assert
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Body -ne $null -and $Body -like '*TestProject*'
                }
            }
        }
    }

    Context 'Authentication Header Management' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
                Mock New-AdoAuthHeader {
                    $script:header = @{ Authorization = 'Basic newtoken' }
                }
                Mock Invoke-RestMethod { return @{ value = @() } }
            }
        }

        It 'Should create new auth header when header is null' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'
                $script:header = $null

                # Act
                Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method GET

                # Assert
                Should -Invoke New-AdoAuthHeader -Times 1
            }
        }

        It 'Should refresh Bearer token if profile check fails' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'
                $mockProfileUri = 'https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=6.0'
                $script:header = @{ Authorization = 'Bearer expiredtoken' }
                Mock Invoke-RestMethod {
                    if ($Uri -eq $mockProfileUri) {
                        throw 'Token expired'
                    }
                    return @{ value = @() }
                }

                # Act
                Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method GET

                # Assert
                Should -Invoke New-AdoAuthHeader -Times 1
            }
        }

        It 'Should validate Bearer token before making request' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'
                $mockProfileUri = 'https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=6.0'
                $script:header = @{ Authorization = 'Bearer validtoken' }
                Mock Invoke-RestMethod {
                    param($Uri)
                    if ($Uri -eq $mockProfileUri) {
                        return @{ id = 'test-user-id' }
                    }
                    return @{ value = @() }
                }

                # Act
                Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method GET

                # Assert
                Should -Invoke Invoke-RestMethod -Times 2
            }
        }
    }

    Context 'HTTP Method Handling' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
                Mock New-AdoAuthHeader { }
                Mock Invoke-RestMethod { return @{ value = @() } }

                $script:header = @{ Authorization = 'Basic faketoken' }
            }
        }

        It 'Should handle GET requests without body' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'

                # Act
                Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method GET

                # Assert
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Method -eq 'GET' -and $null -eq $Body
                }
            }
        }

        It 'Should handle PATCH requests with body' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'
                $mockBody = @{ name = 'Updated Name' }

                # Act
                Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method PATCH -Body $mockBody

                # Assert
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Method -eq 'PATCH' -and $Body -ne $null
                }
            }
        }

        It 'Should handle DELETE requests' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'

                # Act
                Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method DELETE

                # Assert
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Method -eq 'DELETE'
                }
            }
        }

        It 'Should handle PUT requests with body' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'
                $mockBody = @{ enabled = $true }

                # Act
                Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method PUT -Body $mockBody

                # Assert
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Method -eq 'PUT' -and $Body -ne $null
                }
            }
        }
    }

    Context 'Content Type Handling' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
                Mock New-AdoAuthHeader { }
                Mock Invoke-RestMethod { return @{ value = @() } }

                $script:header = @{ Authorization = 'Basic faketoken' }
            }
        }

        It 'Should use default content type application/json' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'

                # Act
                Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method GET

                # Assert
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $ContentType -eq 'application/json'
                }
            }
        }

        It 'Should use application/json-patch+json when specified' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'

                # Act
                Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method PATCH -ContentType 'application/json-patch+json'

                # Assert
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $ContentType -eq 'application/json-patch+json'
                }
            }
        }
    }

    Context 'Error Handling Tests' {
        BeforeEach {
            InModuleScope Azure.DevOps.PSModule {
                Mock Start-Sleep { }
                Mock New-AdoAuthHeader { }

                $script:header = @{ Authorization = 'Basic faketoken' }
            }
        }

        It 'Should propagate REST method errors' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'
                Mock Invoke-RestMethod {
                    throw 'REST API error: 404 Not Found'
                }

                # Act & Assert
                { Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method GET } | Should -Throw
            }
        }

        It 'Should handle authentication failure' {
            InModuleScope Azure.DevOps.PSModule {
                # Arrange
                $mockUri = 'https://dev.azure.com/myorg/_apis/projects'
                $mockVersion = '7.0'
                $script:header = $null
                Mock New-AdoAuthHeader {
                    throw 'Authentication failed'
                }

                # Act & Assert
                { Invoke-AdoRestMethod -Uri $mockUri -Version $mockVersion -Method GET } | Should -Throw
            }
        }
    }
}
