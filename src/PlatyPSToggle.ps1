<#
.SYNOPSIS
    Toggle YAML front matter between commented and uncommented format in documentation files.

.DESCRIPTION
    This script processes all markdown files in the docs folder and toggles the YAML front matter
    between HTML comment format (<!-- ... -->) and standard YAML format (--- ... ---).

    It can automatically detect the current state and toggle it, or you can force a specific action.

.PARAMETER DocsPath
    Path to the docs folder containing markdown files. Defaults to ..\docs relative to script location.

.PARAMETER Action
    Specify the action to perform:
    - 'Toggle' (default): Automatically detect current state and switch
    - 'Comment': Force commenting all front matter (convert --- to <!--)
    - 'Uncomment': Force uncommenting all front matter (convert <!-- to ---)

.EXAMPLE
    .\src\PlatyPSToggle.ps1

    Automatically detects current state and toggles all documentation files.

.EXAMPLE
    .\src\PlatyPSToggle.ps1 -Action Comment

    Forces all front matter to be commented (HTML comment format).

.EXAMPLE
    .\src\PlatyPSToggle.ps1 -Action Uncomment

    Forces all front matter to be uncommented (YAML format).

.EXAMPLE
    .\src\PlatyPSToggle.ps1 -DocsPath "C:\MyProject\docs"

    Toggles front matter in a custom docs folder location.

.NOTES
    Author: Azure DevOps PSModule Team
    Version: 1.0.0

    The script preserves all content and only modifies the front matter delimiters.
    Commented format is useful for PlatyPS processing, while uncommented format
    displays better on GitHub.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is used for internal user feedback in this script.')]
[CmdletBinding()]
param (
    [Parameter()]
    [string]$DocsPath = (Join-Path $PSScriptRoot '..\docs'),

    [Parameter()]
    [ValidateSet('Toggle', 'Comment', 'Uncomment')]
    [string]$Action = 'Toggle'
)

function Test-FrontMatterState {
    <#
    .SYNOPSIS
        Detects if a file has commented or uncommented front matter.
    #>
    param (
        [string]$FilePath
    )

    $firstLine = Get-Content $FilePath -TotalCount 1

    if ($firstLine -eq '---') {
        return 'Uncommented'
    } elseif ($firstLine -eq '<!--' -or $firstLine -eq '<!-- ') {
        return 'Commented'
    } else {
        return 'Unknown'
    }
}

function Convert-ToCommented {
    <#
    .SYNOPSIS
        Converts YAML front matter from --- format to <!-- --> format.
    #>
    param (
        [string]$FilePath
    )

    $lines = Get-Content $FilePath
    $newContent = @()
    $inFrontMatter = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Check if this is the start of YAML front matter
        if ($i -eq 0 -and $line -eq '---') {
            $newContent += '<!--'
            $inFrontMatter = $true
        }
        # Check if this is the end of front matter
        elseif ($inFrontMatter -and $line -eq '---') {
            $newContent += '-->'
            $inFrontMatter = $false
        }
        # Copy front matter content as-is
        elseif ($inFrontMatter) {
            $newContent += $line
        }
        # Copy all other lines
        else {
            $newContent += $line
        }
    }

    $newContent | Set-Content -Path $FilePath
}

function Convert-ToUncommented {
    <#
    .SYNOPSIS
        Converts YAML front matter from <!-- --> format to --- format.
    #>
    param (
        [string]$FilePath
    )

    $lines = Get-Content $FilePath
    $newContent = @()
    $inFrontMatter = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Check if this is the start of commented front matter
        if ($i -eq 0 -and ($line -eq '<!--' -or $line -eq '<!-- ')) {
            $newContent += '---'
            $inFrontMatter = $true
        }
        # Check if this is the end of front matter
        elseif ($inFrontMatter -and $line -eq '-->') {
            $newContent += '---'
            $inFrontMatter = $false
        }
        # Copy front matter content as-is
        elseif ($inFrontMatter) {
            $newContent += $line
        }
        # Copy all other lines
        else {
            $newContent += $line
        }
    }

    $newContent | Set-Content -Path $FilePath
}

# Main script execution
try {
    # Validate docs path exists
    if (-not (Test-Path $DocsPath)) {
        throw "Docs path not found: $DocsPath"
    }

    # Get all markdown files
    $mdFiles = Get-ChildItem -Path $DocsPath -Filter '*.md'

    if ($mdFiles.Count -eq 0) {
        Write-Warning "No markdown files found in: $DocsPath"
        return
    }

    Write-Host "Found $($mdFiles.Count) markdown files in: $DocsPath" -ForegroundColor Cyan
    Write-Host ''

    # Determine action if Toggle is specified
    if ($Action -eq 'Toggle') {
        # Check first file to determine current state
        $firstFileState = Test-FrontMatterState -FilePath $mdFiles[0].FullName

        if ($firstFileState -eq 'Uncommented') {
            $Action = 'Comment'
            Write-Host 'Detected uncommented front matter. Will COMMENT all files.' -ForegroundColor Yellow
        } elseif ($firstFileState -eq 'Commented') {
            $Action = 'Uncomment'
            Write-Host 'Detected commented front matter. Will UNCOMMENT all files.' -ForegroundColor Yellow
        } else {
            Write-Warning 'Could not detect front matter state in first file. Defaulting to Uncomment.'
            $Action = 'Uncomment'
        }
        Write-Host ''
    }

    # Process each file
    $successCount = 0
    $errorCount = 0

    foreach ($file in $mdFiles) {
        try {
            if ($Action -eq 'Comment') {
                Convert-ToCommented -FilePath $file.FullName
                Write-Host "✓ Commented: $($file.Name)" -ForegroundColor Green
            } else {
                Convert-ToUncommented -FilePath $file.FullName
                Write-Host "✓ Uncommented: $($file.Name)" -ForegroundColor Green
            }
            $successCount++
        } catch {
            Write-Error "✗ Failed to process $($file.Name): $_"
            $errorCount++
        }
    }

    Write-Host ''
    Write-Host 'Processing complete!' -ForegroundColor Cyan
    Write-Host "Success: $successCount | Errors: $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { 'Green' } else { 'Yellow' })
} catch {
    Write-Error "Script execution failed: $_"
    exit 1
}
