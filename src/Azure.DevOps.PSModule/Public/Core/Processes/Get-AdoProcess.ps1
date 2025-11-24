function Get-AdoProcess {
    <#
    .SYNOPSIS
        Get the process details.

    .DESCRIPTION
        This function retrieves the process details for an Azure DevOps process through REST API.

    .PARAMETER Process
        Optional. The name of the process. Default is $null.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.Object

        The process details object.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/processes

    .EXAMPLE
        $processes = Get-AdoProcess

        Gets all available processes.

    .EXAMPLE
        $process = Get-AdoProcess -Process 'Agile'

        Gets the details of the 'Agile' process.

    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Agile', 'Scrum', 'CMMI', 'Basic')]
        [string]$Process,

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command      : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  Process    : {0}' -f $Process)
        Write-Debug ('  ApiVersion : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/_apis/process/processes?api-version={1}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), $ApiVersion)

            $params = @{
                Method  = 'GET'
                Uri     = $azDevOpsUri
                Headers = ((ConvertFrom-SecureString -SecureString $global:AzDevOpsHeaders -AsPlainText) | ConvertFrom-Json -AsHashtable)
            }

            $response = Invoke-RestMethod @params -Verbose:$VerbosePreference

            if ($Process) {
                return $response.value | Where-Object {
                    $_.name -eq $Process
                }
            } else {
                return $response.value
            }

        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
