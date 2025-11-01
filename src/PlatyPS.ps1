<#
.SYNOPSIS
Generates markdown help files for the specified PowerShell module using PlatyPS.

.DESCRIPTION
This script generates markdown help files for a specified PowerShell module using the PlatyPS module.
It allows customization of various parameters such as module name, output folder, help version, and locale.

.PARAMETER ModuleName
The name of the PowerShell module for which to generate help files. Default is 'Azure.DevOps.PSModule'.

.PARAMETER ModuleFolder
The folder where the module is located. Default is '.\release\{ModuleName}'.

.PARAMETER HelpVersion
The version of the help files to generate. Default is '0.0.1'.

.PARAMETER Locale
The locale for the help files. Default is 'en-US'.

.PARAMETER WithModulePage
A switch indicating whether to include a module page in the generated help files. Default is $true.

.PARAMETER OutputFolder
The folder where the generated markdown help files will be saved. Default is '.\docs'.

.PARAMETER UpdateExisting
A switch indicating whether to update existing markdown help files. Default is $false.

.PARAMETER ParamName
A brief description of the parameter.

.OUTPUTS
None

.EXAMPLE
.\src\PlatyPS.ps1 -UpdateExisting

Generates markdown help files for the 'Azure.DevOps.PSModule' module and updates existing files if they exist.

.NOTES
Executing task: Invoke-PSake src/Build.ps1 -taskList Build, before PlatyPS

#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter()]
    [string]$ModuleName = 'Azure.DevOps.PSModule',

    [Parameter()]
    [string]$ModuleFolder = ('.\.release\{0}' -f $ModuleName),

    [Parameter()]
    [string]$HelpVersion = '0.0.1',

    [Parameter()]
    [string]$Locale = 'en-US',

    [Parameter()]
    [string]$OutputFolder = '.\docs',

    [Parameter()]
    [switch]$WithModulePage,

    [Parameter()]
    [switch]$UpdateExisting
)

begin {
    Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)
}

process {
    try {
        # Load the PlatyPS module
        Import-Module -Name 'Microsoft.PowerShell.PlatyPS' -ErrorAction Stop

        # Load the module to document
        Import-Module $ModuleFolder -ErrorAction Stop

        if ($UpdateExisting) {
            # Update existing markdown help files
            $mdfiles = Measure-PlatyPSMarkdown -Path ('{0}\*.md' -f $OutputFolder)
            $mdfiles | Where-Object Filetype -Match 'CommandHelp' |
                Update-MarkdownCommandHelp -Path { $_.FilePath }
        } else {
            # Create the markdown help files
            $mdHelpSplat = @{
                ModuleInfo     = Get-Module -Name $ModuleName
                OutputFolder   = $OutputFolder
                HelpVersion    = $HelpVersion
                WithModulePage = $WithModulePage
                Locale         = $Locale
                Encoding       = [System.Text.Encoding]::UTF8
            }

            New-MarkdownCommandHelp @mdHelpSplat
        }

    } catch {
        throw $_
    }
}

end {
    Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
}
