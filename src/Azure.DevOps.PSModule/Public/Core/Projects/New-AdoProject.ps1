function New-AdoProject {
    <#
    .SYNOPSIS
        Create a new project in an Azure DevOps organization.

    .DESCRIPTION
        This function creates a new project in an Azure DevOps organization through REST API.

    .PARAMETER Name
        Mandatory. The name of the project to create.

    .PARAMETER Description
        Optional. The description of the project.

    .PARAMETER Process
        Optional. The process to use for the project. Default is 'Agile'.

    .PARAMETER SourceControl
        Optional. The source control type to use for the project. Default is 'Git'.

    .PARAMETER Visibility
        Optional. The visibility of the project. Default is 'Private'.

    .PARAMETER ApiVersion
        Optional. The API version to use. Default is '7.1'.

    .OUTPUTS
        System.Object

        An object representing the created project.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/create

    .EXAMPLE
        New-AdoProject -Name 'my-project-002' -Description 'My new project'

        Creates a new project named 'my-project-002' with the description 'My new project'.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Agile', 'Scrum', 'CMMI', 'Basic')]
        [string]$Process = 'Agile',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Git', 'Tfvc')]
        [string]$SourceControl = 'Git',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Private', 'Public')]
        [string]$Visibility = 'Private',

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command       : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  Name        : {0}' -f $Name)
        Write-Debug ('  Description : {0}' -f $Description)
        Write-Debug ('  Process     : {0}' -f $Process)
        Write-Debug ('  Visibility  : {0}' -f $Visibility)
        Write-Debug ('  ApiVersion  : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $processTemplate = Get-AdoProcess -process $Process

            $uriFormat = '{0}/_apis/projects?api-version={1}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($AzDevOpsOrganization), $ApiVersion)

            $body = @{
                name         = $Name
                description  = $Description
                capabilities = @{
                    versioncontrol  = @{
                        sourceControlType = $SourceControl
                    }
                    processTemplate = @{
                        templateTypeId = $processTemplate.id
                    }
                }
                visibility   = $Visibility

            } | ConvertTo-Json -Depth 5 -Compress

            $params = @{
                Method      = 'POST'
                Uri         = $azDevOpsUri
                ContentType = 'application/json'
                Headers     = ((ConvertFrom-SecureString -SecureString $global:AzDevOpsHeaders -AsPlainText) | ConvertFrom-Json -AsHashtable)
                Body        = $body
            }

            $response = Invoke-RestMethod @params -Verbose:$VerbosePreference

            $status = $response.status
            while ($status -ne 'succeeded') {
                Write-Verbose 'Checking project creation status...'
                Start-Sleep -Seconds 2

                $response = Invoke-RestMethod -Method GET -Uri $response.url -Headers $params.Headers
                $status = $response.status

                if ($status -eq 'failed') {
                    Write-Error -Message ('Project creation failed {0}' -f $PSItem.Exception.Message)
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
