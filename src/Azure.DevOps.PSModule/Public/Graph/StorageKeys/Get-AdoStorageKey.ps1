function Get-AdoStorageKey {
    <#
    .SYNOPSIS
        Resolve a descriptor to a storage key in an Azure DevOps organization.

    .DESCRIPTION
        This function resolve a descriptor to a storage key in an Azure DevOps organization through REST API.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://vssps.dev.azure.com/my-org.

    .PARAMETER SubjectDescriptor
        Mandatory. The descriptor of the Graph entity to resolve.

    .PARAMETER Version
        The API version to use. Default is '7.2-preview.1'.
        The -preview flag must be supplied in the api-version for this request to work.

    .OUTPUTS
        PSCustomObject

    .LINK
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/storage-keys/get

    .EXAMPLE
        Get-AdoStorageKey -SubjectDescriptor 'aad.00000000-0000-0000-0000-000000000000'

        Resolve a descriptor to a storage key using the default collection URI from environment variable.

    .EXAMPLE
        $params = @{
            CollectionUri     = 'https://dev.azure.com/my-org'
            SubjectDescriptor = 'aad.00000000-0000-0000-0000-000000000000'
        }
        Get-AdoStorageKey @params

        Resolve a descriptor to a storage key.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        @(
            'aad.00000000-0000-0000-0000-000000000001',
            'aad.00000000-0000-0000-0000-000000000002'
        ) | Get-AdoStorageKey @params

        Resolves multiple descriptors to their corresponding storage keys, demonstrating pipeline input.
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$SubjectDescriptor,

        [Parameter(HelpMessage = 'The -preview flag must be supplied in the api-version for this request to work.')]
        [Alias('ApiVersion')]
        [ValidateSet('7.1-preview.1', '7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("SubjectDescriptor: $SubjectDescriptor")
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
                Uri     = "$CollectionUri/_apis/graph/storagekeys/$SubjectDescriptor"
                Version = $Version
                Method  = 'GET'
            }

            try {
                $result = (Invoke-AdoRestMethod @params).value

                if ($null -ne $result) {
                    [PSCustomObject]@{
                        subjectDescriptor = $SubjectDescriptor
                        value             = $result
                        collectionUri     = $CollectionUri
                    }
                }
            } catch {
                if ($_.ErrorDetails.Message -match 'StorageKeyNotFoundException') {
                    Write-Warning "The storage key for descriptor $SubjectDescriptor could not be found, skipping."
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
