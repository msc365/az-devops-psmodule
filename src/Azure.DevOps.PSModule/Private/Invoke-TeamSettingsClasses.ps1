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
    TeamSettingsPatch() {
        $this.backlogIteration = $null
        $this.backlogVisibilities = @{
            'Microsoft.EpicCategory'        = $false
            'Microsoft.FeatureCategory'     = $true
            'Microsoft.RequirementCategory' = $true
        }
        $this.bugsBehavior = [BugsBehavior]::asTasks
        $this.defaultIteration = $null
        $this.defaultIterationMacro = '@currentIteration'
        $this.workingDays = [DayOfWeek[]]@(
            [DayOfWeek]::monday,
            [DayOfWeek]::tuesday,
            [DayOfWeek]::wednesday,
            [DayOfWeek]::thursday,
            [DayOfWeek]::friday
        )
    }

    # Common parameterized constructor
    TeamSettingsPatch([string]$backlogIteration, [object]$backlogVisibilities, [BugsBehavior]$bugsBehavior,
        [string]$defaultIteration, [string]$defaultIterationMacro, [DayOfWeek[]]$workingDays) {

        $this.backlogIteration = $backlogIteration
        $this.backlogVisibilities = $backlogVisibilities
        $this.bugsBehavior = $bugsBehavior
        $this.defaultIteration = $defaultIteration
        $this.defaultIterationMacro = $defaultIterationMacro
        $this.workingDays = $workingDays
    }

    # Method to return a JSON representation of the object
    [string] ToJson() {
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
}
