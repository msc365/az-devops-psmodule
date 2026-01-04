function New-AdoCheckBusinessHours {
    <#
    .SYNOPSIS
        Create a new business hours check for a specific resource.

    .DESCRIPTION
        This function creates a new business hours check for a specified resource within an Azure DevOps project.
        When existing configuration is found, it will be returned instead of creating a new one.

    .PARAMETER CollectionUri
        Optional. The collection URI of the Azure DevOps collection/organization, e.g., https://dev.azure.com/my-org.

    .PARAMETER ProjectName
        Optional. The name or id of the project.

    .PARAMETER DisplayName
        Optional. The name of the business hours check. Default is 'Business Hours'.

    .PARAMETER ResourceType
        Mandatory. The type of resource to which the check will be applied. Valid values are 'endpoint', 'environment', 'variablegroup', 'repository'.

    .PARAMETER ResourceName
        Mandatory. The name of the resource to which the check will be applied.

    .PARAMETER BusinessDays
        Optional. An array of business days. Valid values are 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'.
        Default is Monday to Friday.

    .PARAMETER TimeZone
        Optional. The time zone for the business hours as Windows Standard Time Zone IDs. Default is 'UTC'.

        To see the list of valid time zone IDs, run the following command:
        [System.TimeZoneInfo]::GetSystemTimeZones() | Select-Object -ExpandProperty Id | Out-String

    .PARAMETER StartTime
        Optional. The start time for business hours in HH:mm format. Default is '04:00'.

    .PARAMETER EndTime
        Optional. The end time for business hours in HH:mm format. Default is '11:00'.

    .PARAMETER Timeout
        Optional. The timeout in minutes for the approval check. Default is 1440 (1 day).

    .PARAMETER Version
        Optional. The API version to use for the request. Default is '7.2-preview.1'.
        The -preview flag must be supplied in the api-version for such requests.

    .LINK
        https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/add

    .EXAMPLE
        $params = @{
            CollectionUri = 'https://dev.azure.com/my-org'
            ProjectName   = 'my-project-1'
            DisplayName   = 'Business Hours'
            ResourceType  = 'environment'
            ResourceName  = 'my-environment-tst'
            BusinessDays  = @('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
            TimeZone      = 'UTC'
            StartTime     = '04:00'
            EndTime       = '11:00'
            Timeout       = 1440
        }
        New-AdoCheckBusinessHours @params

        Creates a new business hours check in the specified project using the provided parameters.
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', 'New-AdoCheckBusinessHours')]
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Confirm-CollectionUri -Uri $_ })]
        [string]$CollectionUri = $env:DefaultAdoCollectionUri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [string]$ProjectName = $env:DefaultAdoProject,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$DisplayName = 'Business Hours',

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('endpoint', 'environment', 'variablegroup', 'repository')]
        [string]$ResourceType,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]$ResourceName,

        [Parameter()]
        [ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]
        [string[]]$BusinessDays = @('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'),

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet(
            'Afghanistan Standard Time',
            'Alaskan Standard Time',
            'Aleutian Standard Time',
            'Altai Standard Time',
            'Arab Standard Time',
            'Arabian Standard Time',
            'Arabic Standard Time',
            'Argentina Standard Time',
            'Astrakhan Standard Time',
            'Atlantic Standard Time',
            'AUS Central Standard Time',
            'AUS Eastern Standard Time',
            'Aus Central W. Standard Time',
            'AUS Central Standard Time',
            'Azerbaijan Standard Time',
            'Azores Standard Time',
            'Bahia Standard Time',
            'Bangladesh Standard Time',
            'Belarus Standard Time',
            'Bougainville Standard Time',
            'Canada Central Standard Time',
            'Cape Verde Standard Time',
            'Caucasus Standard Time',
            'Cen. Australia Standard Time',
            'Central America Standard Time',
            'Central Asia Standard Time',
            'Central Brazilian Standard Time',
            'Central Europe Standard Time',
            'Central European Standard Time',
            'Central Pacific Standard Time',
            'Central Standard Time',
            'Central Standard Time (Mexico)',
            'Chatham Islands Standard Time',
            'China Standard Time',
            'Cuba Standard Time',
            'Dateline Standard Time',
            'E. Africa Standard Time',
            'E. Australia Standard Time',
            'E. Europe Standard Time',
            'E. South America Standard Time',
            'Easter Island Standard Time',
            'Eastern Standard Time',
            'Eastern Standard Time (Mexico)',
            'Egypt Standard Time',
            'Ekaterinburg Standard Time',
            'Fiji Standard Time',
            'FLE Standard Time',
            'Georgian Standard Time',
            'GMT Standard Time',
            'Greenland Standard Time',
            'Greenwich Standard Time',
            'GTB Standard Time',
            'Haiti Standard Time',
            'Hawaiian Standard Time',
            'India Standard Time',
            'Iran Standard Time',
            'Israel Standard Time',
            'Jordan Standard Time',
            'Kaliningrad Standard Time',
            'Kamchatka Standard Time',
            'Korea Standard Time',
            'Libya Standard Time',
            'Line Islands Standard Time',
            'Lord Howe Standard Time',
            'Magadan Standard Time',
            'Magallanes Standard Time',
            'Marquesas Standard Time',
            'Mauritius Standard Time',
            'Mid-Atlantic Standard Time',
            'Middle East Standard Time',
            'Montevideo Standard Time',
            'Morocco Standard Time',
            'Mountain Standard Time',
            'Mountain Standard Time (Mexico)',
            'Myanmar Standard Time',
            'N. Central Asia Standard Time',
            'Namibia Standard Time',
            'Nepal Standard Time',
            'New Zealand Standard Time',
            'Newfoundland Standard Time',
            'Norfolk Standard Time',
            'North Asia East Standard Time',
            'North Asia Standard Time',
            'North Korea Standard Time',
            'Omsk Standard Time',
            'Pacific SA Standard Time',
            'Pacific Standard Time',
            'Pacific Standard Time (Mexico)',
            'Pakistan Standard Time',
            'Paraguay Standard Time',
            'Qyzylorda Standard Time',
            'Romance Standard Time',
            'Russia Time Zone 10',
            'Russia Time Zone 11',
            'Russia Time Zone 3',
            'Russian Standard Time',
            'SA Eastern Standard Time',
            'SA Pacific Standard Time',
            'SA Western Standard Time',
            'Saint Pierre Standard Time',
            'Sakhalin Standard Time',
            'Samoa Standard Time',
            'Sao Tome Standard Time',
            'Saratov Standard Time',
            'SE Asia Standard Time',
            'Singapore Standard Time',
            'South Africa Standard Time',
            'South Sudan Standard Time',
            'Sri Lanka Standard Time',
            'Sudan Standard Time',
            'Syria Standard Time',
            'Taipei Standard Time',
            'Tasmania Standard Time',
            'Tocantins Standard Time',
            'Tokyo Standard Time',
            'Tomsk Standard Time',
            'Tonga Standard Time',
            'Transbaikal Standard Time',
            'Turkey Standard Time',
            'Turks And Caicos Standard Time',
            'Ulaanbaatar Standard Time',
            'US Eastern Standard Time',
            'US Mountain Standard Time',
            'UTC',
            'UTC+12',
            'UTC+13',
            'UTC-02',
            'UTC-08',
            'UTC-09',
            'UTC-11',
            'Venezuela Standard Time',
            'Vladivostok Standard Time',
            'Volgograd Standard Time',
            'W. Australia Standard Time',
            'W. Central Africa Standard Time',
            'W. Europe Standard Time',
            'W. Mongolia Standard Time',
            'West Asia Standard Time',
            'West Bank Standard Time',
            'West Pacific Standard Time',
            'Yakutsk Standard Time',
            'Yukon Standard Time'
        )]
        [string]$TimeZone = 'UTC',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$StartTime = '04:00',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$EndTime = '11:00',

        [Parameter()]
        [int]$Timeout = 1440, # 1 day

        [Parameter(HelpMessage = 'The -preview flag must be supplied in the api-version for such requests.')]
        [Alias('ApiVersion')]
        [ValidateSet('7.1-preview.1', '7.2-preview.1')]
        [string]$Version = '7.2-preview.1'
    )

    begin {
        Write-Verbose ("Command: $($MyInvocation.MyCommand.Name)")
        Write-Debug ("CollectionUri: $CollectionUri")
        Write-Debug ("ProjectName: $ProjectName")
        Write-Debug ("DisplayName: $DisplayName")
        Write-Debug ("ResourceType: $ResourceType")
        Write-Debug ("ResourceName: $ResourceName")
        Write-Debug ("BusinessDays: $BusinessDays")
        Write-Debug ("TimeZone: $TimeZone")
        Write-Debug ("StartTime: $StartTime")
        Write-Debug ("EndTime: $EndTime")
        Write-Debug ("Timeout: $Timeout")
        Write-Debug ("ApiVersion: $Version")

        Confirm-Default -Defaults ([ordered]@{
                'CollectionUri' = $CollectionUri
                'ProjectName'   = $ProjectName
            })
    }

    process {
        try {
            $params = @{
                Uri     = "$CollectionUri/$ProjectName/_apis/pipelines/checks/configurations"
                Version = $Version
                Method  = 'POST'
            }

            # Get resource ID
            switch ($ResourceType) {
                'environment' {
                    $typeParams = @{
                        CollectionUri = $CollectionUri
                        ProjectName   = $ProjectName
                        Name          = $ResourceName
                    }
                    $resourceId = (Get-AdoEnvironment @typeParams).Id
                }
                default {
                    throw "ResourceType '$ResourceType' is not supported yet."
                }
            }

            # Create configuration JSON
            $body = @{
                type     = @{
                    name = 'Task Check'
                    id   = 'fe1de3ee-a436-41b4-bb20-f6eb4cb879a7'
                }
                settings = @{
                    displayName   = $DisplayName
                    definitionRef = @{
                        id      = '445fde2f-6c39-441c-807f-8a59ff2e075f'
                        name    = 'evaluateBusinessHours'
                        version = '0.0.1'
                    }
                    inputs        = @{
                        businessDays = $BusinessDays -join ','
                        timeZone     = $TimeZone
                        startTime    = $StartTime
                        endTime      = $EndTime
                    }
                    retryInterval = 5
                }
                timeout  = $Timeout
                resource = @{
                    type = $ResourceType
                    id   = $resourceId
                }
            }

            if ($PSCmdlet.ShouldProcess($ProjectName, "Create $($DisplayName) for: $ResourceName")) {
                try {
                    # Check if configuration already exists with the same inputs
                    $exists = [PSCustomObject]@{
                        ResourceType = $ResourceType
                        ResourceName = $ResourceName
                        Expands      = 'settings'
                    } | Get-AdoCheckConfiguration

                    $exists = $exists | Where-Object {
                        $_.settings.definitionRef.id -eq '445fde2f-6c39-441c-807f-8a59ff2e075f' -and
                        $_.settings.inputs.businessDays -eq ($BusinessDays -join ',') -and
                        $_.settings.inputs.timeZone -eq $TimeZone -and
                        $_.settings.inputs.startTime -eq $StartTime -and
                        $_.settings.inputs.endTime -eq $EndTime
                    }

                    if (-not $exists) {
                        $results = $body | Invoke-AdoRestMethod @params

                        $obj = [ordered]@{
                            id = $results.id
                        }
                        if ($results.settings) {
                            $obj['settings'] = $results.settings
                        }
                        $obj['timeout'] = $results.timeout
                        $obj['type'] = $results.type
                        $obj['resource'] = $results.resource
                        $obj['createdBy'] = $results.createdBy.id
                        $obj['createdOn'] = $results.createdOn
                        $obj['project'] = $ProjectName
                        $obj['collectionUri'] = $CollectionUri
                        [PSCustomObject]$obj

                    } else {
                        Write-Warning "$DisplayName already exists for $ResourceType with $ResourceName, returning existing one"

                        $obj = [ordered]@{
                            id = $exists.id
                        }
                        if ($exists.settings) {
                            $obj['settings'] = $exists.settings
                        }
                        $obj['timeout'] = $exists.timeout
                        $obj['type'] = $exists.type
                        $obj['resource'] = $exists.resource
                        $obj['createdBy'] = $exists.createdBy.id
                        $obj['createdOn'] = $exists.createdOn
                        $obj['project'] = $ProjectName
                        $obj['collectionUri'] = $CollectionUri
                        [PSCustomObject]$obj
                    }
                } catch {
                    throw $_
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
