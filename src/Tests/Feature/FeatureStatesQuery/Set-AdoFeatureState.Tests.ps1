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

Describe 'Set-AdoFeatureState' {

    Context 'When setting individual feature states' {
        BeforeAll {
            # Mock Get-AdoProject for project name resolution
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                param($CollectionUri, $Name)

                return @{
                    id   = 'test-project-id-123'
                    name = $Name
                }
            }

            # Mock Invoke-AdoRestMethod for successful feature state updates
            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Uri, $Method, $Version, $Body)

                $bodyObj = $Body | ConvertFrom-Json
                return @{
                    featureId = $bodyObj.featureId
                    state     = $bodyObj.state
                    scope     = $bodyObj.scope
                }
            }
        }

        It 'Should set feature state to <FeatureState> for <Feature>' -ForEach @(
            @{ Feature = 'boards'; FeatureState = 'enabled'; ExpectedState = 1; FeatureId = 'ms.vss-work.agile' }
            @{ Feature = 'boards'; FeatureState = 'disabled'; ExpectedState = 0; FeatureId = 'ms.vss-work.agile' }
            @{ Feature = 'repos'; FeatureState = 'enabled'; ExpectedState = 1; FeatureId = 'ms.vss-code.version-control' }
            @{ Feature = 'repos'; FeatureState = 'disabled'; ExpectedState = 0; FeatureId = 'ms.vss-code.version-control' }
            @{ Feature = 'pipelines'; FeatureState = 'enabled'; ExpectedState = 1; FeatureId = 'ms.vss-build.pipelines' }
            @{ Feature = 'pipelines'; FeatureState = 'disabled'; ExpectedState = 0; FeatureId = 'ms.vss-build.pipelines' }
            @{ Feature = 'testPlans'; FeatureState = 'enabled'; ExpectedState = 1; FeatureId = 'ms.vss-test-web.test' }
            @{ Feature = 'testPlans'; FeatureState = 'disabled'; ExpectedState = 0; FeatureId = 'ms.vss-test-web.test' }
            @{ Feature = 'artifacts'; FeatureState = 'enabled'; ExpectedState = 1; FeatureId = 'ms.azure-artifacts.feature' }
            @{ Feature = 'artifacts'; FeatureState = 'disabled'; ExpectedState = 0; FeatureId = 'ms.azure-artifacts.feature' }
        ) {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'

            # Act
            $result = Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature $Feature -FeatureState $FeatureState -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.featureId | Should -Be $FeatureId
            $result.state | Should -Be $FeatureState
            $result.feature | Should -Be $Feature
            $result.projectName | Should -Be $projectName
            $result.projectId | Should -Be 'test-project-id-123'
            $result.collectionUri | Should -Be $collectionUri

            # Verify Get-AdoProject was called for name resolution
            Should -Invoke Get-AdoProject -ModuleName $moduleName -ParameterFilter {
                $Name -eq $projectName
            }

            # Verify Invoke-AdoRestMethod was called correctly
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -ParameterFilter {
                $Uri -eq "$collectionUri/_apis/FeatureManagement/FeatureStates/host/project/test-project-id-123/$FeatureId" -and
                $Method -eq 'PATCH' -and
                $Version -eq '4.1-preview.1' -and
                ($Body | ConvertFrom-Json).state -eq $ExpectedState -and
                ($Body | ConvertFrom-Json).featureId -eq $FeatureId
            }
        }

        It 'Should use project ID directly when GUID is provided' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectId = '12345678-1234-1234-1234-123456789abc'
            $feature = 'boards'
            $featureState = 'enabled'

            # Act
            $result = Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectId -Feature $feature -FeatureState $featureState -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.projectId | Should -Be $projectId

            # Verify Get-AdoProject was NOT called (GUID doesn't need resolution)
            Should -Invoke Get-AdoProject -ModuleName $moduleName -Exactly 0

            # Verify Invoke-AdoRestMethod was called with the GUID
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -ParameterFilter {
                $Uri -like "*$projectId*"
            }
        }

        It 'Should include correct scope in request body' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'
            $feature = 'boards'
            $featureState = 'enabled'

            # Act
            Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature $feature -FeatureState $featureState -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -ParameterFilter {
                $bodyObj = $Body | ConvertFrom-Json
                $bodyObj.scope.settingScope -eq 'project' -and
                $bodyObj.scope.userScoped -eq $false
            }
        }

        It 'Should default to disabled when FeatureState is not specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'
            $feature = 'boards'

            # Act
            $result = Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature $feature -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.state | Should -Be 'disabled'

            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -ParameterFilter {
                ($Body | ConvertFrom-Json).state -eq 0
            }
        }
    }

    Context 'When using environment variable defaults' {
        BeforeAll {
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return @{
                    id   = 'env-project-id'
                    name = 'EnvProject'
                }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                $bodyObj = $Body | ConvertFrom-Json
                return @{
                    featureId = $bodyObj.featureId
                    state     = $bodyObj.state
                }
            }
        }

        It 'Should use environment variable for CollectionUri when not specified' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/envorg'
            $env:DefaultAdoProject = 'EnvProject'
            $feature = 'boards'

            try {
                # Act
                $result = Set-AdoFeatureState -Feature $feature -FeatureState 'enabled' -Confirm:$false

                # Assert
                $result | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -ParameterFilter {
                    $Uri -like 'https://dev.azure.com/envorg/_apis/FeatureManagement/*'
                }
            } finally {
                # Cleanup
                $env:DefaultAdoCollectionUri = $null
                $env:DefaultAdoProject = $null
            }
        }

        It 'Should use environment variable for ProjectName when not specified' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/testorg'
            $env:DefaultAdoProject = 'EnvProject'
            $feature = 'repos'

            try {
                # Act
                $result = Set-AdoFeatureState -Feature $feature -FeatureState 'disabled' -Confirm:$false

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.projectName | Should -Be 'EnvProject'

                Should -Invoke Get-AdoProject -ModuleName $moduleName -ParameterFilter {
                    $Name -eq 'EnvProject'
                }
            } finally {
                # Cleanup
                $env:DefaultAdoCollectionUri = $null
                $env:DefaultAdoProject = $null
            }
        }
    }

    Context 'When using custom API version' {
        BeforeAll {
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return @{ id = 'test-project-id' }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                $bodyObj = $Body | ConvertFrom-Json
                return @{
                    featureId = $bodyObj.featureId
                    state     = $bodyObj.state
                }
            }
        }

        It 'Should use specified API version' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'
            $version = '4.1-preview.1'

            # Act
            Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature 'boards' -FeatureState 'enabled' -Version $version -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -ParameterFilter {
                $Version -eq $version
            }
        }

        It 'Should use default API version when not specified' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'

            # Act
            Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature 'boards' -FeatureState 'enabled' -Confirm:$false

            # Assert
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -ParameterFilter {
                $Version -eq '4.1-preview.1'
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should have Feature as a mandatory parameter' {
            # Arrange
            $command = Get-Command Set-AdoFeatureState

            # Act
            $featureParam = $command.Parameters['Feature']

            # Assert
            $featureParam.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have ProjectName parameter with alias ProjectId' {
            # Arrange
            $command = Get-Command Set-AdoFeatureState

            # Act
            $projectNameParam = $command.Parameters['ProjectName']

            # Assert
            $projectNameParam.Aliases | Should -Contain 'ProjectId'
        }

        It 'Should have Version parameter with alias ApiVersion' {
            # Arrange
            $command = Get-Command Set-AdoFeatureState

            # Act
            $versionParam = $command.Parameters['Version']

            # Assert
            $versionParam.Aliases | Should -Contain 'ApiVersion'
        }

        It 'Should have ValidateSet constraint on Feature parameter' {
            # Arrange
            $command = Get-Command Set-AdoFeatureState
            $featureParam = $command.Parameters['Feature']

            # Act
            $validateSet = $featureParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'boards'
            $validateSet.ValidValues | Should -Contain 'repos'
            $validateSet.ValidValues | Should -Contain 'pipelines'
            $validateSet.ValidValues | Should -Contain 'testPlans'
            $validateSet.ValidValues | Should -Contain 'artifacts'
        }

        It 'Should have ValidateSet constraint on FeatureState parameter' {
            # Arrange
            $command = Get-Command Set-AdoFeatureState
            $featureStateParam = $command.Parameters['FeatureState']

            # Act
            $validateSet = $featureStateParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'enabled'
            $validateSet.ValidValues | Should -Contain 'disabled'
        }

        It 'Should have ValidateSet constraint on Version parameter' {
            # Arrange
            $command = Get-Command Set-AdoFeatureState
            $versionParam = $command.Parameters['Version']

            # Act
            $validateSet = $versionParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            # Assert
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain '4.1-preview.1'
        }

        It 'Should accept CollectionUri from pipeline by property name' {
            # Arrange
            $command = Get-Command Set-AdoFeatureState
            $collectionUriParam = $command.Parameters['CollectionUri']

            # Act
            $pipelineAttribute = $collectionUriParam.Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ValueFromPipelineByPropertyName
            }

            # Assert
            $pipelineAttribute | Should -Not -BeNullOrEmpty
        }

        It 'Should accept ProjectName from pipeline by property name' {
            # Arrange
            $command = Get-Command Set-AdoFeatureState
            $projectNameParam = $command.Parameters['ProjectName']

            # Act
            $pipelineAttribute = $projectNameParam.Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ValueFromPipelineByPropertyName
            }

            # Assert
            $pipelineAttribute | Should -Not -BeNullOrEmpty
        }

        It 'Should accept Feature from pipeline by property name' {
            # Arrange
            $command = Get-Command Set-AdoFeatureState
            $featureParam = $command.Parameters['Feature']

            # Act
            $pipelineAttribute = $featureParam.Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ValueFromPipelineByPropertyName
            }

            # Assert
            $pipelineAttribute | Should -Not -BeNullOrEmpty
        }

        It 'Should accept FeatureState from pipeline by property name' {
            # Arrange
            $command = Get-Command Set-AdoFeatureState
            $featureStateParam = $command.Parameters['FeatureState']

            # Act
            $pipelineAttribute = $featureStateParam.Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ValueFromPipelineByPropertyName
            }

            # Assert
            $pipelineAttribute | Should -Not -BeNullOrEmpty
        }

        It 'Should support ShouldProcess' {
            # Arrange
            $command = Get-Command Set-AdoFeatureState

            # Act
            $supportsShouldProcess = $command.Parameters.ContainsKey('WhatIf') -and $command.Parameters.ContainsKey('Confirm')

            # Assert
            $supportsShouldProcess | Should -Be $true
        }

        It 'Should have PSCustomObject as output type' {
            # Arrange
            $command = Get-Command Set-AdoFeatureState

            # Act
            $outputType = ($command.OutputType | Select-Object -First 1).Type.Name

            # Assert
            $outputType | Should -Be 'PSObject'
        }
    }

    Context 'Error handling' {
        BeforeAll {
            # Mock Get-AdoProject to return nothing (project not found)
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return $null
            }
        }

        It 'Should return early when project is not found' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'NonExistentProject'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                throw 'Should not be called'
            }

            # Act
            $result = Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature 'boards' -FeatureState 'enabled' -Confirm:$false

            # Assert
            $result | Should -BeNullOrEmpty

            # Verify Invoke-AdoRestMethod was not called
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should throw when REST API call fails' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectId = '12345678-1234-1234-1234-123456789abc'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Access denied: User does not have permissions'
                    typeKey = 'UnauthorizedException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Unauthorized')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'Unauthorized',
                    [System.Management.Automation.ErrorCategory]::PermissionDenied,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert
            { Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectId -Feature 'boards' -FeatureState 'enabled' -Confirm:$false -ErrorAction Stop } |
                Should -Throw
        }

        It 'Should throw when project ID parsing fails and Get-AdoProject throws' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'FailProject'

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                throw 'Project not found'
            }

            # Act & Assert
            { Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature 'boards' -FeatureState 'enabled' -Confirm:$false -ErrorAction Stop } |
                Should -Throw 'Project not found'
        }

        It 'Should throw when feature state update fails with invalid feature' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectId = '12345678-1234-1234-1234-123456789abc'

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                $errorMessage = @{
                    message = 'Invalid feature ID specified'
                    typeKey = 'InvalidFeatureIdException'
                } | ConvertTo-Json
                $errorDetails = [System.Management.Automation.ErrorDetails]::new($errorMessage)
                $exception = [System.Exception]::new('Invalid feature')
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'InvalidFeature',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $null
                )
                $errorRecord.ErrorDetails = $errorDetails
                throw $errorRecord
            }

            # Act & Assert
            { Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectId -Feature 'boards' -FeatureState 'enabled' -Confirm:$false -ErrorAction Stop } |
                Should -Throw
        }
    }

    Context 'WhatIf and Confirm support' {
        BeforeAll {
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return @{
                    id   = 'test-project-id'
                    name = 'TestProject'
                }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                $bodyObj = $Body | ConvertFrom-Json
                return @{
                    featureId = $bodyObj.featureId
                    state     = $bodyObj.state
                }
            }
        }

        It 'Should support WhatIf parameter' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'

            # Act
            $result = Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature 'boards' -FeatureState 'enabled' -WhatIf

            # Assert
            $result | Should -BeNullOrEmpty

            # Verify Invoke-AdoRestMethod was not called
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 0
        }

        It 'Should support Confirm parameter bypass' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'

            # Act
            $result = Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature 'boards' -FeatureState 'enabled' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty

            # Verify Invoke-AdoRestMethod was called
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 1
        }
    }

    Context 'Output validation' {
        BeforeAll {
            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                return @{
                    id   = 'output-test-project-id'
                    name = 'OutputTestProject'
                }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                $bodyObj = $Body | ConvertFrom-Json
                return @{
                    featureId = $bodyObj.featureId
                    state     = $bodyObj.state
                    scope     = $bodyObj.scope
                }
            }
        }

        It 'Should return object with expected properties' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'OutputTestProject'
            $feature = 'boards'
            $featureState = 'enabled'

            # Act
            $result = Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature $feature -FeatureState $featureState -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain 'featureId'
            $result.PSObject.Properties.Name | Should -Contain 'state'
            $result.PSObject.Properties.Name | Should -Contain 'feature'
            $result.PSObject.Properties.Name | Should -Contain 'projectName'
            $result.PSObject.Properties.Name | Should -Contain 'projectId'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
        }

        It 'Should map state values correctly in output' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'OutputTestProject'

            # Act - Test enabled state
            $resultEnabled = Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature 'boards' -FeatureState 'enabled' -Confirm:$false

            # Assert
            $resultEnabled | Should -Not -BeNullOrEmpty
            $resultEnabled.state | Should -Be 'enabled'

            # Act - Test disabled state
            $resultDisabled = Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature 'repos' -FeatureState 'disabled' -Confirm:$false

            # Assert
            $resultDisabled | Should -Not -BeNullOrEmpty
            $resultDisabled.state | Should -Be 'disabled'
        }

        It 'Should preserve feature name in output' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'OutputTestProject'
            $feature = 'pipelines'

            # Act
            $result = Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature $feature -FeatureState 'enabled' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.feature | Should -Be $feature
        }

        It 'Should include project context in output' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'OutputTestProject'

            # Act
            $result = Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature 'boards' -FeatureState 'enabled' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.projectName | Should -Be $projectName
            $result.projectId | Should -Be 'output-test-project-id'
            $result.collectionUri | Should -Be $collectionUri
        }
    }

    Context 'Integration scenarios' {
        BeforeAll {
            # Mock Confirm-Default to bypass validation in pipeline scenarios
            Mock Confirm-Default -ModuleName $moduleName -MockWith {}

            Mock Get-AdoProject -ModuleName $moduleName -MockWith {
                param($Name)
                return @{
                    id   = "int-project-id-$Name"
                    name = $Name
                }
            }

            Mock Invoke-AdoRestMethod -ModuleName $moduleName -MockWith {
                param($Body)
                $bodyObj = $Body | ConvertFrom-Json
                return @{
                    featureId = $bodyObj.featureId
                    state     = $bodyObj.state
                }
            }
        }

        It 'Should handle pipeline input from Get-AdoFeatureState' {
            # Arrange - Create objects that match output of Get-AdoFeatureState
            $featureStateObjects = @(
                [PSCustomObject]@{
                    Feature       = 'boards'
                    FeatureState  = 'disabled'
                    ProjectName   = 'Project1'
                    CollectionUri = 'https://dev.azure.com/testorg'
                },
                [PSCustomObject]@{
                    Feature       = 'repos'
                    FeatureState  = 'disabled'
                    ProjectName   = 'Project1'
                    CollectionUri = 'https://dev.azure.com/testorg'
                }
            )

            # Act - Pipe objects to Set-AdoFeatureState
            $result = $featureStateObjects | Set-AdoFeatureState -FeatureState 'enabled' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].state | Should -Be 'enabled'
            $result[1].state | Should -Be 'enabled'
        }

        It 'Should handle multiple consecutive calls for different features' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'TestProject'
            $features = @('boards', 'repos', 'pipelines')

            # Act
            $results = foreach ($feature in $features) {
                Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature $feature -FeatureState 'enabled' -Confirm:$false
            }

            # Assert
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 3

            # Verify each feature was processed
            Should -Invoke Invoke-AdoRestMethod -ModuleName $moduleName -Exactly 3
        }

        It 'Should work with realistic project names containing special characters' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'My-Project.Test_123'
            $feature = 'boards'

            # Act
            $result = Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature $feature -FeatureState 'enabled' -Confirm:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.projectName | Should -Be $projectName
        }

        It 'Should enable all features for a project' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'FullProject'
            $allFeatures = @('boards', 'repos', 'pipelines', 'testPlans', 'artifacts')

            # Act
            $results = foreach ($feature in $allFeatures) {
                Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature $feature -FeatureState 'enabled' -Confirm:$false
            }

            # Assert
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 5
            $results.state | Should -Not -Contain 'disabled'
            $results.state | ForEach-Object { $_ | Should -Be 'enabled' }
        }

        It 'Should disable all features for a project' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'MinimalProject'
            $allFeatures = @('boards', 'repos', 'pipelines', 'testPlans', 'artifacts')

            # Act
            $results = foreach ($feature in $allFeatures) {
                Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature $feature -FeatureState 'disabled' -Confirm:$false
            }

            # Assert
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 5
            $results.state | Should -Not -Contain 'enabled'
            $results.state | ForEach-Object { $_ | Should -Be 'disabled' }
        }

        It 'Should handle mixed feature states for a project' {
            # Arrange
            $collectionUri = 'https://dev.azure.com/testorg'
            $projectName = 'MixedProject'

            # Act
            $boardsResult = Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature 'boards' -FeatureState 'enabled' -Confirm:$false
            $reposResult = Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature 'repos' -FeatureState 'disabled' -Confirm:$false
            $pipelinesResult = Set-AdoFeatureState -CollectionUri $collectionUri -ProjectName $projectName -Feature 'pipelines' -FeatureState 'enabled' -Confirm:$false

            # Assert
            $boardsResult.state | Should -Be 'enabled'
            $reposResult.state | Should -Be 'disabled'
            $pipelinesResult.state | Should -Be 'enabled'
        }
    }
}
