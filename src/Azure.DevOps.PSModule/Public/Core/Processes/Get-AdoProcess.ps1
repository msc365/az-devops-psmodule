function Get-AdoProcess {
    <#
    .SYNOPSIS
        Retrieves Azure DevOps process details.

    .DESCRIPTION
        This cmdlet retrieves details of one or more Azure DevOps processes within a specified organization.
        You can retrieve all processes or a specific process by name.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER Name
        Optional. The name of the process to retrieve. If not provided, retrieves all processes.

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.1'.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/core/processes/list

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        Get-AdoProcess @params

        Retrieves all available processes from the specified organization.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        Get-AdoProcess @params -Name 'Agile'

        Retrieves the specified process by name.

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
        }
        @('Agile', 'Scrum') | Get-AdoProcess @params -Verbose

        Retrieves multiple processes by name demonstrating pipeline input.
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('Process', 'ProcessName')]
        [ValidateSet('Agile', 'Scrum', 'CMMI', 'Basic')]
        [string]$Name,

        [Parameter()]
        [Alias('ApiVersion')]
        [ValidateSet('7.1', '7.2-preview.1')]
        [string]$Version = '7.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("Name: $Name")
        Write-Debug ("Version: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
            })
    }

    process {
        try {
            $params = @{
                Uri     = "$CollectionUri/_apis/process/processes"
                Version = $Version
                Method  = 'GET'
            }

            $results = Invoke-AdoRestMethod @params
            $processes = $results.value

            if ($Name) {
                $processes = $processes | Where-Object { $_.name -eq $Name }
            }

            foreach ($p_ in $processes) {
                [PSCustomObject]@{
                    id            = $p_.id
                    name          = $p_.name
                    description   = $p_.description
                    url           = $p_.url
                    type          = $p_.type
                    isDefault     = $p_.isDefault
                    collectionUri = $CollectionUri
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
