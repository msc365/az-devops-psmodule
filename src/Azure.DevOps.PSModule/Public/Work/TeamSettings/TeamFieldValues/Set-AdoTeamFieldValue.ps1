# cSpell: words teamfieldvalues, teamsettings
function Set-AdoTeamFieldValue {
    <#
    .SYNOPSIS
        Sets the team field value settings for a team in an Azure DevOps project.

    .DESCRIPTION
        This function sets the team field value settings for a specified team in an Azure DevOps project using the REST API.

    .PARAMETER ProjectId
        Mandatory. The ID or name of the Azure DevOps project.

    .PARAMETER TeamId
        Optional. The ID or name of the team within the project. If not specified, the default team is used.

    .PARAMETER DefaultValue
        Mandatory. The default team field value for the team.

    .PARAMETER Values
        Mandatory. An array of team field values to set for the team.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        TeamFieldValuesPatch

        The updated team field value settings for the specified team.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/work/teamfieldvalues/update

    .NOTES
        - Requires an active connection to Azure DevOps using Connect-AdoOrganization.

    .EXAMPLE
        $defaultValue = 'e2egov-fantastic-four'
        $values = @(
            @{
                value           = 'e2egov-fantastic-four'
                includeChildren = $false
            }
            ,
            @{
                value           = 'e2egov-fantastic-four\Human Torch'
                includeChildren = $false
            },
            @{
                value           = 'e2egov-fantastic-four\Invisible Woman'
                includeChildren = $false
            },
            @{
                value           = 'e2egov-fantastic-four\Mister Fantastic'
                includeChildren = $false
            },
            @{
                value           = 'e2egov-fantastic-four\The Thing'
                includeChildren = $false
            }
        )
        Set-AdoTeamFieldValue -ProjectId 'e2egov-fantastic-four' -DefaultValue $defaultValue -Values $values

        This example sets the team field values for the default team in the specified project.

    .EXAMPLE
        $defaultValue = 'e2egov-fantastic-four\Mister Fantastic'
        $values = @(
            @{
                value           = 'e2egov-fantastic-four\Mister Fantastic'
                includeChildren = $false
            }
        )
        Set-AdoTeamFieldValue -ProjectId 'e2egov-fantastic-four' -TeamId 'Mister Fantastic' -DefaultValue $defaultValue -Values $values

        This example sets the team field value for the 'Mister Fantastic' team in the specified project.
    #>
    [CmdletBinding()]
    [OutputType([TeamFieldValuesPatch])]
    param (
        [Parameter(Mandatory)]
        [string]$ProjectId,

        [Parameter(Mandatory = $false)]
        [string]$TeamId,

        [Parameter (Mandatory)]
        [string]$DefaultValue,

        [Parameter(Mandatory)]
        [object[]]$Values,

        [Parameter(Mandatory = $false)]
        [Alias('api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command        : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  ProjectId    : {0}' -f $ProjectId)
        Write-Debug ('  TeamId       : {0}' -f $TeamId)
        Write-Debug ('  DefaultValue : {0}' -f $DefaultValue)
        Write-Debug ('  ValuesCount  : {0}' -f $Values.Count)
        Write-Debug ('  ApiVersion   : {0}' -f $ApiVersion)

        try {
            # Convert input to TeamFieldValuesPatch object
            $teamFieldValues = [TeamFieldValuesPatch]::new(
                $DefaultValue,
                ($Values | ForEach-Object {
                    if ([string]::IsNullOrWhiteSpace($_.value)) {
                        throw "The 'value' property is required."
                    }
                    if ($null -eq $_.includeChildren -or $_.includeChildren -isnot [bool]) {
                        throw "The 'includeChildren' property must be of type bool and cannot be null."
                    }
                    [TeamFieldValue]::new(
                        $_.value,
                        $_.includeChildren
                    )
                })
            )
        } catch {
            throw $_
        }
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $global:AzDevOpsIsConnected) {
                throw 'Not connected to Azure DevOps. Please connect using Connect-AdoOrganization.'
            }

            $uriFormat = '{0}/{1}/{2}/_apis/work/teamsettings/teamfieldvalues?api-version={3}'
            $azDevOpsUri = ($uriFormat -f [uri]::new($global:AzDevOpsOrganization), [uri]::EscapeUriString($ProjectId),
                [uri]::EscapeUriString($TeamId), $ApiVersion)

            $params = @{
                Method      = 'PATCH'
                Uri         = $azDevOpsUri
                ContentType = 'application/json'
                Headers     = ((ConvertFrom-SecureString -SecureString $global:AzDevOpsHeaders -AsPlainText) | ConvertFrom-Json -AsHashtable)
                Body        = ($teamFieldValues | ConvertTo-Json -Depth 3)
            }

            $response = Invoke-RestMethod @params -Verbose:$VerbosePreference

            return $response

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
