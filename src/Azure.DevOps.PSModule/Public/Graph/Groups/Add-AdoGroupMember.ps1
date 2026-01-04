function Add-AdoGroupMember {
    <#
    .SYNOPSIS
        Adds an Entra ID group as member of a group.

    .DESCRIPTION
        This cmdlet adds an Entra ID group as member of a group in Azure DevOps.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://vssps.dev.azure.com/my-org.

    .PARAMETER GroupDescriptor
        Mandatory. The descriptor of the group to which the member will be added.

    .PARAMETER OriginId
        Mandatory. The OriginId of the Entra ID group to add as a member.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.
        The -preview flag must be supplied in the api-version for this request to work.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/create

    .EXAMPLE
        $params = @{
            CollectionUri   = 'https://vssps.dev.azure.com/my-org'
            GroupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
            OriginId        = '00000000-0000-0000-0000-000000000001'
        }
        Add-AdoGroupMember @params

        Adds an Entra ID group as member of a group.

    .EXAMPLE
        $params = @{
            CollectionUri   = 'https://vssps.dev.azure.com/my-org'
            GroupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
        }
        @(
            '00000000-0000-0000-0000-000000000001',
            '00000000-0000-0000-0000-000000000002'
        ) | Add-AdoGroupMember @params

        Adds multiple Entra ID groups as members demonstrating pipeline input.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = ($env:DefaultAdoCollectionUri -replace 'https://', 'https://vssps.'),

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Descriptor')]
        [string]$GroupDescriptor,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('Id', 'GroupId')]
        [string]$OriginId,

        [Parameter(HelpMessage = 'The -preview flag must be supplied in the api-version for this request to work.')]
        [Alias('ApiVersion')]
        [ValidateSet('7.1-preview.1', '7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("GroupDescriptor: $GroupDescriptor")
        Write-Debug ("GroupId: $($GroupId -join ',')")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })
    }

    process {
        try {
            $params = @{
                Uri             = "$CollectionUri/_apis/graph/groups"
                Version         = $Version
                QueryParameters = "groupDescriptors=$GroupDescriptor"
                Method          = 'POST'
            }

            $body = [PSCustomObject]@{
                originId = $OriginId
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, "Add group with OriginId: $OriginId to descriptor: $GroupDescriptor")) {
                try {
                    $result = $body | Invoke-AdoRestMethod @params

                    [PSCustomObject]@{
                        displayName   = $result.displayName
                        originId      = $result.originId
                        principalName = $result.principalName
                        origin        = $result.origin
                        subjectKind   = $result.subjectKind
                        descriptor    = $result.descriptor
                        collectionUri = $CollectionUri
                    }

                } catch {
                    if ($_.ErrorDetails.Message -match 'VS860016') {
                        Write-Warning "Could not find originId '$OriginId' in the backing domain, skipping."
                    } elseif ($_.ErrorDetails.Message -match 'TF50258' -or
                        $_.ErrorDetails.Message -match 'FindGroupSidDoesNotExist') {
                        Write-Warning "There is no group with the security identifier (SID) '$GroupDescriptor', skipping."
                    } else {
                        throw $_
                    }
                }
            } else {
                $params += @{
                    Body = $body
                }
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
