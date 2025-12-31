function New-AdoGroup {
    <#
    .SYNOPSIS
        Adds an AAD Group as member of a group.

    .DESCRIPTION
        This cmdlet adds an AAD Group as member of a group in Azure DevOps.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://vssps.dev.azure.com/myorganization.

    .PARAMETER GroupDescriptor
        Mandatory. A comma separated list of descriptors referencing groups you want the graph group to join.

    .PARAMETER GroupId
        Mandatory. The OriginId of the entra group to add as a member.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/groups/create

    .EXAMPLE
        $params = @{
            CollectionUri   = 'https://vssps.dev.azure.com/my-org'
            GroupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000000'
            GroupId         = '00000000-0000-0000-0000-000000000000'
        }
        New-AdoGroup @params

        Adds an AAD Group as member of a group.

    .EXAMPLE
        $params = @{
            CollectionUri   = 'https://vssps.dev.azure.com/my-org'
            GroupDescriptor = 'vssgp.00000000-0000-0000-0000-000000000000'
        }
        @('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002') | New-AdoGroup @params

        Adds multiple AAD Groups as members demonstrating pipeline input.
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
        [Alias('OriginId')]
        [string[]]$GroupId,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.2-preview.1')]
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

            foreach ($id in $GroupId) {

                $body = [PSCustomObject]@{
                    originId = $id
                }

                if ($PSCmdlet.ShouldProcess($CollectionUri, "Add group with OriginId: $id to descriptor: $GroupDescriptor")) {
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
                        if ($_ -match 'already exists') {
                            Write-Warning "Group with OriginId $id already exists in descriptor $GroupDescriptor"
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
            }

        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
