<#
.SYNOPSIS
    Build script for PowerShell module.

.DESCRIPTION
    This script uses the PSake build automation tool to define tasks for building, testing,
    and publishing PowerShell modules. It includes tasks for cleaning the build directory,
    running unit tests, and packaging the module for release. The script also handles
    versioning and publishing to the PowerShell Gallery.

.NOTES
    Requires PSake module: Install-Module -Name PSake -Scope CurrentUser -Force
    Requires Pester module: Install-Module -Name Pester -Scope  CurrentUser -Force
#>

# // ----------------- //
# // Module properties //
# // ----------------- //

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', '', Justification = 'Write-Host is allowed to display tests status messages') ]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', 'Output', Justification = 'Output parameter is used in Properties block via $script:Output') ]
param(
    [Parameter()]
    [ValidateSet('Detailed', 'Diagnostic', 'Minimal', 'None', 'Normal')]
    [string]$Output = 'Normal'
)

Properties {
    # The output verbosity level for Pester tests.
    $script:Output = $Output
    # The name of the module being built.
    # $script:moduleName = 'Azure.DevOps.PSModule'

    # The current release version of the module.
    $script:buildVersion = [System.Version]'0.2.0'

    # Pre-release label (e.g. 'alpha1', 'beta1', 'rc1'). Set to $null for stable releases.
    $script:prerelease = 'alpha3'

    # The root path of the repository.
    $script:rootPath = (Get-Item $PSScriptRoot).Parent.FullName

    # The root path of the source files.
    $script:sourcePath = ('{0}\src' -f $script:rootPath)

    # The name of your module should match the basename of the PSD1 file.
    $validManifest = Get-Item -Path ('{0}\**\*.psd1' -f $script:sourcePath) |
        ForEach-Object {
            $null = Test-ModuleManifest -Path $_ -ErrorAction SilentlyContinue
            if ($?) { $_ }
        }

    if ($validManifest.Length -gt 0) {
        $script:moduleName = $validManifest[0].BaseName
    } else {
        throw ('No valid PowerShell module manifest (.psd1) found in {0}' -f $script:modulePath)
    }

    # The root path of the module to be built.
    $script:modulePath = Join-Path $script:sourcePath -ChildPath $script:moduleName

    # The directory used to publish the module from.
    $script:releasePath = Join-Path -Path $script:rootPath -ChildPath '.release'
    $script:releaseModulePath = Join-Path -Path $script:releasePath -ChildPath $script:moduleName

    # The path to the module manifest to be built.
    $script:moduleManifestPath = Join-Path -Path $script:modulePath -ChildPath ('{0}.psd1' -f $script:moduleName)

    # Repository to publish to, defaults to PSGallery
    $script:repository = 'PSGallery' # or 'LocalGallery'

    # API Key for PowerShell Gallery
    $script:apiKey = $env:PSGalleryApiKey

    # Skip automatic tags when publishing to the gallery
    $script:skipAutomaticTags = $true
}

# // ---------------------------- //
# // Publish task implementations //
# // ---------------------------- //

Task PrePublish {
    # Ask feedback before publishing
    $confirmation = Read-Host 'Are you sure you want to publish the module? (Y/N)'
    if ($confirmation -ne 'Y') {
        Write-Information 'Publishing aborted by user.' -InformationAction Continue
        exit 0
    }
}

Task PublishToGallery -RequiredVariables releaseModulePath, repository, apiKey {

    if (-not $script:apiKey) {
        throw 'API Key is required for publishing to PowerShell Gallery'
    }

    $publishParams = @{
        Path              = $script:releaseModulePath
        Repository        = $script:repository
        NuGetApiKey       = $script:apiKey
        SkipAutomaticTags = $script:skipAutomaticTags
    }

    try {
        Publish-Module @publishParams
    } catch {
        throw $_
    }
}

Task PostPublish {

    $findParams = @{
        Name       = $script:moduleName
        Repository = $script:repository
    }

    # Determine if the version is a prerelease
    if ($null -ne $script:prerelease) {
        $findParams['AllowPrerelease'] = $true
    }

    # Check if module is published
    $cmdlet = Find-Module @findParams -ErrorAction SilentlyContinue

    if ($null -ne $cmdlet) {
        # Verify the published version matches the built version
        $checkVersion = $null -eq $script:prerelease ? $script:buildVersion : ('{0}-{1}' -f $script:buildVersion, $script:prerelease)

        if ($cmdlet.Version -ne $checkVersion) {
            throw ('Published version {0} does not match built version {1}' -f $cmdlet.Version, $checkVersion)
        }
    }
}

