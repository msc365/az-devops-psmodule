function Remove-AdoServiceEndpoint {
    <#
    .SYNOPSIS
        Removes a service endpoint from Azure DevOps projects.

    .DESCRIPTION
        This cmdlet removes a service endpoint from one or more Azure DevOps projects.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER Id
        Mandatory. The unique identifier of the service endpoint to remove.

    .PARAMETER ProjectIds
        Mandatory. The project IDs from which the endpoint needs to be deleted.

    .PARAMETER Deep
        Optional. If specified, delete the service principal name (SPN) created by the endpoint.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/delete

    .EXAMPLE
        Remove-AdoServiceEndpoint -CollectionUri 'https://dev.azure.com/my-org' -Id $endpoint.id -ProjectId $project.id

        Removes the specified service endpoint from the given project.

    .EXAMPLE
        $endpoint | Remove-AdoServiceEndpoint -ProjectId '00000000-0000-0000-0000-000000000001'

        Removes a service endpoint by piping the endpoint object.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('EndpointId')]
        [string]$Id,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$ProjectIds,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$Deep,

        [Parameter()]
        [Alias('ApiVersion', 'Api')]
        [ValidateSet('7.1', '7.2-preview.4')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("Id: $Id")
        Write-Debug ("ProjectIds: $($ProjectIds -join ',')")
        Write-Debug ("Deep: $($Deep.IsPresent)")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })
    }

    process {
        try {
            $QueryParameters = [System.Collections.Generic.List[string]]::new()
            $QueryParameters.Add("projectIds=$($ProjectIds -join ',')")

            if ($Deep.IsPresent) {
                $QueryParameters.Add('deep=true')
            }

            $params = @{
                Uri             = "$CollectionUri/_apis/serviceendpoint/endpoints/$Id"
                Version         = $Version
                QueryParameters = if ($QueryParameters.Count -gt 0) { $QueryParameters -join '&' } else { $null }
                Method          = 'DELETE'
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, "Remove service endpoint: $Id from project(s) '$($ProjectIds -join ', ')'" )) {
                try {
                    Invoke-AdoRestMethod @params | Out-Null
                } catch {
                    if ($_.ErrorDetails.Message -match 'No service connection found') {
                        Write-Warning "Service endpoint with ID $Id does not exist, skipping."
                    } else {
                        throw $_
                    }
                }
            } else {
                Write-Verbose "Calling Invoke-AdoRestMethod with $($params | ConvertTo-Json -Depth 10)"
            }
        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
