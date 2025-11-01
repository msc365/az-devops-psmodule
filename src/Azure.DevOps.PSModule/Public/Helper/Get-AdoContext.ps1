function Get-AdoContext {
    <#
    .SYNOPSIS
        Get the current Azure DevOps connection context.

    .DESCRIPTION
        This function retrieves the current connection context for Azure DevOps, including the organization name and connection status.

    .OUTPUTS
        System.Collections.Hashtable

    .EXAMPLE
        Get-AdoContext

        Retrieves the current Azure DevOps connection context.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param ()

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            $isConnected = Get-Variable -Name 'AzDevOpsIsConnected' -Scope Global -ErrorAction SilentlyContinue
            $organization = Get-Variable -Name 'AzDevOpsOrganization' -Scope Global -ErrorAction SilentlyContinue

            if ($null -ne $isConnected -and $isConnected.Value -and $null -ne $organization) {
                return @{
                    Connected    = $isConnected.Value
                    Organization = $organization.Value
                }
            } else {
                return $null
            }
        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
