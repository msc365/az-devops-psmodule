function Get-AdoDescriptor {
    <#
    .SYNOPSIS
        Resolve a storage key to a descriptor.

    .DESCRIPTION
        This function resolves a storage key to a descriptor through REST API.

    .PARAMETER StorageKey
        Mandatory. Storage key (uuid) of the subject (user, group, scope, etc.) to resolve.

    .PARAMETER ApiVersion
        Optional. The API version to use.

    .OUTPUTS
        PSCustomObject

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/descriptors/get

    .EXAMPLE
        Get-AdoDescriptor -StorageKey '00000000-0000-0000-0000-000000000000'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$CollectionUri = ($env:DefaultAdoCollectionUri -replace 'https://', 'https://vssps.'),

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]]$StorageKey,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("StorageKey: $($StorageKey -join ',')")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })
    }

    process {
        try {
            foreach ($key in $StorageKey) {

                $params = @{
                    Uri     = "$CollectionUri/_apis/graph/descriptors/$key"
                    Version = $Version
                    Method  = 'GET'
                }

                if ($PSCmdlet.ShouldProcess($CollectionUri, "Get Descriptor(s) for: $key")) {

                    $value = (Invoke-AdoRestMethod @params).value

                    if ($null -ne $value) {
                        [PSCustomObject]@{
                            storageKey    = $key
                            value         = $value
                            collectionUri = $CollectionUri
                        }
                    }

                } else {
                    Write-Verbose "Calling Invoke-AdoRestMethod with $($params| ConvertTo-Json -Depth 10)"
                }
            }

        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
