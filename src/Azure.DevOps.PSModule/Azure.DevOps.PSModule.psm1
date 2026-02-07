# Using statements
using namespace System.Collections.Generic

[CmdletBinding()]
param()

Write-Verbose $PSScriptRoot
Write-Verbose 'Import all modules in sub folders'

# First, load any class definitions from Private folder
# $classFiles = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Private') -Filter '*Classes.ps1' -ErrorAction SilentlyContinue
# if ($classFiles) {
#     Write-Verbose '  Loading class definitions first'
#     $classFiles | ForEach-Object {
#         Write-Verbose ('    {0}' -f $_.basename)
#         . $_.FullName
#     }
# }

# Then load all other files
foreach ($folder in @('Private', 'Public')) {
    $root = Join-Path -Path $PSScriptRoot -ChildPath $folder

    if (Test-Path -Path $root) {
        Write-Verbose ('  Processing folder {0}' -f $folder)
        $files = Get-ChildItem -Path $root -Filter *.ps1 -Recurse | Where-Object { $_.Name -notlike '*Classes.ps1' }

        # dot source each file
        $files | ForEach-Object { Write-Verbose ('    {0}' -f $_.basename); . $_.FullName }
    }
}
