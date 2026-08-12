[CmdletBinding()]
param(
    [string] $KiCadConfigRoot = (Join-Path $env:APPDATA 'kicad'),
    [string[]] $Version,
    [switch] $AllVersions
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-JsonFile {
    param(
        [Parameter(Mandatory)] [object] $Value,
        [Parameter(Mandatory)] [string] $Path
    )

    $json = $Value | ConvertTo-Json -Depth 100
    $temporaryPath = "$Path.tmp"
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($temporaryPath, $json + [Environment]::NewLine, $utf8WithoutBom)
    Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
}

function Set-JsonProperty {
    param(
        [Parameter(Mandatory)] [object] $Object,
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] $Value
    )

    $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
}

$runningKiCad = Get-Process -Name 'kicad', 'eeschema', 'pl_editor' -ErrorAction SilentlyContinue
if ($runningKiCad) {
    $processNames = ($runningKiCad.ProcessName | Sort-Object -Unique) -join ', '
    throw "Close KiCad before installing these settings. Running process(es): $processNames"
}

if (-not (Test-Path -LiteralPath $KiCadConfigRoot -PathType Container)) {
    throw "KiCad configuration directory not found: $KiCadConfigRoot"
}

$availableVersions = @(
    Get-ChildItem -LiteralPath $KiCadConfigRoot -Directory |
        Where-Object { $_.Name -match '^\d+\.\d+$' } |
        Sort-Object { [version] $_.Name }
)

if ($Version) {
    $selectedVersions = @($availableVersions | Where-Object { $_.Name -in $Version })
    $missingVersions = @($Version | Where-Object { $_ -notin $availableVersions.Name })
    if ($missingVersions) {
        throw "KiCad configuration version(s) not found: $($missingVersions -join ', ')"
    }
}
elseif ($AllVersions) {
    $selectedVersions = $availableVersions
}
else {
    $selectedVersions = @($availableVersions | Select-Object -Last 1)
}

if (-not $selectedVersions) {
    throw "No KiCad version profiles were found below $KiCadConfigRoot. Start KiCad once, then rerun this script."
}

$black = 'rgb(0, 0, 0)'
$blackTextKeys = @(
    'aux_items',
    'fields',
    'hidden',
    'label_global',
    'label_hier',
    'label_local',
    'netclass_flag',
    'note',
    'op_currents',
    'op_voltages',
    'pin_name',
    'pin_number',
    'private_note',
    'reference',
    'sheet_fields',
    'sheet_filename',
    'sheet_label',
    'sheet_name',
    'value',
    'worksheet'
)
$timeStamp = Get-Date -Format 'yyyyMMdd-HHmmss'

foreach ($versionDirectory in $selectedVersions) {
    $eeschemaPath = Join-Path $versionDirectory.FullName 'eeschema.json'
    $colorsDirectory = Join-Path $versionDirectory.FullName 'colors'
    $sourceThemePath = Join-Path $colorsDirectory 'user.json'
    $targetThemePath = Join-Path $colorsDirectory 'segoe-ui-black.json'

    if (-not (Test-Path -LiteralPath $eeschemaPath -PathType Leaf)) {
        throw "Schematic Editor settings not found: $eeschemaPath"
    }
    if (-not (Test-Path -LiteralPath $sourceThemePath -PathType Leaf)) {
        throw "Base KiCad color theme not found: $sourceThemePath"
    }

    Copy-Item -LiteralPath $eeschemaPath -Destination "$eeschemaPath.$timeStamp.bak"
    if (Test-Path -LiteralPath $targetThemePath -PathType Leaf) {
        Copy-Item -LiteralPath $targetThemePath -Destination "$targetThemePath.$timeStamp.bak"
    }

    $eeschema = Get-Content -LiteralPath $eeschemaPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Set-JsonProperty -Object $eeschema.appearance -Name 'default_font' -Value 'Segoe UI'
    Set-JsonProperty -Object $eeschema.appearance -Name 'color_theme' -Value 'segoe-ui-black'
    if ($eeschema.PSObject.Properties.Name -contains 'printing') {
        Set-JsonProperty -Object $eeschema.printing -Name 'monochrome' -Value $true
    }

    $theme = Get-Content -LiteralPath $sourceThemePath -Raw -Encoding UTF8 | ConvertFrom-Json
    Set-JsonProperty -Object $theme.meta -Name 'name' -Value 'Segoe UI / black schematic text'
    foreach ($key in $blackTextKeys) {
        Set-JsonProperty -Object $theme.schematic -Name $key -Value $black
    }
    Set-JsonProperty -Object $theme.schematic -Name 'override_item_colors' -Value $true

    Write-JsonFile -Value $theme -Path $targetThemePath
    Write-JsonFile -Value $eeschema -Path $eeschemaPath

    Write-Host "Configured KiCad $($versionDirectory.Name): Segoe UI and black schematic text."
    Write-Host "Backup: $eeschemaPath.$timeStamp.bak"
}

Write-Host 'Done. Start KiCad and open the Schematic Editor.'
