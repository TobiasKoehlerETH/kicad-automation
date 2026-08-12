[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$HardwareRoot,

    [Parameter()]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'Custom-Footprints.pretty')
)

$ErrorActionPreference = 'Stop'

function Get-RelativePath {
    param(
        [Parameter(Mandatory)]
        [string]$BasePath,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $baseUri = [Uri]((Resolve-Path -LiteralPath $BasePath).Path.TrimEnd('\') + '\')
    $pathUri = [Uri](Resolve-Path -LiteralPath $Path).Path
    return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($pathUri).ToString()).Replace('/', '\')
}

$resolvedHardwareRoot = (Resolve-Path -LiteralPath $HardwareRoot).Path
$sourceFiles = @(
    Get-ChildItem -LiteralPath $resolvedHardwareRoot -Recurse -File -Filter '*.kicad_mod' |
        Sort-Object FullName
)

if ($sourceFiles.Count -eq 0) {
    throw "No .kicad_mod files were found under '$resolvedHardwareRoot'."
}

$records = @(
    foreach ($file in $sourceFiles) {
        [pscustomobject]@{
            FileName   = $file.Name
            Sha256     = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
            SourcePath = Get-RelativePath -BasePath $resolvedHardwareRoot -Path $file.FullName
            FullName   = $file.FullName
        }
    }
)

$conflicts = @(
    $records |
        Group-Object FileName |
        Where-Object { @($_.Group | Group-Object Sha256).Count -gt 1 }
)

if ($conflicts.Count -gt 0) {
    $details = foreach ($conflict in $conflicts) {
        $variants = $conflict.Group | ForEach-Object { "  $($_.Sha256)  $($_.SourcePath)" }
        "$($conflict.Name):`n$($variants -join "`n")"
    }
    throw "Same-name footprints with different contents were found. Resolve or rename them before combining:`n$($details -join "`n")"
}

if (Test-Path -LiteralPath $OutputDirectory) {
    Get-ChildItem -LiteralPath $OutputDirectory -File -Filter '*.kicad_mod' |
        Remove-Item -Force
}
else {
    $null = New-Item -ItemType Directory -Path $OutputDirectory
}

$canonicalRecords = @(
    $records |
        Group-Object FileName |
        Sort-Object Name |
        ForEach-Object { $_.Group | Sort-Object SourcePath | Select-Object -First 1 }
)

foreach ($record in $canonicalRecords) {
    Copy-Item -LiteralPath $record.FullName -Destination (Join-Path $OutputDirectory $record.FileName)
}

Write-Host "Combined $($sourceFiles.Count) source files into $($canonicalRecords.Count) unique footprints."
Write-Host "Library: $OutputDirectory"
