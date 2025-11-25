class TeamFieldValue {
    [string]$value
    [bool]$includeChildren

    # Default constructor
    TeamFieldValue() { $this.Init(@{}) }

    # Convenience constructor from hashtable
    TeamFieldValue([hashtable]$Properties) { $this.Init($Properties) }

    # Common constructor for direct parameter assignment
    TeamFieldValue([string]$value, [bool]$includeChildren = $false) {
        $this.Init(@{
                value           = $value
                includeChildren = $includeChildren
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
            value           = $this.value
            includeChildren = $this.includeChildren
        }
    }
}

class TeamFieldValuesPatch {
    [string]$defaultValue
    [TeamFieldValue[]]$values

    # Default constructor
    TeamFieldValuesPatch() { $this.Init(@{}) }

    # Convenience constructor from hashtable
    TeamFieldValuesPatch([hashtable]$Properties) { $this.Init($Properties) }

    # Common constructor for direct parameter assignment
    TeamFieldValuesPatch([string]$defaultValue, [TeamFieldValue[]]$values) {
        $this.Init(@{
                defaultValue = $defaultValue
                values       = $values
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
            defaultValue = $this.defaultValue
            values       = $this.values
        }
    }
}
