function Get-AdoProject {
    <#
    .SYNOPSIS
        Get project details.

    .DESCRIPTION
        This function retrieves the project details for a given Azure DevOps project through REST API.

    .PARAMETER ProjectId
        Required. Project ID or project name.

    .PARAMETER IncludeCapabilities
        Optional. Include capabilities (such as source control) in the team project result. Default is 'false'.

    .PARAMETER IncludeHistory
        Optional. Search within renamed projects (that had such name in the past). Default is 'false'.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/get?view=azure-devops

    .EXAMPLE
        $project = Get-AdoProject -ProjectName 'my-project'

        Gets the project details for the specified project.

    .EXAMPLE
        $project =  Get-AdoProject -ProjectName 'my-project' -IncludeCapabilities -IncludeHistory

        Gets the project details for the specified project, including capabilities and searching within renamed projects.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeCapabilities,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeHistory,

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command               : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId           : {0}' -f $ProjectId)
        Write-Debug ('  IncludeCapabilities : {0}' -f $IncludeCapabilities)
        Write-Debug ('  IncludeHistory      : {0}' -f $IncludeHistory)
        Write-Debug ('  ApiVersion          : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/_apis/projects/{1}?includeCapabilities={2}&includeHistory={3}&api-version={4}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                $IncludeCapabilities, $IncludeHistory, $ApiVersion)

            $params = @{
                Method  = 'GET'
                Uri     = $azDevOpsUri
                Headers = ((ConvertFrom-SecureString -SecureString $global:AzDevOpsHeaders -AsPlainText) | ConvertFrom-Json -AsHashtable)
            }

            $response = Invoke-RestMethod @params -Verbose:$VerbosePreference

            return $response

        } catch {
            if ($_.Exception.StatusCode -eq 'NotFound') {
                Write-Debug 'Project not found.'
                return $null
            }
            throw $_
        }
    }

    end {
        Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }

}
