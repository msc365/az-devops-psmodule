BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'TeamIterationAttributes' -Tag 'Private', 'Classes' {
    Context 'Constructor Tests' {
        It 'Should create object with default constructor' {
            # Act
            $result = [TeamIterationAttributes]::new()

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [TeamIterationAttributes]
        }

        It 'Should create object from hashtable constructor' {
            # Arrange
            $properties = @{
                finishDate = '2026-12-31'
                startDate  = '2026-01-01'
                timeFrame  = [TimeFrame]::future
            }

            # Act
            $result = [TeamIterationAttributes]::new($properties)

            # Assert
            $result.finishDate | Should -Be '2026-12-31'
            $result.startDate | Should -Be '2026-01-01'
            $result.timeFrame | Should -Be ([TimeFrame]::future)
        }

        It 'Should create object with direct parameter assignment' {
            # Act
            $result = [TeamIterationAttributes]::new('2026-06-30', '2026-01-01', [TimeFrame]::current)

            # Assert
            $result.finishDate | Should -Be '2026-06-30'
            $result.startDate | Should -Be '2026-01-01'
            $result.timeFrame | Should -Be ([TimeFrame]::current)
        }
    }

    Context 'Enum Handling Tests' {
        It 'Should handle TimeFrame enum value past' {
            # Arrange
            $properties = @{ timeFrame = [TimeFrame]::past }

            # Act
            $result = [TeamIterationAttributes]::new($properties)

            # Assert
            $result.timeFrame | Should -Be ([TimeFrame]::past)
        }

        It 'Should handle TimeFrame enum value current' {
            # Arrange
            $properties = @{ timeFrame = [TimeFrame]::current }

            # Act
            $result = [TeamIterationAttributes]::new($properties)

            # Assert
            $result.timeFrame | Should -Be ([TimeFrame]::current)
        }

        It 'Should handle TimeFrame enum value future' {
            # Arrange
            $properties = @{ timeFrame = [TimeFrame]::future }

            # Act
            $result = [TeamIterationAttributes]::new($properties)

            # Assert
            $result.timeFrame | Should -Be ([TimeFrame]::future)
        }
    }

    Context 'AsJson Method Tests' {
        It 'Should return valid JSON string' {
            # Arrange
            $object = [TeamIterationAttributes]::new('2026-12-31', '2026-01-01', [TimeFrame]::current)

            # Act
            $json = $object.AsJson()

            # Assert
            $json | Should -Not -BeNullOrEmpty
            { $json | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'Should preserve date values in JSON' {
            # Arrange
            $object = [TeamIterationAttributes]::new('2026-03-31', '2026-01-01', [TimeFrame]::current)

            # Act
            $json = $object.AsJson()
            $parsed = $json | ConvertFrom-Json

            # Assert
            $parsed.finishDate | Should -Be '2026-03-31'
            $parsed.startDate | Should -Be '2026-01-01'
        }
    }

    Context 'AsHashtable Method Tests' {
        It 'Should return hashtable with correct properties' {
            # Arrange
            $object = [TeamIterationAttributes]::new('2026-12-31', '2026-01-01', [TimeFrame]::future)

            # Act
            $hashtable = $object.AsHashtable()

            # Assert
            $hashtable | Should -BeOfType [hashtable]
            $hashtable.finishDate | Should -Be '2026-12-31'
            $hashtable.startDate | Should -Be '2026-01-01'
            $hashtable.timeFrame | Should -Be 'future'
        }

        It 'Should convert enum to string in hashtable' {
            # Arrange
            $object = [TeamIterationAttributes]::new('2026-06-30', '2026-01-01', [TimeFrame]::current)

            # Act
            $hashtable = $object.AsHashtable()

            # Assert
            $hashtable.timeFrame | Should -Be 'current'
        }
    }
}

Describe 'TeamSettingsIteration' -Tag 'Private', 'Classes' {
    Context 'Constructor Tests' {
        It 'Should create object with default constructor' {
            # Act
            $result = [TeamSettingsIteration]::new()

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [TeamSettingsIteration]
        }

        It 'Should create object with id-only constructor' {
            # Act
            $result = [TeamSettingsIteration]::new('12345678-1234-1234-1234-123456789abc')

            # Assert
            $result.id | Should -Be '12345678-1234-1234-1234-123456789abc'
            $result.name | Should -BeNullOrEmpty
        }

        It 'Should create object from hashtable constructor' {
            # Arrange
            $attributes = [TeamIterationAttributes]::new('2026-12-31', '2026-01-01', [TimeFrame]::current)
            $properties = @{
                id         = 'guid-123'
                name       = 'Sprint 1'
                path       = 'Project\Sprint 1'
                attributes = $attributes
            }

            # Act
            $result = [TeamSettingsIteration]::new($properties)

            # Assert
            $result.id | Should -Be 'guid-123'
            $result.name | Should -Be 'Sprint 1'
            $result.path | Should -Be 'Project\Sprint 1'
            $result.attributes | Should -Not -BeNullOrEmpty
        }

        It 'Should create object with all direct parameters' {
            # Arrange
            $attributes = [TeamIterationAttributes]::new('2026-06-30', '2026-01-01', [TimeFrame]::current)

            # Act
            $result = [TeamSettingsIteration]::new('guid-456', 'Sprint 2', 'Project\Sprint 2', $attributes)

            # Assert
            $result.id | Should -Be 'guid-456'
            $result.name | Should -Be 'Sprint 2'
            $result.path | Should -Be 'Project\Sprint 2'
            $result.attributes.startDate | Should -Be '2026-01-01'
        }
    }

    Context 'Nested Object Handling Tests' {
        It 'Should handle null attributes property' {
            # Arrange
            $properties = @{
                id   = 'guid-789'
                name = 'Sprint 3'
            }

            # Act
            $result = [TeamSettingsIteration]::new($properties)

            # Assert
            $result.attributes | Should -BeNullOrEmpty
        }

        It 'Should preserve nested attributes object' {
            # Arrange
            $attributes = [TeamIterationAttributes]::new('2026-12-31', '2026-01-01', [TimeFrame]::future)
            $properties = @{
                id         = 'guid-101'
                name       = 'Sprint 4'
                attributes = $attributes
            }

            # Act
            $result = [TeamSettingsIteration]::new($properties)

            # Assert
            $result.attributes | Should -Not -BeNullOrEmpty
            $result.attributes.timeFrame | Should -Be ([TimeFrame]::future)
        }
    }

    Context 'AsJson Method Tests' {
        It 'Should return valid JSON string' {
            # Arrange
            $attributes = [TeamIterationAttributes]::new('2026-12-31', '2026-01-01', [TimeFrame]::current)
            $object = [TeamSettingsIteration]::new('guid-123', 'Sprint 1', 'Project\Sprint 1', $attributes)

            # Act
            $json = $object.AsJson()

            # Assert
            $json | Should -Not -BeNullOrEmpty
            { $json | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'Should preserve nested attributes in JSON' {
            # Arrange
            $attributes = [TeamIterationAttributes]::new('2026-06-30', '2026-01-01', [TimeFrame]::current)
            $object = [TeamSettingsIteration]::new('guid-456', 'Sprint 2', 'Project\Sprint 2', $attributes)

            # Act
            $json = $object.AsJson()
            $parsed = $json | ConvertFrom-Json

            # Assert
            $parsed.id | Should -Be 'guid-456'
            $parsed.attributes.startDate | Should -Be '2026-01-01'
        }
    }

    Context 'AsHashtable Method Tests' {
        It 'Should return hashtable with correct structure' {
            # Arrange
            $attributes = [TeamIterationAttributes]::new('2026-12-31', '2026-01-01', [TimeFrame]::future)
            $object = [TeamSettingsIteration]::new('guid-789', 'Sprint 3', 'Project\Sprint 3', $attributes)

            # Act
            $hashtable = $object.AsHashtable()

            # Assert
            $hashtable | Should -BeOfType [hashtable]
            $hashtable.id | Should -Be 'guid-789'
            $hashtable.name | Should -Be 'Sprint 3'
            $hashtable.path | Should -Be 'Project\Sprint 3'
            $hashtable.attributes | Should -Not -BeNullOrEmpty
        }

        It 'Should convert nested attributes to hashtable' {
            # Arrange
            $attributes = [TeamIterationAttributes]::new('2026-03-31', '2026-01-01', [TimeFrame]::current)
            $object = [TeamSettingsIteration]::new('guid-101', 'Sprint 4', 'Project\Sprint 4', $attributes)

            # Act
            $hashtable = $object.AsHashtable()

            # Assert
            $hashtable.attributes | Should -BeOfType [hashtable]
            $hashtable.attributes.timeFrame | Should -Be 'current'
        }

        It 'Should handle null attributes gracefully' {
            # Arrange
            $object = [TeamSettingsIteration]::new('guid-102', 'Sprint 5', 'Project\Sprint 5', $null)

            # Act
            $hashtable = $object.AsHashtable()

            # Assert
            $hashtable.attributes | Should -BeNullOrEmpty
        }
    }
}
