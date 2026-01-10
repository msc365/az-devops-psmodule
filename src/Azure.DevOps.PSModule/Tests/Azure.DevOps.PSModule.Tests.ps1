BeforeAll {
    # Store the module path for testing
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..'
    $moduleFile = Join-Path -Path $modulePath -ChildPath 'Azure.DevOps.PSModule.psm1'
}

Describe 'Azure.DevOps.PSModule.psm1 Module Loader' {
    Context 'Core Functionality Tests' {
        BeforeEach {
            Mock Start-Sleep { }
        }

        It 'Should successfully import the module without errors' {
            # Act & Assert
            { Import-Module $moduleFile -Force -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should export functions from Public folder' {
            # Arrange
            Import-Module $moduleFile -Force

            # Act
            $exportedCommands = Get-Command -Module 'Azure.DevOps.PSModule' -CommandType Function

            # Assert
            $exportedCommands.Count | Should -BeGreaterThan 0
        }

        It 'Should load Get-AdoProject function' {
            # Arrange
            Import-Module $moduleFile -Force

            # Act
            $command = Get-Command -Name 'Get-AdoProject' -Module 'Azure.DevOps.PSModule' -ErrorAction SilentlyContinue

            # Assert
            $command | Should -Not -BeNullOrEmpty
            $command.CommandType | Should -Be 'Function'
        }

        It 'Should load functions from multiple categories' {
            # Arrange
            Import-Module $moduleFile -Force

            # Act - Check for functions from different categories
            $coreFunction = Get-Command -Name 'Get-AdoProject' -Module 'Azure.DevOps.PSModule' -ErrorAction SilentlyContinue
            $gitFunction = Get-Command -Name 'Get-AdoRepository' -Module 'Azure.DevOps.PSModule' -ErrorAction SilentlyContinue
            $policyFunction = Get-Command -Name 'Get-AdoPolicyConfiguration' -Module 'Azure.DevOps.PSModule' -ErrorAction SilentlyContinue

            # Assert
            $coreFunction | Should -Not -BeNullOrEmpty
            $gitFunction | Should -Not -BeNullOrEmpty
            $policyFunction | Should -Not -BeNullOrEmpty
        }

        It 'Should load helper functions' {
            # Arrange
            Import-Module $moduleFile -Force

            # Act
            $command = Get-Command -Name 'Set-AdoDefault' -Module 'Azure.DevOps.PSModule' -ErrorAction SilentlyContinue

            # Assert
            $command | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Module Structure Tests' {
        BeforeEach {
            Mock Start-Sleep { }
        }

        It 'Should have Private folder' {
            # Arrange
            $privatePath = Join-Path -Path $modulePath -ChildPath 'Private'

            # Act & Assert
            Test-Path -Path $privatePath | Should -Be $true
        }

        It 'Should have Public folder' {
            # Arrange
            $publicPath = Join-Path -Path $modulePath -ChildPath 'Public'

            # Act & Assert
            Test-Path -Path $publicPath | Should -Be $true
        }

        It 'Should contain PS1 files in Public folder' {
            # Arrange
            $publicPath = Join-Path -Path $modulePath -ChildPath 'Public'

            # Act
            $ps1Files = Get-ChildItem -Path $publicPath -Filter '*.ps1' -Recurse

            # Assert
            $ps1Files.Count | Should -BeGreaterThan 0
        }
    }

    Context 'Module Loading Behavior Tests' {
        BeforeEach {
            Mock Start-Sleep { }
        }

        It 'Should reimport module without errors' {
            # Arrange
            Import-Module $moduleFile -Force

            # Act & Assert
            { Import-Module $moduleFile -Force -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should maintain function availability after reimport' {
            # Arrange
            Import-Module $moduleFile -Force
            $initialCommand = Get-Command -Name 'Get-AdoProject' -Module 'Azure.DevOps.PSModule'

            # Act
            Import-Module $moduleFile -Force
            $reimportedCommand = Get-Command -Name 'Get-AdoProject' -Module 'Azure.DevOps.PSModule'

            # Assert
            $reimportedCommand | Should -Not -BeNullOrEmpty
            $reimportedCommand.Name | Should -Be $initialCommand.Name
        }
    }

    Context 'Function Category Tests' {
        BeforeEach {
            Mock Start-Sleep { }
            Import-Module $moduleFile -Force
        }

        It 'Should load Core category functions' {
            # Act
            $functions = Get-Command -Module 'Azure.DevOps.PSModule' | Where-Object { $_.Name -like '*AdoProject*' -or $_.Name -like '*AdoTeam*' -or $_.Name -like '*AdoProcess*' }

            # Assert
            $functions.Count | Should -BeGreaterThan 0
        }

        It 'Should load Git category functions' {
            # Act
            $functions = Get-Command -Module 'Azure.DevOps.PSModule' | Where-Object { $_.Name -like '*AdoRepository*' }

            # Assert
            $functions.Count | Should -BeGreaterThan 0
        }

        It 'Should load Policy category functions' {
            # Act
            $functions = Get-Command -Module 'Azure.DevOps.PSModule' | Where-Object { $_.Name -like '*AdoPolicy*' }

            # Assert
            $functions.Count | Should -BeGreaterThan 0
        }

        It 'Should load Pipeline category functions' {
            # Act
            $functions = Get-Command -Module 'Azure.DevOps.PSModule' | Where-Object { $_.Name -like '*AdoEnvironment*' -or $_.Name -like '*AdoCheck*' }

            # Assert
            $functions.Count | Should -BeGreaterThan 0
        }

        It 'Should load WorkItemTracking category functions' {
            # Act
            $functions = Get-Command -Module 'Azure.DevOps.PSModule' | Where-Object { $_.Name -like '*AdoClassificationNode*' }

            # Assert
            $functions.Count | Should -BeGreaterThan 0
        }

        It 'Should load Graph category functions' {
            # Act
            $functions = Get-Command -Module 'Azure.DevOps.PSModule' | Where-Object { $_.Name -like '*AdoGroup*' -or $_.Name -like '*AdoDescriptor*' -or $_.Name -like '*AdoMembership*' }

            # Assert
            $functions.Count | Should -BeGreaterThan 0
        }
    }
}
