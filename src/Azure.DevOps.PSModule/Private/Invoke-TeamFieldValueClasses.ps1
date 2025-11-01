class TeamFieldValue {
    [string]$value
    [bool]$includeChildren

    # Common parameterized constructor
    TeamFieldValue([string]$value, [bool]$includeChildren = $false) {
        $this.value = $value
        $this.includeChildren = $includeChildren
    }

    [string] ToJson() {
        return ($this | ConvertTo-Json -Depth 3)
    }
}

class TeamFieldValuesPatch {
    [string]$defaultValue
    [TeamFieldValue[]]$values

    # Common parameterized constructor
    TeamFieldValuesPatch([string]$defaultValue, [TeamFieldValue[]]$values) {
        $this.defaultValue = $defaultValue
        $this.values = $values
    }

    # Method to return a JSON representation of the object
    [string] ToJson() {
        return ($this | ConvertTo-Json -Depth 3)
    }
}
