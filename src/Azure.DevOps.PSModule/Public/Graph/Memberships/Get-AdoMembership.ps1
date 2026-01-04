function Get-AdoMembership {
    <#
    .SYNOPSIS
        Get the membership relationship between a subject and a container in Azure DevOps.

    .DESCRIPTION
        This cmdlet retrieves the membership relationship between a specified subject and container in Azure DevOps.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://vssps.dev.azure.com/my-org.

    .PARAMETER SubjectDescriptor
        Mandatory. A descriptor to the child subject in the relationship.

    .PARAMETER ContainerDescriptor
        Mandatory. A descriptor to the container in the relationship.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/memberships/get

    .EXAMPLE
        $params = @{
            CollectionUri       = 'https://vssps.dev.azure.com/my-org'
            SubjectDescriptor   = 'aadgp.00000000-0000-0000-0000-000000000000'
            ContainerDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
        }
        Get-AdoMembership @params

        Retrieves the membership relationship between the specified subject and container.

    .EXAMPLE
        $params = @{
            CollectionUri       = 'https://vssps.dev.azure.com/my-org'
            ContainerDescriptor = 'vssgp.00000000-0000-0000-0000-000000000001'
        }
        @('aadgp.00000000-0000-0000-0000-000000000002', 'aadgp.00000000-0000-0000-0000-000000000003') | Get-AdoMembership @params

        Retrieves the membership relationships for multiple subjects demonstrating pipeline input.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = ($env:DefaultAdoCollectionUri -replace 'https://', 'https://vssps.'),

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]]$SubjectDescriptor,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$ContainerDescriptor,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("SubjectDescriptor: $($SubjectDescriptor -join ',')")
        Write-Debug ("ContainerDescriptor: $ContainerDescriptor")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })
    }

    process {
        try {
            $params = @{
                Uri     = "$CollectionUri/_apis/graph/memberships/$SubjectDescriptor/$ContainerDescriptor"
                Version = $Version
                Method  = 'GET'
            }

            if ($PSCmdlet.ShouldProcess($CollectionUri, "Get Membership for subject: $SubjectDescriptor in container: $ContainerDescriptor")) {

                $result = Invoke-AdoRestMethod @params

                [PSCustomObject]@{
                    memberDescriptor    = $result.memberDescriptor
                    containerDescriptor = $result.containerDescriptor
                    collectionUri       = $CollectionUri
                }

            } else {
                Write-Verbose "Calling Invoke-AdoRestMethod with $($params| ConvertTo-Json -Depth 10)"
            }

        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
