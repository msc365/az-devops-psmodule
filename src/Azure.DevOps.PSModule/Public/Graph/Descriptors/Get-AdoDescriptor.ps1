function Get-AdoDescriptor {
    <#
    .SYNOPSIS
        Resolve a storage key to a descriptor.

    .DESCRIPTION
        This function resolves a storage key to a descriptor through REST API.

    .PARAMETER StorageKey
        Mandatory. Storage key (uuid) of the subject (user, group, scope, etc.) to resolve.

    .PARAMETER ApiVersion
        Optional. The API version to use. Default is '7.1'.

    .OUTPUTS
        PSCustomObject

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/descriptors/get

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            StorageKey    = '00000000-0000-0000-0000-000000000001'
        }
        Get-AdoDescriptor

        Resolves the specified storage key to its corresponding descriptor.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        @(
            '00000000-0000-0000-0000-000000000001',
            '00000000-0000-0000-0000-000000000002'
        ) | Get-AdoDescriptor @params

        Resolves multiple storage keys to their corresponding descriptors, demonstrating pipeline input.
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]$StorageKey,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("StorageKey: $($StorageKey -join ',')")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })

        if ($CollectionUri -notmatch 'vssps\.') {
            $CollectionUri = $CollectionUri -replace 'https://', 'https://vssps.'
        }
    }

    process {
        try {
            $params = @{
                Uri     = "$CollectionUri/_apis/graph/descriptors/$StorageKey"
                Version = $Version
                Method  = 'GET'
            }

            try {
                $result = (Invoke-AdoRestMethod @params).value

                if ($null -ne $result) {
                    [PSCustomObject]@{
                        storageKey    = $StorageKey
                        value         = $result
                        collectionUri = $CollectionUri
                    }
                }
            } catch {
                if ($_.ErrorDetails.Message -match 'NotFoundException') {
                    Write-Warning "StorageKey with ID $StorageKey does not exist in $CollectionUri, skipping."
                } else {
                    throw $_
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
