enum TimeFrame {
    past
    current
    future
}

class TeamIterationAttributes {
    [string]$finishDate
    [string]$startDate
    [TimeFrame]$timeFrame

    # Default constructor
    TeamIterationAttributes() { $this.Init(@{}) }

    # Convenience constructor from hashtable
    TeamIterationAttributes([hashtable]$Properties) { $this.Init($Properties) }

    # Common constructor for direct parameter assignment
    TeamIterationAttributes([string]$finishDate, [string]$startDate, [TimeFrame]$timeFrame) {
        $this.Init(@{
                finishDate = $finishDate
                startDate  = $startDate
                timeFrame  = $timeFrame
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
        return ($this | ConvertTo-Json -Depth 3)
    }

    # Method to return a Hashtable representation of the object
    [hashtable] AsHashtable() {
        return = @{
            finishDate = $this.finishDate
            startDate  = $this.startDate
            timeFrame  = [string]$this.timeFrame
        }
    }
}

class TeamSettingsIteration {
    [string]$id
    [string]$name
    [string]$path
    [TeamIterationAttributes]$attributes

    # Default constructor
    TeamSettingsIteration() { $this.Init(@{}) }

    # Convenience constructor from hashtable
    TeamSettingsIteration([hashtable]$Properties) { $this.Init($Properties) }

    # Common constructor for id only
    TeamSettingsIteration([string]$id) {
        $this.Init(@{ id = $id })
    }

    # Common constructor for direct parameter assignment
    TeamSettingsIteration([string]$id, [string]$name, [string]$path, [TeamIterationAttributes]$attributes) {
        $this.Init(@{
                id         = $id
                name       = $name
                path       = $path
                attributes = $attributes
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
        return ($this | ConvertTo-Json -Depth 3)
    }

    # Method to return a Hashtable representation of the object
    [hashtable] AsHashtable() {
        return = @{
            id         = $this.id
            name       = $this.name
            path       = $this.path
            attributes = if ($this.attributes) { $this.attributes.AsHashtable() } else { $null }
        }
    }
}
