enum BugsBehavior {
    off
    asRequirements
    asTasks
}

enum DayOfWeek {
    sunday
    monday
    tuesday
    wednesday
    thursday
    friday
    saturday
}

<#
    .SYNOPSIS
        Data contract for what Azure DevOps API expect to receive when using PATCH
#>
class TeamSettingsPatch {
    [string]$backlogIteration
    [object]$backlogVisibilities
    [BugsBehavior]$bugsBehavior
    [string]$defaultIteration
    [string]$defaultIterationMacro
    [DayOfWeek[]]$workingDays

    # Default constructor
    TeamSettingsPatch() { $this.Init(@{}) }

    # Default constructor for common default values
    TeamSettingsPatch([bool]$UseDefaults) {
        if ($UseDefaults) {
            $this.Init(
                @{
                    backlogVisibilities   = @{
                        'Microsoft.EpicCategory'        = $false
                        'Microsoft.FeatureCategory'     = $true
                        'Microsoft.RequirementCategory' = $true
                    }
                    bugsBehavior          = [BugsBehavior]::asTasks
                    defaultIterationMacro = '@currentIteration'
                    workingDays           = [DayOfWeek[]]@(
                        [DayOfWeek]::monday,
                        [DayOfWeek]::tuesday,
                        [DayOfWeek]::wednesday,
                        [DayOfWeek]::thursday,
                        [DayOfWeek]::friday
                    )
                }
            )
        } else {
            $this.Init(@{})
        }
    }

    # Convenience constructor from hashtable
    TeamSettingsPatch([hashtable]$Properties) { $this.Init($Properties) }

    # Common constructor for direct parameter assignment
    TeamSettingsPatch([string]$backlogIteration, [object]$backlogVisibilities, [BugsBehavior]$bugsBehavior,
        [string]$defaultIteration, [string]$defaultIterationMacro, [DayOfWeek[]]$workingDays) {

        $this.Init(@{
                backlogIteration      = $backlogIteration
                backlogVisibilities   = $backlogVisibilities
                bugsBehavior          = $bugsBehavior
                defaultIteration      = $defaultIteration
                defaultIterationMacro = $defaultIterationMacro
                workingDays           = $workingDays
            })
    }

    # Shared initializer method
    [void] Init([hashtable]$Properties) {
        foreach ($Property in $Properties.Keys) {
            $this.$Property = $Properties.$Property
        }
    }

    # Method to return a JSON representation of the object
    [string] AsJson() {
        $jsonObject = @{
            backlogIteration      = $this.backlogIteration
            backlogVisibilities   = $this.backlogVisibilities
            bugsBehavior          = [string]$this.bugsBehavior
            defaultIteration      = $this.defaultIteration
            defaultIterationMacro = $this.defaultIterationMacro
            workingDays           = @($this.workingDays | ForEach-Object { [string]$_ })
        }
        return ($jsonObject | ConvertTo-Json -Depth 3)
    }

    # Method to return a Hashtable representation of the object
    [hashtable] AsHashtable() {
        $hashTable = @{
            backlogIteration      = $this.backlogIteration
            backlogVisibilities   = $this.backlogVisibilities
            bugsBehavior          = [string]$this.bugsBehavior
            defaultIteration      = $this.defaultIteration
            defaultIterationMacro = $this.defaultIterationMacro
            workingDays           = @($this.workingDays | ForEach-Object { [string]$_ })
        }
        return $hashTable
    }
}
