function Invoke-AdoRestMethod {
    <#
    .SYNOPSIS
        Invokes a REST method against the Azure DevOps Services REST API.

    .DESCRIPTION
        This is a helper function that invokes a REST method against the Azure DevOps Services REST API.
        It handles authentication and error handling.

    .PARAMETER Uri
        The URI of the Azure DevOps Services REST API endpoint.

    .PARAMETER Version
        The API version to use.

    .PARAMETER QueryParameters
        The query parameters to include in the request.

    .PARAMETER Method
        The HTTP method to use (GET, POST, PATCH, DELETE).

    .PARAMETER Body
        The body of the request (for POST and PATCH methods).

    .PARAMETER ContentType
        The content type of the request. Default is 'application/json'.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter(Mandatory)]
        [string]$Version,

        [Parameter()]
        [string]$QueryParameters,

        [Parameter(Mandatory)]
        [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')]
        [string]$Method,

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [PSCustomObject[]]$Body,

        [Parameter()]
        [ValidateSet('application/json', 'application/json-patch+json')]
        [string]$ContentType = 'application/json'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("  Uri: $Uri")
        Write-Debug ("  Method: $Method")
        Write-Debug ("  Body: $($Body | ConvertTo-Json -Depth 10)")

        if ($script:header.Authorization -match 'Bearer') {
            $params = @{
                Uri         = 'https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=6.0'
                Method      = 'GET'
                Headers     = $script:header
                ContentType = 'application/json'
            }
            try {
                $profileData = Invoke-RestMethod @params

                if (!$profileData.id) {
                    throw
                }
            } catch {
                Write-Verbose 'Refreshing authentication header'
                $script:header = $null
            }
        }
        if (-not($script:header)) {
            try {
                New-AdoAuthHeader -ErrorAction Stop
            } catch {
                throw $_
            }
        }

        $params = @{
            Method      = $Method
            Headers     = $script:header
            ContentType = $ContentType
        }

        if ($QueryParameters) {
            $params.Uri = "$($Uri)?$($QueryParameters)&api-version=$($Version)"
        } else {
            $params.Uri = "$($Uri)?api-version=$($Version)"
        }

        Write-Verbose "Uri: $($params.Uri)"
        Write-Verbose "Method: $($params.Method)"
    }

    process {
        try {
            if ($Method -eq 'POST' -or $Method -eq 'PUT' -or ($Method -eq 'PATCH')) {
                Write-Verbose "Body: $($Body | ConvertTo-Json -Depth 10)"
                $params.Body = $Body | ConvertTo-Json -Depth 10
            }
            if ($PSCmdlet.ShouldProcess($ProjectName, "Invoke Rest method on: $ProjectName")) {
                Invoke-RestMethod @params
            }
        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
