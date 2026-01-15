function Get-AdoPolicyType {
    <#
    .SYNOPSIS
        Retrieves Azure DevOps policy type details.

    .DESCRIPTION
        This cmdlet retrieves details of one or more Azure DevOps policy types within a specified project.
        You can retrieve all policy types, or specific policy types by ID or name.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Mandatory. The ID or name of the project.

    .PARAMETER Id
        Optional. The ID (uuid) of the policy type to retrieve. If not provided, retrieves all policy types.

        The set of policy types is standard across Azure DevOps; projects don’t get different type catalogs, only different configurations.
        See the [branch policies](https://learn.microsoft.com/en-us/azure/devops/repos/git/branch-policies) overview.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/types/get
        - https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/types/list

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        Get-AdoPolicyType @params

        Retrieves all policy types from the specified project.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
        }
        Get-AdoPolicyType @params -Id '00000000-0000-0000-0000-000000000000'

        Retrieves the specified policy type from the project.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ListPolicyTypes')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter( ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'ByTypeId')]
        [Alias('TypeId', 'PolicyTypeId')]
        [ValidateSet (
            '0517f88d-4ec5-4343-9d26-9930ebd53069', # Git repository settings policy name
            'ec003f37-8db0-4e10-992a-a2895045752c', # Secrets scanning restriction
            '90f9629b-664b-4804-a560-dd79b0c628f8', # Secrets scanning restriction
            '001a79cf-fda1-4c4e-9e7c-bac40ee5ead8', # Path Length restriction
            '67ed70bd-2a6b-4006-af44-be590463f46d', # Proof of Presence
            'db2b9b4c-180d-4529-9701-01541d19f36b', # Reserved names restriction
            'fa4e907d-c16b-4a4c-9dfa-4916e5d171ab', # Require a merge strategy
            'c6a1889d-b943-4856-b76f-9e46bb6b0df2', # Comment requirements
            'cbdc66da-9728-4af8-aada-9a5a32e4a226', # Status
            '7ed39669-655c-494e-b4a0-a08b4da0fcce', # Git repository settings
            '0609b952-1397-4640-95ec-e00a01b2c241', # Build
            '2e26e725-8201-4edd-8bf5-978563c34a80', # File size restriction
            '51c78909-e838-41a2-9496-c647091e3c61', # File name restriction
            '77ed4bd3-b063-4689-934a-175e4d0a78d7', # Commit author email validation
            'fd2167ab-b0be-447a-8ec8-39368250530e', # Required reviewers
            'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd', # Minimum number of reviewers
            '40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e'  # Work item linking
        )]
        [string]$Id,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("Name: $Id")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            if ($Id) {
                $uri = "$CollectionUri/$ProjectName/_apis/policy/types/$Id"
            } else {
                $uri = "$CollectionUri/$ProjectName/_apis/policy/types"
            }

            $params = @{
                Uri     = $uri
                Version = $Version
                Method  = 'GET'
            }

            try {
                $results = Invoke-AdoRestMethod @params
                $items = if ($Id) { @($results) } else { $results.value }

                foreach ($i_ in $items) {
                    [PSCustomObject]@{
                        id            = $i_.id
                        displayName   = $i_.displayName
                        description   = $i_.description
                        projectName   = $ProjectName
                        collectionUri = $CollectionUri
                    }
                }
            } catch {
                if ($_.ErrorDetails.Message -match 'NotFoundException') {
                    Write-Warning "Policy type with ID $Id does not exist in project $ProjectName, skipping."
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
