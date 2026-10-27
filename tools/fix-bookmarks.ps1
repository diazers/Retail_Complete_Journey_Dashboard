# fix-bookmarks.ps1
# Removes the "preserveNewVisualVisibility" property from every *.bookmark.json
# in the project, because the bookmark schema Power BI Desktop validates against rejects it.
# Run with Power BI Desktop CLOSED. Safe to run repeatedly.
#
# Put this file in a "tools" folder at the root of the repo (next to the .pbip).
# Usage (PowerShell):  powershell -NoProfile -ExecutionPolicy Bypass -File tools\fix-bookmarks.ps1

$root  = Split-Path -Parent $PSScriptRoot
$noBom = New-Object System.Text.UTF8Encoding($false)
$fixed = 0

$files = Get-ChildItem $root -Recurse -File -Filter *.bookmark.json -ErrorAction SilentlyContinue
foreach ($f in $files) {
    $t = [IO.File]::ReadAllText($f.FullName)
    if ($t -notmatch 'preserveNewVisualVisibility') { continue }

    $n = $t
    # property after another property:   , "preserveNewVisualVisibility": true
    $n = $n -replace ',\s*"preserveNewVisualVisibility"\s*:\s*(true|false)', ''
    # property first, followed by others: "preserveNewVisualVisibility": true,
    $n = $n -replace '"preserveNewVisualVisibility"\s*:\s*(true|false)\s*,\s*', ''
    # property alone
    $n = $n -replace '"preserveNewVisualVisibility"\s*:\s*(true|false)', ''

    try   { $null = $n | ConvertFrom-Json }
    catch { Write-Warning "Skipped (result would not be valid JSON): $($f.FullName)"; continue }

    [IO.File]::WriteAllText($f.FullName, $n, $noBom)
    $fixed++
    Write-Host "Fixed: $($f.Name)"
}
Write-Host "Done. Files fixed: $fixed"
