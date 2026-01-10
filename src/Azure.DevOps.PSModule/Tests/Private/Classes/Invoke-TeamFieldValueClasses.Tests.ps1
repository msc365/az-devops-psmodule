BeforeAll {
    # Import the module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..'
    $moduleName = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psd1'

    # Remove module if already loaded
    Get-Module Azure.DevOps.PSModule | Remove-Module -Force

    # Import the module
    Import-Module $moduleName -Force -Verbose:$false
}

Describe 'TeamFieldValue' -Tag 'Private', 'Classes' {
    Context 'Constructor Tests' {
        It 'Should create object with default constructor' {
            # Act
            $result = [TeamFieldValue]::new()

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [TeamFieldValue]
        }

        It 'Should create object from hashtable constructor' {
            # Arrange
            $properties = @{
                value           = 'TestValue'
                includeChildren = $true
            }

            # Act
            $result = [TeamFieldValue]::new($properties)

            # Assert
            $result.value | Should -Be 'TestValue'
            $result.includeChildren | Should -Be $true
        }

        It 'Should create object with direct parameter assignment' {
            # Act
            $result = [TeamFieldValue]::new('MyValue', $true)

            # Assert
            $result.value | Should -Be 'MyValue'
            $result.includeChildren | Should -Be $true
        }

        It 'Should use default value for includeChildren parameter' {
            # Act
            $result = [TeamFieldValue]::new('MyValue', $false)

            # Assert
            $result.value | Should -Be 'MyValue'
            $result.includeChildren | Should -Be $false
        }
    }

    Context 'AsJson Method Tests' {
        It 'Should return valid JSON string' {
            # Arrange
            $object = [TeamFieldValue]::new('TestValue', $true)

            # Act
            $json = $object.AsJson()

            # Assert
            $json | Should -Not -BeNullOrEmpty
            { $json | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'Should preserve property values in JSON' {
            # Arrange
            $object = [TeamFieldValue]::new('TestValue', $true)

            # Act
            $json = $object.AsJson()
            $parsed = $json | ConvertFrom-Json

            # Assert
            $parsed.value | Should -Be 'TestValue'
            $parsed.includeChildren | Should -Be $true
        }
    }

    Context 'AsHashtable Method Tests' {
        It 'Should return hashtable with correct properties' {
            # Arrange
            $object = [TeamFieldValue]::new('TestValue', $false)

            # Act
            $hashtable = $object.AsHashtable()

            # Assert
            $hashtable | Should -BeOfType [hashtable]
            $hashtable.value | Should -Be 'TestValue'
            $hashtable.includeChildren | Should -Be $false
        }

        It 'Should preserve all property values' {
            # Arrange
            $object = [TeamFieldValue]::new('AreaPath\Child', $true)

            # Act
            $hashtable = $object.AsHashtable()

            # Assert
            $hashtable.Keys.Count | Should -Be 2
            $hashtable.value | Should -Be 'AreaPath\Child'
            $hashtable.includeChildren | Should -Be $true
        }
    }
}

Describe 'TeamFieldValuesPatch' -Tag 'Private', 'Classes' {
    Context 'Constructor Tests' {
        It 'Should create object with default constructor' {
            # Act
            $result = [TeamFieldValuesPatch]::new()

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [TeamFieldValuesPatch]
        }

        It 'Should create object from hashtable constructor' {
            # Arrange
            $value = [TeamFieldValue]::new('TestValue', $true)
            $properties = @{
                defaultValue = 'DefaultArea'
                values       = @($value)
            }

            # Act
            $result = [TeamFieldValuesPatch]::new($properties)

            # Assert
            $result.defaultValue | Should -Be 'DefaultArea'
            $result.values | Should -HaveCount 1
            $result.values[0].value | Should -Be 'TestValue'
        }

        It 'Should create object with direct parameter assignment' {
            # Arrange
            $value1 = [TeamFieldValue]::new('Value1', $false)
            $value2 = [TeamFieldValue]::new('Value2', $true)
            $values = @($value1, $value2)

            # Act
            $result = [TeamFieldValuesPatch]::new('DefaultValue', $values)

            # Assert
            $result.defaultValue | Should -Be 'DefaultValue'
            $result.values | Should -HaveCount 2
        }
    }

    Context 'AsJson Method Tests' {
        It 'Should return valid JSON string' {
            # Arrange
            $value = [TeamFieldValue]::new('TestValue', $true)
            $object = [TeamFieldValuesPatch]::new('DefaultValue', @($value))

            # Act
            $json = $object.AsJson()

            # Assert
            $json | Should -Not -BeNullOrEmpty
            { $json | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'Should preserve nested TeamFieldValue objects in JSON' {
            # Arrange
            $value = [TeamFieldValue]::new('TestArea', $true)
            $object = [TeamFieldValuesPatch]::new('DefaultArea', @($value))

            # Act
            $json = $object.AsJson()
            $parsed = $json | ConvertFrom-Json

            # Assert
            $parsed.defaultValue | Should -Be 'DefaultArea'
            $parsed.values | Should -HaveCount 1
            $parsed.values[0].value | Should -Be 'TestArea'
        }
    }

    Context 'AsHashtable Method Tests' {
        It 'Should return hashtable with correct structure' {
            # Arrange
            $value = [TeamFieldValue]::new('TestValue', $false)
            $object = [TeamFieldValuesPatch]::new('DefaultValue', @($value))

            # Act
            $hashtable = $object.AsHashtable()

            # Assert
            $hashtable | Should -BeOfType [hashtable]
            $hashtable.defaultValue | Should -Be 'DefaultValue'
            $hashtable.values | Should -HaveCount 1
        }

        It 'Should handle multiple values in array' {
            # Arrange
            $value1 = [TeamFieldValue]::new('Value1', $true)
            $value2 = [TeamFieldValue]::new('Value2', $false)
            $object = [TeamFieldValuesPatch]::new('DefaultValue', @($value1, $value2))

            # Act
            $hashtable = $object.AsHashtable()

            # Assert
            $hashtable.values | Should -HaveCount 2
            $hashtable.values[0].value | Should -Be 'Value1'
            $hashtable.values[1].value | Should -Be 'Value2'
        }
    }
}
