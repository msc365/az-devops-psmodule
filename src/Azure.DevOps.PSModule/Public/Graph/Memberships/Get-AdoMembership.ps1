function Get-AdoMembership {
    <#
    .SYNOPSIS
        Get membership relationships

    .DESCRIPTION
        This cmdlet retrieves the membership relationships between a specified subject and container in Azure DevOps or
        get all the memberships where this descriptor is a member in the relationship.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://vssps.dev.azure.com/my-org.

    .PARAMETER SubjectDescriptor
        Mandatory. A descriptor to the child subject in the relationship.

    .PARAMETER ContainerDescriptor
        Optional. A descriptor to the container in the relationship.

    .PARAMETER Depth
        Optional. The depth of memberships to retrieve when ContainerDescriptor is not specified. Default is 1.

    .PARAMETER Direction
        Optional. The direction of memberships to retrieve when ContainerDescriptor is not specified.

        The default value for direction is 'up' meaning return all memberships where the subject is a member (e.g. all groups the subject is a member of).
        Alternatively, passing the direction as 'down' will return all memberships where the subject is a container (e.g. all members of the subject group).

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1-preview.1'.

    .OUTPUTS
        PSCustomObject

    .LINK
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/memberships/get
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/memberships/list

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

    .EXAMPLE
        $params = @{
            CollectionUri     = 'https://vssps.dev.azure.com/my-org'
            SubjectDescriptor = 'aadgp.00000000-0000-0000-0000-000000000000'
            Depth             = 2
            Direction         = 'up'
        }
        Get-AdoMembership @params

        Retrieves all groups for a user with a depth of 2.

    .EXAMPLE
        $params = @{
            CollectionUri     = 'https://vssps.dev.azure.com/my-org'
            SubjectDescriptor = 'aadgp.00000000-0000-0000-0000-000000000000'
            Depth             = 2
            Direction         = 'down'
        }
        Get-AdoMembership @params

        Retrieves all memberships of a group with a depth of 2.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ListMemberships')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]]$SubjectDescriptor,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'GetMembership')]
        [string]$ContainerDescriptor,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ListMemberships')]
        [int32]$Depth,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ListMemberships')]
        [ValidateSet('up', 'down')]
        [string]$Direction,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1-preview.1', '7.2-preview.1')]
        [string]$Version = '7.1-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("SubjectDescriptor: $($SubjectDescriptor -join ',')")
        Write-Debug ("ContainerDescriptor: $ContainerDescriptor")
        Write-Debug ("Depth: $Depth")
        Write-Debug ("Direction: $Direction")
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
            $queryParameters = [List[string]]::new()

            if ($ContainerDescriptor) {
                $uri = "$CollectionUri/_apis/graph/memberships/$SubjectDescriptor/$ContainerDescriptor"
            } else {
                $uri = "$CollectionUri/_apis/graph/memberships/$SubjectDescriptor"

                if ($Depth) {
                    $queryParameters.Add("depth=$Depth")
                }
                if ($Direction) {
                    $queryParameters.Add("direction=$Direction")
                }
            }

            $params = @{
                Uri             = $uri
                Version         = $Version
                QueryParameters = if ($queryParameters.Count -gt 0) { $queryParameters -join '&' } else { $null }
                Method          = 'GET'
            }

            $results = Invoke-AdoRestMethod @params
            $memberships = if ($ContainerDescriptor) { @($results) } else { $results.value }

            foreach ($m_ in $memberships) {
                $obj = [ordered]@{
                    containerDescriptor = $m_.containerDescriptor
                    memberDescriptor    = $m_.memberDescriptor
                    collectionUri       = $CollectionUri
                }
                [PSCustomObject]$obj
            }

        } catch {
            throw $_
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
