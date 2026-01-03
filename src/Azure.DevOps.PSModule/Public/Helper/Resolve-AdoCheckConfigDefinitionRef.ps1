function Resolve-AdoCheckConfigDefinitionRef {
    <#
    .SYNOPSIS
        Resolve a check definition reference by its name or ID.

    .DESCRIPTION
        This function resolves a check definition reference in Azure DevOps by either its name or ID.
        It returns the corresponding definition reference object.

        Supported check definitions:
        - Approval (26014962-64a0-49f4-885b-4b874119a5cc)
        - PreCheckApproval (0f52a19b-c67e-468f-b8eb-0ae83b532c99)
        - PostCheckApproval (06441319-13fb-4756-b198-c2da116894a4)

    .PARAMETER Id
        The ID of the check definition reference to resolve.
        Valid values: '26014962-64a0-49f4-885b-4b874119a5cc', '0f52a19b-c67e-468f-b8eb-0ae83b532c99', '06441319-13fb-4756-b198-c2da116894a4'

    .PARAMETER Name
        The name of the check definition reference to resolve.
        Valid values: 'approval', 'preCheckApproval', 'postCheckApproval'
        Case-insensitive.

    .PARAMETER ListAll
        Returns all available check definition references.

    .OUTPUTS
        [PSCustomObject]@{
            name        = '<Definition Name>'
            id          = '<Definition ID>'
            displayName = '<Definition Display Name>'
        }

        Representing the check definition reference with 'name' and 'id' properties.
        When using -ListAll, returns an array of all definition reference objects.

    .EXAMPLE
        Resolve-AdoCheckConfigDefinitionRef -Name 'approval'

        Resolves the definition reference for the 'approval' check.

    .EXAMPLE
        Resolve-AdoCheckConfigDefinitionRef -Id '26014962-64a0-49f4-885b-4b874119a5cc'

        Resolves the definition reference for the check with the specified ID.

    .EXAMPLE
        Resolve-AdoCheckConfigDefinitionRef -ListAll

        Returns all available check definition references.

    .NOTES
        This function uses a static mapping of Azure DevOps check definition types.
        The IDs are fixed and defined by Azure DevOps.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([PSCustomObject])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ListAll', Justification = 'Parameter is used via $PSCmdlet.ParameterSetName')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ById')]
        [ValidateSet(
            '26014962-64a0-49f4-885b-4b874119a5cc', # Approval
            '0f52a19b-c67e-468f-b8eb-0ae83b532c99', # Pre-check approval
            '06441319-13fb-4756-b198-c2da116894a4', # Post-check approval
            '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b', # Branch control
            '445fde2f-6c39-441c-807f-8a59ff2e075f'  # Business hours
        )]
        [string]$Id,

        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [ValidateSet('approval', 'preCheckApproval', 'postCheckApproval', 'branchControl', 'businessHours')]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'ListAll')]
        [switch]$ListAll
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")

        # Define all check definitions in a single source of truth
        $DefinitionReferences = @{
            # By Name (case-insensitive key)
            'approval'                             = [PSCustomObject]@{
                name        = 'approval'
                id          = '26014962-64a0-49f4-885b-4b874119a5cc'
                displayName = 'Approval'
            }
            'precheckapproval'                     = [PSCustomObject]@{
                name        = 'preCheckApproval'
                id          = '0f52a19b-c67e-468f-b8eb-0ae83b532c99'
                displayName = 'Pre-check approval'
            }
            'postcheckapproval'                    = [PSCustomObject]@{
                name        = 'postCheckApproval'
                id          = '06441319-13fb-4756-b198-c2da116894a4'
                displayName = 'Post-check approval'
            }
            'branchcontrol'                        = [PSCustomObject]@{
                name        = 'branchControl'
                id          = '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'
                displayName = 'Branch control'
            }
            'businesshours'                        = [PSCustomObject]@{
                name        = 'businessHours'
                id          = '445fde2f-6c39-441c-807f-8a59ff2e075f'
                displayName = 'Business hours'
            }
            # By ID
            '26014962-64a0-49f4-885b-4b874119a5cc' = [PSCustomObject]@{
                name        = 'approval'
                id          = '26014962-64a0-49f4-885b-4b874119a5cc'
                displayName = 'Approval'
            }
            '0f52a19b-c67e-468f-b8eb-0ae83b532c99' = [PSCustomObject]@{
                name        = 'preCheckApproval'
                id          = '0f52a19b-c67e-468f-b8eb-0ae83b532c99'
                displayName = 'Pre-check approval'
            }
            '06441319-13fb-4756-b198-c2da116894a4' = [PSCustomObject]@{
                name        = 'postCheckApproval'
                id          = '06441319-13fb-4756-b198-c2da116894a4'
                displayName = 'Post-check approval'
            }
            '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b' = [PSCustomObject]@{
                name        = 'branchControl'
                id          = '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'
                displayName = 'Branch control'
            }
            '445fde2f-6c39-441c-807f-8a59ff2e075f' = [PSCustomObject]@{
                name        = 'businessHours'
                id          = '445fde2f-6c39-441c-807f-8a59ff2e075f'
                displayName = 'Business hours'
            }
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ListAll') {
            Write-Verbose 'Returning all definition references'

            # Get unique definitions by name (avoid duplicates from ID entries)
            $uniqueDefinitions = @($DefinitionReferences.Values |
                    Sort-Object -Property name -Unique)

            return $uniqueDefinitions
        }

        $lookupKey = if ($PSCmdlet.ParameterSetName -eq 'ById') {
            $Id
        } else {
            $Name.ToLower()
        }

        Write-Verbose "Looking up definition reference by $($PSCmdlet.ParameterSetName): $lookupKey"

        if ($DefinitionReferences.ContainsKey($lookupKey)) {
            $definitionRef = $DefinitionReferences[$lookupKey]
            Write-Verbose "Found definition: $($definitionRef.name) ($($definitionRef.id))"

            return $definitionRef
        } else {
            # This should never happen due to ValidateSet, but keeping as safeguard
            $errorMessage = if ($PSCmdlet.ParameterSetName -eq 'ById') {
                "Unknown DefinitionRef Id: $Id."
            } else {
                "Unknown DefinitionRef Name: $Name."
            }
            throw $errorMessage
        }
    }

    end {
        Write-Verbose ("Exit: $($MyInvocation.MyCommand.Name)")
    }
}
