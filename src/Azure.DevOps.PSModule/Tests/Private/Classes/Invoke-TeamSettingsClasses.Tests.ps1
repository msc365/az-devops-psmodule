BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'TeamSettingsPatch' -Tag 'Private', 'Classes' {
    Context 'Constructor Tests' {
        It 'Should create object with default constructor' {
            # Act
            $result = [TeamSettingsPatch]::new()

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [TeamSettingsPatch]
        }

        It 'Should create object with default values when UseDefaults is true' {
            # Act
            $result = [TeamSettingsPatch]::new($true)

            # Assert
            $result.backlogVisibilities.'Microsoft.EpicCategory' | Should -Be $false
            $result.backlogVisibilities.'Microsoft.FeatureCategory' | Should -Be $true
            $result.backlogVisibilities.'Microsoft.RequirementCategory' | Should -Be $true
            $result.bugsBehavior | Should -Be ([BugsBehavior]::asTasks)
            $result.defaultIterationMacro | Should -Be '@currentIteration'
            $result.workingDays | Should -HaveCount 5
        }

        It 'Should create empty object when UseDefaults is false' {
            # Act
            $result = [TeamSettingsPatch]::new($false)

            # Assert
            $result.backlogVisibilities | Should -BeNullOrEmpty
            $result.bugsBehavior | Should -Be ([BugsBehavior]::off)
        }

        It 'Should create object from hashtable constructor' {
            # Arrange
            $properties = @{
                backlogIteration      = 'Iteration 1'
                bugsBehavior          = [BugsBehavior]::asRequirements
                defaultIterationMacro = '@currentIteration'
            }

            # Act
            $result = [TeamSettingsPatch]::new($properties)

            # Assert
            $result.backlogIteration | Should -Be 'Iteration 1'
            $result.bugsBehavior | Should -Be ([BugsBehavior]::asRequirements)
            $result.defaultIterationMacro | Should -Be '@currentIteration'
        }

        It 'Should create object with all direct parameters' {
            # Arrange
            $backlogVisibilities = @{ 'Microsoft.EpicCategory' = $true }
            $workingDays = @([DayOfWeek]::monday, [DayOfWeek]::tuesday)

            # Act
            $result = [TeamSettingsPatch]::new(
                'Iteration1',
                $backlogVisibilities,
                [BugsBehavior]::asTasks,
                'Iteration2',
                '@currentIteration',
                $workingDays
            )

            # Assert
            $result.backlogIteration | Should -Be 'Iteration1'
            $result.bugsBehavior | Should -Be ([BugsBehavior]::asTasks)
            $result.workingDays | Should -HaveCount 2
        }
    }

    Context 'Enum Handling Tests' {
        It 'Should handle BugsBehavior enum values correctly' {
            # Arrange
            $properties = @{ bugsBehavior = [BugsBehavior]::off }

            # Act
            $result = [TeamSettingsPatch]::new($properties)

            # Assert
            $result.bugsBehavior | Should -Be ([BugsBehavior]::off)
        }

        It 'Should handle DayOfWeek enum array correctly' {
            # Arrange
            $days = @([DayOfWeek]::monday, [DayOfWeek]::friday)
            $properties = @{ workingDays = $days }

            # Act
            $result = [TeamSettingsPatch]::new($properties)

            # Assert
            $result.workingDays | Should -HaveCount 2
            $result.workingDays[0] | Should -Be ([DayOfWeek]::monday)
            $result.workingDays[1] | Should -Be ([DayOfWeek]::friday)
        }
    }

    Context 'AsJson Method Tests' {
        It 'Should return valid JSON string' {
            # Arrange
            $object = [TeamSettingsPatch]::new($true)

            # Act
            $json = $object.AsJson()

            # Assert
            $json | Should -Not -BeNullOrEmpty
            { $json | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'Should convert enums to strings in JSON' {
            # Arrange
            $properties = @{
                bugsBehavior = [BugsBehavior]::asRequirements
                workingDays  = @([DayOfWeek]::monday, [DayOfWeek]::tuesday)
            }
            $object = [TeamSettingsPatch]::new($properties)

            # Act
            $json = $object.AsJson()
            $parsed = $json | ConvertFrom-Json

            # Assert
            $parsed.bugsBehavior | Should -Be 'asRequirements'
            $parsed.workingDays[0] | Should -Be 'monday'
            $parsed.workingDays[1] | Should -Be 'tuesday'
        }

        It 'Should preserve backlog visibilities in JSON' {
            # Arrange
            $object = [TeamSettingsPatch]::new($true)

            # Act
            $json = $object.AsJson()
            $parsed = $json | ConvertFrom-Json

            # Assert
            $parsed.backlogVisibilities.'Microsoft.EpicCategory' | Should -Be $false
            $parsed.backlogVisibilities.'Microsoft.FeatureCategory' | Should -Be $true
        }
    }

    Context 'AsHashtable Method Tests' {
        It 'Should return hashtable with correct structure' {
            # Arrange
            $object = [TeamSettingsPatch]::new($true)

            # Act
            $hashtable = $object.AsHashtable()

            # Assert
            $hashtable | Should -BeOfType [hashtable]
            $hashtable.Keys | Should -Contain 'bugsBehavior'
            $hashtable.Keys | Should -Contain 'workingDays'
        }

        It 'Should convert enums to strings in hashtable' {
            # Arrange
            $properties = @{
                bugsBehavior = [BugsBehavior]::asTasks
                workingDays  = @([DayOfWeek]::friday)
            }
            $object = [TeamSettingsPatch]::new($properties)

            # Act
            $hashtable = $object.AsHashtable()

            # Assert
            $hashtable.bugsBehavior | Should -Be 'asTasks'
            $hashtable.workingDays[0] | Should -Be 'friday'
        }

        It 'Should handle null values in hashtable' {
            # Arrange
            $object = [TeamSettingsPatch]::new()

            # Act
            $hashtable = $object.AsHashtable()

            # Assert
            $hashtable | Should -BeOfType [hashtable]
            $hashtable.backlogIteration | Should -BeNullOrEmpty
        }
    }
}
