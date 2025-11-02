function Connect-AdoOrganization {
    <#
    .SYNOPSIS
        Connect to an Azure DevOps organization.

    .DESCRIPTION
        This function connects to an Azure DevOps organization using a personal access token (PAT) or a service principal when no PAT is provided.

    .PARAMETER Organization
        Mandatory. The name of the Azure DevOps organization.

    .PARAMETER PersonalAccessToken
        Optional. The personal access token (PAT) to use for the authentication. If not provided, the token is retrieved using Get-Token.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        System.String

        A message indicating the connection status.

    .EXAMPLE
        Connect-AdoOrganization -Organization 'my-org'

        Connects to the specified Azure DevOps organization using a service principal.

    .EXAMPLE
        Connect-AdoOrganization -Organization 'my-org' -PersonalAccessToken $PAT

        Connects to the specified Azure DevOps organization using the provided personal access token (PAT).

    .NOTES
        This function requires the Az.Accounts cmdlet.
    #>
    [CmdletBinding()]
    [OutputType([String])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Converting Azure API token response to SecureString for secure handling')]
    param (
        [Parameter(Mandatory)]
        [Alias('Org')]
        [string]$Organization,

        [Parameter(Mandatory = $false)]
        [Alias('PAT')]
        [securestring]$PersonalAccessToken,

        [Parameter(Mandatory = $false)]
        [Alias('Api')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$ApiVersion = '7.1'
    )

    begin {
        Write-Debug ('Command        : {0}' -f $MyInvocation.MyCommand.Name)
        Write-Debug ('  Organization : {0}' -f $Organization)
        Write-Debug ('  ApiVersion   : {0}' -f $ApiVersion)
    }

    process {
        try {
            $ErrorActionPreference = 'Stop'

            $org = ('https://dev.azure.com/{0}' -f $Organization)

            if ($null -ne $PersonalAccessToken) {
                $headers = @{
                    'Accept'        = 'application/json'
                    'Authorization' = ('Basic {0}' -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)")))
                }
            } else {
                $token = Get-AdoAccessToken
                $headers = @{
                    'Accept'        = 'application/json'
                    'Authorization' = ('Bearer {0}' -f (ConvertFrom-SecureString -SecureString $token -AsPlainText))
                }
            }

            $uriFormat = '{0}/_apis/projects?api-version={1}'
            $uri = ($uriFormat -f [uri]::new($org), $ApiVersion)

            $params = @{
                Method  = 'GET'
                Uri     = $uri
                Headers = $headers
            }

            $response = Invoke-RestMethod @params -Verbose:$VerbosePreference

            if ($response.GetType().Name -ne 'PSCustomObject') {
                throw 'Failed to connect to the Azure DevOps organization.'
            }

            $secureHeaders = ($headers |
                    ConvertTo-Json -Depth 5 -Compress |
                    ConvertTo-SecureString -AsPlainText -Force)

            Set-Variable -Name 'AzDevOpsIsConnected' -Value $true -Scope Global;
            Set-Variable -Name 'AzDevOpsOrganization' -Value $org -Scope Global;
            Set-Variable -Name 'AzDevOpsHeaders' -Value $secureHeaders -Scope Global;

            return ('Connected to {0}' -f $AzDevOpsOrganization)

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
    }
}