# // ------------------------- //
# // Core task implementations //
# // ------------------------- //

Task default -Depends Build

Task Publish -Depends Test, PrePublish, PublishToGallery, PostPublish

Task Test -Depends Build -RequiredVariables Output {

    if ((Get-Module -Name PSScriptAnalyzer) -eq $null) {
        Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
    }

    Write-Host ("PSScriptAnalyzer {0}`n" -f (Get-Module -Name PSScriptAnalyzer).Version.ToString()) -ForegroundColor Magenta
    Write-Host 'Running script analyzer.' -ForegroundColor Magenta

    # Get all script files (e.g., .ps1, .psd1 and .psm1 files)
    $scriptCount = (Get-ChildItem -Path $script:sourcePath -Recurse -Include '*.ps1', '*.psd1', '*.psm1').Count

    # Run script analyzer on scripts
    $result = Invoke-ScriptAnalyzer -Path $script:sourcePath -Severity Warning

    Write-Output $result

    $errors = ($result | Where-Object Severity -EQ 'Error').Count
    $warnings = ($result | Where-Object Severity -EQ 'Warning').Count
    # $infos = ($result | Where-Object Severity -EQ 'Info').Count

    Write-Host "`nEvaluation completed."
    Write-Host "Evaluated: $($scriptCount), " -NoNewline -ForegroundColor Green
    Write-Host "Violations: $($result.Count), Errors: $($errors), Warnings: $($warnings)`n" -ForegroundColor DarkGray
    # Write-Host "Errors: $($errors), Warnings: $($warnings), Informative: $($infos)`n" -ForegroundColor DarkGray

    Import-Module Pester -PassThru | Out-Null

    $testPaths = (Get-ChildItem -Path $script:sourcePath -Recurse -Filter '*.Tests.ps1').FullName
    Invoke-Pester -Path $testPaths -Output $script:Output
}

Task Build -Depends Clean, Init -RequiredVariables sourcePath, releasePath, moduleName, buildVersion {

    # Copy the entire module directory to preserve structure
    Copy-Item -Path $script:modulePath -Destination $script:releasePath -Recurse -Force

    # Remove all tests folders from the copied module
    # Get-ChildItem -Path $script:releasePath -Recurse -Directory | Where-Object Name -EQ 'Tests' | ForEach-Object {
    #     Remove-Item -Path $_.FullName -Recurse -Force
    # }

    # Collect all public functions (exclude 'private' folders)
    ($functionsToExport = Get-ChildItem -Path $script:releaseModulePath -Recurse -Directory | Where-Object Name -NE 'Private' | ForEach-Object {
        Get-ChildItem -Path ($_.FullName + '\*.ps1') | Select-Object -ExpandProperty BaseName
    } | ForEach-Object { "$_" }) -join ',' | Out-Null

    # Update the module manifest with the new version and public functions
    $updateParams = @{
        Path              = (Join-Path -Path $script:releaseModulePath -ChildPath ('{0}.psd1' -f $script:moduleName))
        ModuleVersion     = $script:buildVersion
        FunctionsToExport = @($functionsToExport)
    }

    if ($null -ne $script:prerelease) {
        $updateParams['Prerelease'] = $script:prerelease
    }

    Update-PSModuleManifest @updateParams -ErrorAction Stop

    # Create an archive file
    Compress-Archive -Path $script:releaseModulePath -DestinationPath ('{0}.zip' -f $script:releaseModulePath) -ErrorAction Stop
}

Task Clean -RequiredVariables releasePath {
    # Sanity check the dir we are about to "clean".  If $releasePath were to
    # inadvertently get set to $null, the Remove-Item command removes the
    # contents of \*.  That's a bad day!
    if ((Test-Path $releasePath) -and $releasePath.Contains($rootPath)) {
        Remove-Item $releasePath -Recurse -Force
    }
}

Task Init -Depends Validate -RequiredVariables releasePath {
    if (!(Test-Path $releasePath)) {
        New-Item $releasePath -ItemType Directory | Out-Null
    }
}

Task Validate {
    Assert ($buildVersion -ne $null) 'buildVersion should not be null'
    Assert ($rootPath -ne $null) 'rootPath should not be null'
    Assert ($moduleName -ne $null) 'moduleName should not be null'
}
