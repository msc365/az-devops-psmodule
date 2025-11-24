function Set-AdoProject {
    <#
    .SYNOPSIS
        Updates an existing Azure DevOps project through REST API.

    .DESCRIPTION
        This function updates an existing Azure DevOps project through REST API.

    .PARAMETER ProjectId
        Optional. Project ID or project name.

    .PARAMETER Name
        Optional. The name of the project to update.

    .PARAMETER Description
        Optional. The description of the project to update.

    .PARAMETER Visibility
        Optional. The visibility of the project to update. Default is 'Private'.

    .PARAMETER ApiVersion
        Optional. The API version to use. Default is '7.1'.

    .OUTPUTS
        System.Object

        The updated project object.
    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/update

    .EXAMPLE
        Set-AdoProject -ProjectId 'my-project-002' -Name 'my-project-updated-name'

        Updates the name of the Azure DevOps project with ID 'my-project-002' to 'my-project-updated-name'.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Private', 'Public')]
        [string]$Visibility,

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command       : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  Name        : {0}' -f $Name)
        Write-Debug ('  Description : {0}' -f $Description)
        Write-Debug ('  Visibility  : {0}' -f $Visibility)
        Write-Debug ('  ApiVersion  : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/_apis/projects/{1}?api-version={2}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($AzDevOpsOrganization), $ProjectId, $ApiVersion)

            $bodyObject = @{}

            if ($PSBoundParameters.ContainsKey('Name')) {
                $bodyObject['name'] = $Name
            }
            if ($PSBoundParameters.ContainsKey('Description')) {
                $bodyObject['description'] = $Description
            }
            if ($PSBoundParameters.ContainsKey('Visibility')) {
                $bodyObject['visibility'] = $Visibility
            }

            $body = $bodyObject | ConvertTo-Json -Depth 3 -Compress

            $params = @{
                Method      = 'PATCH'
                Uri         = $azDevOpsUri
                ContentType = 'application/json'
                Headers     = ((ConvertFrom-SecureString -SecureString $global:AzDevOpsHeaders -AsPlainText) | ConvertFrom-Json -AsHashtable)
                Body        = $body
            }

            $response = Invoke-RestMethod @params -Verbose:$VerbosePreference

            $status = $response.status

            while ($status -ne 'succeeded') {
                Write-Verbose 'Checking project update status...'
                Start-Sleep -Seconds 2

                $response = Invoke-RestMethod -Method GET -Uri $response.url -Headers $params.Headers
                $status = $response.status

                if ($status -eq 'failed') {
                    Write-Error -Message ('Project update failed {0}' -f $PSItem.Exception.Message)
                }
            }

            return $response

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
