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

    .OUTPUTS
        [PSCustomObject]@{
            name = '<Definition Name>'
            id   = '<Definition ID>'
        }

        Representing the check definition reference with 'name' and 'id' properties.

    .EXAMPLE
        Resolve-AdoCheckConfigDefinitionRef -Name 'approval'

        Resolves the definition reference for the 'approval' check.

    .EXAMPLE
        Resolve-AdoCheckConfigDefinitionRef -Id '26014962-64a0-49f4-885b-4b874119a5cc'

        Resolves the definition reference for the check with the specified ID.

    .NOTES
        This function uses a static mapping of Azure DevOps check definition types.
        The IDs are fixed and defined by Azure DevOps.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
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
        [string]$Name
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")

        # Define all check definitions in a single source of truth
        $script:DefinitionReferences = @{
            # By Name (case-insensitive key)
            'approval'                             = [PSCustomObject]@{
                displayName = 'Approval'
                name        = 'approval'
                id          = '26014962-64a0-49f4-885b-4b874119a5cc'
            }
            'precheckapproval'                     = [PSCustomObject]@{
                displayName = 'Pre-check approval'
                name        = 'preCheckApproval'
                id          = '0f52a19b-c67e-468f-b8eb-0ae83b532c99'
            }
            'postcheckapproval'                    = [PSCustomObject]@{
                displayName = 'Post-check approval'
                name        = 'postCheckApproval'
                id          = '06441319-13fb-4756-b198-c2da116894a4'
            }
            'branchcontrol'                        = [PSCustomObject]@{
                displayName = 'Branch control'
                name        = 'branchControl'
                id          = '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'
            }
            'businesshours'                        = [PSCustomObject]@{
                displayName = 'Business hours'
                name        = 'businessHours'
                id          = '445fde2f-6c39-441c-807f-8a59ff2e075f'
            }
            # By ID
            '26014962-64a0-49f4-885b-4b874119a5cc' = [PSCustomObject]@{
                displayName = 'Approval'
                name        = 'approval'
                id          = '26014962-64a0-49f4-885b-4b874119a5cc'
            }
            '0f52a19b-c67e-468f-b8eb-0ae83b532c99' = [PSCustomObject]@{
                displayName = 'Pre-check approval'
                name        = 'preCheckApproval'
                id          = '0f52a19b-c67e-468f-b8eb-0ae83b532c99'
            }
            '06441319-13fb-4756-b198-c2da116894a4' = [PSCustomObject]@{
                displayName = 'Post-check approval'
                name        = 'postCheckApproval'
                id          = '06441319-13fb-4756-b198-c2da116894a4'
            }
            '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b' = [PSCustomObject]@{
                displayName = 'Branch control'
                name        = 'branchControl'
                id          = '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'
            }
            '445fde2f-6c39-441c-807f-8a59ff2e075f' = [PSCustomObject]@{
                displayName = 'Business hours'
                name        = 'businessHours'
                id          = '445fde2f-6c39-441c-807f-8a59ff2e075f'
            }
        }
    }

    process {
        $lookupKey = if ($PSCmdlet.ParameterSetName -eq 'ById') {
            $Id
        } else {
            $Name.ToLower()
        }

        Write-Verbose "Looking up definition reference by $($PSCmdlet.ParameterSetName): $lookupKey"

        if ($script:DefinitionReferences.ContainsKey($lookupKey)) {
            $definitionRef = $script:DefinitionReferences[$lookupKey]
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
