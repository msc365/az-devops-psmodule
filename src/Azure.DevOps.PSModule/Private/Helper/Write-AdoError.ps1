function Write-AdoError {
    <#
    .SYNOPSIS
        Write a terminating error with a custom message.

    .DESCRIPTION
        This function creates and throws a terminating error with the provided message.

    .PARAMETER Message
        The error message to be included in the terminating error.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Message
    )

    begin {
        Write-Debug ("Command: $($MyInvocation.MyCommand.Name)")
    }

    process {
        $errRecord = [System.Management.Automation.ErrorRecord]::new(
            [Exception]::new($Message),
            'ErrorID',
            [System.Management.Automation.ErrorCategory]::OperationStopped,
            'TargetObject'
        )

        $PScmdlet.ThrowTerminatingError($errRecord)
    }

    end {
        Write-Debug ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
